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

// Find parentId of a given node id in the tree
const findParentId = (nodes: NoteNode[], targetId: string, parentId: string | null = null): string | null => {
  for (const n of nodes) {
    if (n.id === targetId) return parentId
    const found = findParentId(n.children, targetId, n.id)
    if (found !== undefined) return found
  }
  return undefined as any
}

// ─── Debounce helper ───────────────────────────────────────────────────────

const debounceMap = new Map<string, ReturnType<typeof setTimeout>>()

const debounce = (key: string, fn: () => void, ms = 600) => {
  clearTimeout(debounceMap.get(key))
  debounceMap.set(key, setTimeout(() => { fn(); debounceMap.delete(key) }, ms))
}

// ─── Store ─────────────────────────────────────────────────────────────────

type State = { nodes: NoteNode[]; loaded: boolean }

const state = $state<State>({ nodes: [], loaded: false })

export const noteStore = {
  get nodes() { return state.nodes },
  get loaded() { return state.loaded },

  get flat(): FlatNode[] { return flattenTree(state.nodes) },

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
  },

  /** Insert a new sibling node directly after `afterId`. Returns the new node. */
  async addAfter(afterId: string): Promise<NoteNode> {
    const node = newNode()
    const flat = flattenTree(state.nodes)
    const entry = flat.find(f => f.node.id === afterId)
    const parentId = entry?.parentId ?? null

    // Find position in parent list
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

    notesApi.create({ id: node.id, parentId, nodeType: node.type, content: '', sortOrder }).catch(() => {
      toastStore.error('Failed to create note')
      state.nodes = removeNodeFromTree(state.nodes, node.id)
    })

    return node
  },

  /** Remove node. Returns the id of the node that should receive focus next. */
  async remove(id: string): Promise<string | null> {
    const flat = flattenTree(state.nodes)
    const idx = flat.findIndex(f => f.node.id === id)
    const focusId = idx > 0 ? flat[idx - 1].node.id : null
    state.nodes = removeNodeFromTree(state.nodes, id)

    notesApi.delete(id).catch(() => {
      toastStore.error('Failed to delete note')
    })

    return focusId
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
    if (!entry?.parentId) return  // already root

    const parentEntry = flat.find(f => f.node.id === entry.parentId)
    if (!parentEntry) return

    const grandParentId = parentEntry.parentId
    const node = entry.node

    // Remove from parent, insert after parent in grandparent list
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
    const sortOrder = state.nodes.length * 10
    state.nodes = [...state.nodes, node]

    notesApi.create({ id: node.id, parentId: null, nodeType: node.type, content: '', sortOrder }).catch(() => {
      toastStore.error('Failed to create note')
      state.nodes = removeNodeFromTree(state.nodes, node.id)
    })

    return node
  },
}
