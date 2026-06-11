import { notesApi, dtoToNode, type NoteDto } from '$shared/api/notes.api'
import { toastStore } from '$shared/lib/toast.svelte'
import type { NoteNode, NoteNodeType } from './note.types'

// ─── Flat representation used for keyboard navigation ──────────────────────
export type FlatNode = { node: NoteNode; depth: number; parentId: string | null }

const flattenTree = (nodes: NoteNode[], depth = 0, parentId: string | null = null): FlatNode[] => {
  const result: FlatNode[] = []
  for (const node of nodes) {
    result.push({ node, depth, parentId })
    if (!node.collapsed && node.children.length) {
      result.push(...flattenTree(node.children, depth + 1, node.id))
    }
  }
  return result
}

// ─── Immutable tree helpers ────────────────────────────────────────────────

const findNodeById = (nodes: NoteNode[], id: string): NoteNode | null => {
  for (const n of nodes) {
    if (n.id === id) return n
    const found = findNodeById(n.children, id)
    if (found) return found
  }
  return null
}

const updateNodeInTree = (nodes: NoteNode[], id: string, patch: Partial<NoteNode>): NoteNode[] =>
  nodes.map(n => n.id === id
    ? { ...n, ...patch }
    : { ...n, children: updateNodeInTree(n.children, id, patch) }
  )

const removeNodeFromTree = (nodes: NoteNode[], id: string): NoteNode[] =>
  nodes
    .filter(n => n.id !== id)
    .map(n => ({ ...n, children: removeNodeFromTree(n.children, id) }))

const newNode = (type: NoteNodeType = 'bullet'): NoteNode => ({
  id: crypto.randomUUID(),
  type,
  content: '',
  children: [],
})

// Returns the parent id, null for root-level nodes, undefined when not found.
const findParentId = (nodes: NoteNode[], targetId: string, parentId: string | null = null): string | null | undefined => {
  for (const n of nodes) {
    if (n.id === targetId) return parentId
    const found = findParentId(n.children, targetId, n.id)
    if (found !== undefined) return found
  }
  return undefined
}

// Build path from root to targetId (inclusive), returns [{id, content}]
const buildPath = (nodes: NoteNode[], targetId: string, path: Array<{ id: string; content: string }> = []): Array<{ id: string; content: string }> | null => {
  for (const n of nodes) {
    const next = [...path, { id: n.id, content: n.content }]
    if (n.id === targetId) return next
    if (n.children.length) {
      const found = buildPath(n.children, targetId, next)
      if (found) return found
    }
  }
  return null
}

// ─── Debounce helper ───────────────────────────────────────────────────────

const debounceMap = new Map<string, ReturnType<typeof setTimeout>>()

const debounce = (key: string, fn: () => void, ms = 600) => {
  clearTimeout(debounceMap.get(key))
  debounceMap.set(key, setTimeout(() => { fn(); debounceMap.delete(key) }, ms))
}

const collectSubtreeIds = (node: NoteNode): string[] =>
  [node.id, ...node.children.flatMap(collectSubtreeIds)]

// Create payload for persisting a cloned node (parent-first order).
type CreatePayload = {
  id: string
  parentId: string | null
  nodeType: NoteNodeType
  content: string
  url: string | null
  sortOrder: number
}

// Deep-clone a subtree with fresh UUIDs. Returns the new tree plus a flat,
// parent-first list of create payloads so children always POST after their parent.
const cloneSubtree = (node: NoteNode, parentId: string | null, sortOrder: number): { clone: NoteNode; creates: CreatePayload[] } => {
  const id = crypto.randomUUID()
  const creates: CreatePayload[] = [
    { id, parentId, nodeType: node.type, content: node.content, url: node.url ?? null, sortOrder },
  ]
  const children = node.children.map((child, i) => {
    const sub = cloneSubtree(child, id, i * 10)
    creates.push(...sub.creates)
    return sub.clone
  })
  return {
    clone: { id, type: node.type, content: node.content, url: node.url, collapsed: node.collapsed, children },
    creates,
  }
}

// Cancel pending content saves for the node and all its descendants,
// otherwise a debounced PATCH can fire after the DELETE and 404.
const cancelContentDebounce = (nodes: NoteNode[], id: string) => {
  const target = findNodeById(nodes, id)
  const ids = target ? collectSubtreeIds(target) : [id]
  for (const nodeId of ids) {
    const key = `content:${nodeId}`
    clearTimeout(debounceMap.get(key))
    debounceMap.delete(key)
  }
}

// In-flight optimistic creates: a DELETE issued before the POST resolves
// would 404 and the INSERT would land after, leaving a ghost note.
const pendingCreates = new Map<string, Promise<unknown>>()

const trackCreate = (id: string, promise: Promise<unknown>) => {
  pendingCreates.set(id, promise)
  promise.finally(() => pendingCreates.delete(id))
}

// Swap a node with its adjacent sibling and persist both sort orders.
const moveSibling = (id: string, delta: -1 | 1) => {
  const parentId = findParentId(state.nodes, id)
  if (parentId === undefined) return
  const siblings = parentId
    ? findNodeById(state.nodes, parentId)?.children ?? []
    : state.nodes
  const idx = siblings.findIndex(n => n.id === id)
  const target = idx + delta
  if (idx < 0 || target < 0 || target >= siblings.length) return

  const reordered = [...siblings]
  ;[reordered[idx], reordered[target]] = [reordered[target], reordered[idx]]
  if (parentId) {
    state.nodes = updateNodeInTree(state.nodes, parentId, { children: reordered })
  } else {
    state.nodes = reordered
  }

  for (const i of [idx, target]) {
    notesApi.update(reordered[i].id, { sortOrder: i * 10 }).catch(() => {
      toastStore.error('Failed to move note')
    })
  }
}

// ─── Store ─────────────────────────────────────────────────────────────────

type State = {
  nodes: NoteNode[]
  loaded: boolean
  rootId: string | null
  selectedIds: Set<string>
}

const state = $state<State>({
  nodes: [],
  loaded: false,
  rootId: null,
  selectedIds: new Set(),
})

export const noteStore = {
  get nodes() { return state.nodes },
  get loaded() { return state.loaded },

  // Root visible nodes (scoped to current page)
  get rootNodes(): NoteNode[] {
    if (!state.rootId) return state.nodes
    return findNodeById(state.nodes, state.rootId)?.children ?? state.nodes
  },

  // Flat list of visible nodes (scoped to current page root)
  get flat(): FlatNode[] {
    return flattenTree(this.rootNodes)
  },

  // Breadcrumb path from global root to current rootId (inclusive)
  get breadcrumbs(): Array<{ id: string; content: string }> {
    if (!state.rootId) return []
    return buildPath(state.nodes, state.rootId) ?? []
  },

  get rootId() { return state.rootId },
  get selectedIds() { return state.selectedIds },

  // ── Page navigation ───────────────────────────────────────────────────────

  setRoot(id: string | null) {
    state.rootId = id
    state.selectedIds = new Set()
  },

  // ── Selection ─────────────────────────────────────────────────────────────

  setSelection(ids: Set<string>) {
    state.selectedIds = new Set(ids)
  },

  clearSelection() {
    state.selectedIds = new Set()
  },

  async deleteSelected() {
    const ids = [...state.selectedIds]
    if (!ids.length) return
    state.selectedIds = new Set()
    let nodes = state.nodes
    for (const id of ids) {
      cancelContentDebounce(nodes, id)
      nodes = removeNodeFromTree(nodes, id)
    }
    state.nodes = nodes
    await Promise.all(ids.map(async id => {
      await pendingCreates.get(id)
      await notesApi.delete(id).catch(() => {})
    }))
  },

  // ── Init ─────────────────────────────────────────────────────────────────

  async load() {
    if (state.loaded) return
    try {
      const dtos = await notesApi.list()
      state.nodes = dtos.map(dtoToNode)
      state.loaded = true
    } catch {
      toastStore.error('Failed to load notes')
    }
  },

  // ── CRUD ──────────────────────────────────────────────────────────────────

  update(id: string, patch: Partial<NoteNode>) {
    state.nodes = updateNodeInTree(state.nodes, id, patch)
    if (patch.content !== undefined) {
      debounce(`content:${id}`, () => {
        notesApi.update(id, { content: patch.content! }).catch(() => {
          toastStore.error('Failed to save note')
        })
      })
    }
    if (patch.type !== undefined) {
      notesApi.update(id, { nodeType: patch.type }).catch(() => {
        toastStore.error('Failed to save note')
      })
    }
    if (patch.url !== undefined) {
      notesApi.update(id, { url: patch.url || null }).catch(() => {
        toastStore.error('Failed to save note')
      })
    }
  },

  /** Insert a new sibling node directly after `afterId`. Returns the new node. */
  async addAfter(afterId: string): Promise<NoteNode> {
    const node = newNode()
    const flat = flattenTree(state.nodes)
    const entry = flat.find(f => f.node.id === afterId)
    const parentId = entry?.parentId ?? null

    const parentList = parentId
      ? (flat.find(f => f.node.id === parentId)?.node.children ?? state.nodes)
      : state.nodes
    const idx = parentList.findIndex(n => n.id === afterId)
    const sortOrder = (idx + 1) * 10

    const insert = (nodes: NoteNode[]): NoteNode[] => {
      const i = nodes.findIndex(n => n.id === afterId)
      if (i !== -1) return [...nodes.slice(0, i + 1), node, ...nodes.slice(i + 1)]
      return nodes.map(n => ({ ...n, children: insert(n.children) }))
    }
    state.nodes = insert(state.nodes)

    trackCreate(node.id, notesApi.create({ id: node.id, parentId, nodeType: node.type, content: '', sortOrder }).catch(() => {
      toastStore.error('Failed to create note')
      state.nodes = removeNodeFromTree(state.nodes, node.id)
    }))

    return node
  },

  /** Remove node. Returns the id of the node that should receive focus next. */
  async remove(id: string): Promise<string | null> {
    const flat = flattenTree(state.nodes)
    const idx = flat.findIndex(f => f.node.id === id)
    const focusId = idx > 0 ? flat[idx - 1].node.id : null
    cancelContentDebounce(state.nodes, id)
    state.nodes = removeNodeFromTree(state.nodes, id)

    const pending = pendingCreates.get(id)
    const doDelete = () => notesApi.delete(id).catch(() => {
      toastStore.error('Failed to delete note')
    })
    if (pending) {
      pending.then(doDelete)
    } else {
      doDelete()
    }

    return focusId
  },

  // ── Row metadata (menu state) ────────────────────────────────────────────

  /** Case-insensitive content search over the whole tree, with breadcrumb paths. */
  search(query: string): Array<{ id: string; content: string; type: NoteNodeType; path: string }> {
    const q = query.trim().toLowerCase()
    if (!q) return []
    const results: Array<{ id: string; content: string; type: NoteNodeType; path: string }> = []
    const walk = (nodes: NoteNode[], ancestors: string[]) => {
      for (const n of nodes) {
        if (n.content.toLowerCase().includes(q)) {
          results.push({ id: n.id, content: n.content, type: n.type, path: ancestors.join(' › ') })
        }
        if (n.children.length) walk(n.children, [...ancestors, n.content || 'Untitled'])
      }
    }
    walk(state.nodes, [])
    return results
  },

  /** Number of descendants, for the delete confirmation text. */
  descendantCount(id: string): number {
    const node = findNodeById(state.nodes, id)
    return node ? collectSubtreeIds(node).length - 1 : 0
  },

  /** Position of the node among its siblings (for disabling menu items). */
  siblingInfo(id: string): { index: number; count: number; isRoot: boolean } | null {
    const parentId = findParentId(state.nodes, id)
    if (parentId === undefined) return null
    const siblings = parentId
      ? findNodeById(state.nodes, parentId)?.children ?? []
      : state.nodes
    return {
      index: siblings.findIndex(n => n.id === id),
      count: siblings.length,
      isRoot: parentId === null,
    }
  },

  /** Add an empty child at the end of `parentId`, expanding it. Returns the new node. */
  async addChild(parentId: string): Promise<NoteNode> {
    const node = newNode()
    const parent = findNodeById(state.nodes, parentId)
    const sortOrder = (parent?.children.length ?? 0) * 10
    state.nodes = updateNodeInTree(state.nodes, parentId, {
      collapsed: false,
      children: [...(parent?.children ?? []), node],
    })
    trackCreate(node.id, notesApi.create({ id: node.id, parentId, nodeType: node.type, content: '', sortOrder }).catch(() => {
      toastStore.error('Failed to create note')
      state.nodes = removeNodeFromTree(state.nodes, node.id)
    }))
    return node
  },

  // ── Reorder among siblings ───────────────────────────────────────────────

  moveUp(id: string) { moveSibling(id, -1) },
  moveDown(id: string) { moveSibling(id, 1) },

  /** Deep-copy a subtree with fresh UUIDs, inserting it right after the source. */
  async duplicate(id: string): Promise<NoteNode | null> {
    const source = findNodeById(state.nodes, id)
    const parentId = findParentId(state.nodes, id)
    if (!source || parentId === undefined) return null

    const siblings = parentId
      ? findNodeById(state.nodes, parentId)?.children ?? state.nodes
      : state.nodes
    const idx = siblings.findIndex(n => n.id === id)
    const { clone, creates } = cloneSubtree(source, parentId, (idx + 1) * 10)

    const insert = (nodes: NoteNode[]): NoteNode[] => {
      const i = nodes.findIndex(n => n.id === id)
      if (i !== -1) return [...nodes.slice(0, i + 1), clone, ...nodes.slice(i + 1)]
      return nodes.map(n => ({ ...n, children: insert(n.children) }))
    }
    state.nodes = insert(state.nodes)

    // Parent-first sequential creates so each child's FK parent already exists.
    trackCreate(clone.id, (async () => {
      for (const payload of creates) await notesApi.create(payload)
    })().catch(() => {
      toastStore.error('Failed to duplicate note')
      state.nodes = removeNodeFromTree(state.nodes, clone.id)
    }))

    return clone
  },

  // ── Indent / Unindent ────────────────────────────────────────────────────

  indent(id: string) {
    const parentList = (() => {
      const flat = flattenTree(state.nodes)
      const entry = flat.find(f => f.node.id === id)
      if (!entry?.parentId) return state.nodes
      return flat.find(f => f.node.id === entry.parentId)?.node.children ?? state.nodes
    })()
    const idx = parentList.findIndex(n => n.id === id)
    if (idx < 1) return

    const node = parentList[idx]
    const prevSibling = parentList[idx - 1]
    const newSortOrder = prevSibling.children.length * 10

    const removed = removeNodeFromTree(state.nodes, id)
    state.nodes = updateNodeInTree(removed, prevSibling.id, {
      collapsed: false,
      children: [...prevSibling.children, node],
    })

    notesApi.update(id, { parentId: prevSibling.id, sortOrder: newSortOrder }).catch(() => {
      toastStore.error('Failed to move note')
    })
  },

  unindent(id: string) {
    const flat = flattenTree(state.nodes)
    const entry = flat.find(f => f.node.id === id)
    if (!entry?.parentId) return

    const parentEntry = flat.find(f => f.node.id === entry.parentId)
    if (!parentEntry) return

    const grandParentId = parentEntry.parentId
    const node = entry.node

    let result = updateNodeInTree(state.nodes, parentEntry.node.id, {
      children: parentEntry.node.children.filter(c => c.id !== id),
    })
    const insertAfterParent = (nodes: NoteNode[]): NoteNode[] => {
      const i = nodes.findIndex(n => n.id === parentEntry.node.id)
      if (i !== -1) return [...nodes.slice(0, i + 1), node, ...nodes.slice(i + 1)]
      return nodes.map(n => ({ ...n, children: insertAfterParent(n.children) }))
    }
    state.nodes = insertAfterParent(result)

    const grandParentList = grandParentId
      ? flat.find(f => f.node.id === grandParentId)?.node.children ?? state.nodes
      : state.nodes
    const parentIdx = grandParentList.findIndex(n => n.id === parentEntry.node.id)
    const newSortOrder = (parentIdx + 1) * 10

    notesApi.update(id, { parentId: grandParentId, sortOrder: newSortOrder }).catch(() => {
      toastStore.error('Failed to move note')
    })
  },

  // ── Collapse / Expand ────────────────────────────────────────────────────

  toggleCollapse(id: string) {
    const flat = flattenTree(state.nodes)
    const entry = flat.find(f => f.node.id === id)
    if (!entry) return
    const collapsed = !entry.node.collapsed
    state.nodes = updateNodeInTree(state.nodes, id, { collapsed })
    notesApi.update(id, { collapsed }).catch(() => {
      toastStore.error('Failed to save note')
    })
  },

  /** Add a root-level node at the end */
  async addRoot(): Promise<NoteNode> {
    const node = newNode('text')

    if (state.rootId) {
      // We're inside a page — add as child of rootId
      const rootNode = findNodeById(state.nodes, state.rootId)
      const sortOrder = (rootNode?.children.length ?? 0) * 10
      state.nodes = updateNodeInTree(state.nodes, state.rootId, {
        children: [...(rootNode?.children ?? []), node],
      })
      trackCreate(node.id, notesApi.create({ id: node.id, parentId: state.rootId, nodeType: node.type, content: '', sortOrder }).catch(() => {
        toastStore.error('Failed to create note')
        state.nodes = removeNodeFromTree(state.nodes, node.id)
      }))
    } else {
      const sortOrder = state.nodes.length * 10
      state.nodes = [...state.nodes, node]
      trackCreate(node.id, notesApi.create({ id: node.id, parentId: null, nodeType: node.type, content: '', sortOrder }).catch(() => {
        toastStore.error('Failed to create note')
        state.nodes = removeNodeFromTree(state.nodes, node.id)
      }))
    }

    return node
  },
}
