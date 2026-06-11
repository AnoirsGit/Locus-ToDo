import { tagsApi } from '$shared/api/tags.api'
import { toastStore } from '$shared/lib/toast.svelte'
import type { Tag } from './tag.types'

type State = {
  tags: Tag[]
  loaded: boolean
  taskTagsMap: Record<string, string[]>  // taskId → tagIds
  taskTagsLoaded: boolean
  filterTagIds: Set<string>
  noteTagsMap: Record<string, string[]>   // noteId → tagIds
  noteTagsLoaded: boolean
  noteFilterTagIds: Set<string>
}

const state = $state<State>({
  tags: [], loaded: false,
  taskTagsMap: {}, taskTagsLoaded: false, filterTagIds: new Set(),
  noteTagsMap: {}, noteTagsLoaded: false, noteFilterTagIds: new Set(),
})

export const tagStore = {
  get tags() { return state.tags },
  get loaded() { return state.loaded },
  get filterTagIds() { return state.filterTagIds },
  get isFiltering() { return state.filterTagIds.size > 0 },

  toggleFilterTag(id: string) {
    const next = new Set(state.filterTagIds)
    if (next.has(id)) next.delete(id)
    else next.add(id)
    state.filterTagIds = next
  },

  clearFilter() {
    state.filterTagIds = new Set()
  },

  filterTasks<T extends { id: string }>(tasks: T[]): T[] {
    if (state.filterTagIds.size === 0) return tasks
    return tasks.filter(t => {
      const taskTags = state.taskTagsMap[t.id] ?? []
      return [...state.filterTagIds].every(fid => taskTags.includes(fid))
    })
  },

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

  async loadTaskAssignments() {
    if (state.taskTagsLoaded) return
    try {
      const assignments = await tagsApi.getAllTaskAssignments()
      const map: Record<string, string[]> = {}
      for (const { taskId, tags } of assignments) {
        map[taskId] = tags.map(t => t.id)
        // also ensure tags are in the tag list
        for (const t of tags) {
          if (!state.tags.find(x => x.id === t.id)) {
            state.tags = [...state.tags, { id: t.id, name: t.name, color: t.color }]
          }
        }
      }
      state.taskTagsMap = map
      state.taskTagsLoaded = true
    } catch {
      // non-critical — tags just won't show on cards
    }
  },

  getTagsForTask(taskId: string): Tag[] {
    const ids = state.taskTagsMap[taskId] ?? []
    return state.tags.filter(t => ids.includes(t.id))
  },

  setTaskTagsLocal(taskId: string, tagIds: string[]) {
    state.taskTagsMap = { ...state.taskTagsMap, [taskId]: tagIds }
  },

  // ── Notes ──────────────────────────────────────────────────────────────────

  get noteFilterTagIds() { return state.noteFilterTagIds },
  get isFilteringNotes() { return state.noteFilterTagIds.size > 0 },

  toggleNoteFilterTag(id: string) {
    const next = new Set(state.noteFilterTagIds)
    if (next.has(id)) next.delete(id)
    else next.add(id)
    state.noteFilterTagIds = next
  },

  clearNoteFilter() {
    state.noteFilterTagIds = new Set()
  },

  async loadNoteAssignments() {
    if (state.noteTagsLoaded) return
    try {
      const assignments = await tagsApi.getAllNoteAssignments()
      const map: Record<string, string[]> = {}
      for (const { noteId, tags } of assignments) {
        map[noteId] = tags.map(t => t.id)
        for (const t of tags) {
          if (!state.tags.find(x => x.id === t.id)) {
            state.tags = [...state.tags, { id: t.id, name: t.name, color: t.color }]
          }
        }
      }
      state.noteTagsMap = map
      state.noteTagsLoaded = true
    } catch {
      // non-critical — tags just won't show on rows
    }
  },

  getTagsForNote(noteId: string): Tag[] {
    const ids = state.noteTagsMap[noteId] ?? []
    return state.tags.filter(t => ids.includes(t.id))
  },

  tagIdsForNote(noteId: string): string[] {
    return state.noteTagsMap[noteId] ?? []
  },

  /** Persist a note's tag set (optimistic local update + PUT). */
  setNoteTags(noteId: string, tagIds: string[]) {
    state.noteTagsMap = { ...state.noteTagsMap, [noteId]: tagIds }
    tagsApi.setNoteTags(noteId, tagIds).catch(() => {
      toastStore.error('Failed to save note tags')
    })
  },

  /** Does a note (or any node in its subtree-ids) match the active note filter? */
  noteMatchesFilter(noteId: string): boolean {
    if (state.noteFilterTagIds.size === 0) return true
    const noteTags = state.noteTagsMap[noteId] ?? []
    return [...state.noteFilterTagIds].every(fid => noteTags.includes(fid))
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
    // remove from task assignments cache
    const newMap: Record<string, string[]> = {}
    for (const [taskId, ids] of Object.entries(state.taskTagsMap)) {
      const filtered = ids.filter(i => i !== id)
      if (filtered.length) newMap[taskId] = filtered
    }
    state.taskTagsMap = newMap
    const newNoteMap: Record<string, string[]> = {}
    for (const [noteId, ids] of Object.entries(state.noteTagsMap)) {
      const filtered = ids.filter(i => i !== id)
      if (filtered.length) newNoteMap[noteId] = filtered
    }
    state.noteTagsMap = newNoteMap
    const nextFilter = new Set(state.noteFilterTagIds); nextFilter.delete(id)
    state.noteFilterTagIds = nextFilter
    tagsApi.delete(id).catch(() => {
      toastStore.error('Failed to delete tag')
    })
  },
}
