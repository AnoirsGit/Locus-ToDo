import { tagsApi, type TagEntityKind } from '$shared/api/tags.api'
import { toastStore } from '$shared/lib/toast.svelte'
import type { Tag } from './tag.types'

type Kind = TagEntityKind

type State = {
  tags: Tag[]
  loaded: boolean
  assignments: Record<Kind, Record<string, string[]>>   // kind → entityId → tagIds
  assignmentsLoaded: Record<Kind, boolean>
  filters: Record<Kind, Set<string>>
}

const state = $state<State>({
  tags: [],
  loaded: false,
  assignments: { tasks: {}, notes: {} },
  assignmentsLoaded: { tasks: false, notes: false },
  filters: { tasks: new Set(), notes: new Set() },
})

// ─── Generic core (shared by task + note tag handling) ───────────────────────

const loadAssignments = async (kind: Kind) => {
  if (state.assignmentsLoaded[kind]) return
  try {
    const rows = await tagsApi.getAllAssignments(kind)
    const map: Record<string, string[]> = {}
    for (const { id, tags } of rows) {
      map[id] = tags.map(t => t.id)
      for (const t of tags) {
        if (!state.tags.find(x => x.id === t.id)) {
          state.tags = [...state.tags, { id: t.id, name: t.name, color: t.color }]
        }
      }
    }
    state.assignments = { ...state.assignments, [kind]: map }
    state.assignmentsLoaded = { ...state.assignmentsLoaded, [kind]: true }
  } catch {
    // non-critical — tags just won't show
  }
}

const getTagsFor = (kind: Kind, id: string): Tag[] => {
  const ids = state.assignments[kind][id] ?? []
  return state.tags.filter(t => ids.includes(t.id))
}

const tagIdsFor = (kind: Kind, id: string): string[] => state.assignments[kind][id] ?? []

const setLocal = (kind: Kind, id: string, tagIds: string[]) => {
  state.assignments = {
    ...state.assignments,
    [kind]: { ...state.assignments[kind], [id]: tagIds },
  }
}

const toggleFilter = (kind: Kind, id: string) => {
  const next = new Set(state.filters[kind])
  if (next.has(id)) next.delete(id)
  else next.add(id)
  state.filters = { ...state.filters, [kind]: next }
}

const clearFilterFor = (kind: Kind) => {
  state.filters = { ...state.filters, [kind]: new Set() }
}

/** Does an entity satisfy the active filter for its kind (AND semantics)? */
const matchesFilter = (kind: Kind, id: string): boolean => {
  const active = state.filters[kind]
  if (active.size === 0) return true
  const tags = state.assignments[kind][id] ?? []
  return [...active].every(fid => tags.includes(fid))
}

// ─── Store ───────────────────────────────────────────────────────────────────

export const tagStore = {
  get tags() { return state.tags },
  get loaded() { return state.loaded },

  // ── Tasks ───────────────────────────────────────────────────────────────────

  get filterTagIds() { return state.filters.tasks },
  get isFiltering() { return state.filters.tasks.size > 0 },

  toggleFilterTag(id: string) { toggleFilter('tasks', id) },
  clearFilter() { clearFilterFor('tasks') },

  filterTasks<T extends { id: string }>(tasks: T[]): T[] {
    if (state.filters.tasks.size === 0) return tasks
    return tasks.filter(t => matchesFilter('tasks', t.id))
  },

  loadTaskAssignments() { return loadAssignments('tasks') },
  getTagsForTask(taskId: string): Tag[] { return getTagsFor('tasks', taskId) },
  setTaskTagsLocal(taskId: string, tagIds: string[]) { setLocal('tasks', taskId, tagIds) },

  // ── Notes ─────────────────────────────────────────────────────────────────

  get noteFilterTagIds() { return state.filters.notes },
  get isFilteringNotes() { return state.filters.notes.size > 0 },

  toggleNoteFilterTag(id: string) { toggleFilter('notes', id) },
  clearNoteFilter() { clearFilterFor('notes') },

  loadNoteAssignments() { return loadAssignments('notes') },
  getTagsForNote(noteId: string): Tag[] { return getTagsFor('notes', noteId) },
  tagIdsForNote(noteId: string): string[] { return tagIdsFor('notes', noteId) },

  /** Persist a note's tag set (optimistic local update + PUT). */
  setNoteTags(noteId: string, tagIds: string[]) {
    setLocal('notes', noteId, tagIds)
    tagsApi.setNoteTags(noteId, tagIds).catch(() => {
      toastStore.error('Failed to save note tags')
    })
  },

  noteMatchesFilter(noteId: string): boolean { return matchesFilter('notes', noteId) },

  // ── Catalog CRUD ────────────────────────────────────────────────────────────

  async load() {
    if (state.loaded) return
    try {
      const dtos = await tagsApi.list()
      state.tags = dtos.map(d => ({ id: d.id, name: d.name, color: d.color }))
      state.loaded = true
    } catch {
      toastStore.error('Failed to load tags')
    }
  },

  async create(name: string, color?: string | null): Promise<Tag> {
    const dto = await tagsApi.create(name, color)
    const tag: Tag = { id: dto.id, name: dto.name, color: dto.color }
    state.tags = [...state.tags, tag].sort((a, b) => a.name.localeCompare(b.name))
    return tag
  },

  async update(id: string, patch: { name?: string; color?: string | null }): Promise<void> {
    try {
      const dto = await tagsApi.update(id, patch)
      state.tags = state.tags.map(t => t.id === id ? { id: dto.id, name: dto.name, color: dto.color } : t)
    } catch {
      toastStore.error('Failed to update tag')
    }
  },

  async delete(id: string) {
    state.tags = state.tags.filter(t => t.id !== id)
    // Drop the tag from every kind's assignment cache + active filter.
    const strip = (m: Record<string, string[]>) => {
      const out: Record<string, string[]> = {}
      for (const [entityId, ids] of Object.entries(m)) {
        const filtered = ids.filter(i => i !== id)
        if (filtered.length) out[entityId] = filtered
      }
      return out
    }
    state.assignments = { tasks: strip(state.assignments.tasks), notes: strip(state.assignments.notes) }
    const tasks = new Set(state.filters.tasks); tasks.delete(id)
    const notes = new Set(state.filters.notes); notes.delete(id)
    state.filters = { tasks, notes }
    tagsApi.delete(id).catch(() => {
      toastStore.error('Failed to delete tag')
    })
  },
}
