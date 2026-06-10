import { tagsApi } from '$shared/api/tags.api'
import { toastStore } from '$shared/lib/toast.svelte'
import type { Tag } from './tag.types'

type State = {
  tags: Tag[]
  loaded: boolean
  taskTagsMap: Record<string, string[]>  // taskId → tagIds
  taskTagsLoaded: boolean
  filterTagIds: Set<string>
}

const state = $state<State>({ tags: [], loaded: false, taskTagsMap: {}, taskTagsLoaded: false, filterTagIds: new Set() })

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
    tagsApi.delete(id).catch(() => {
      toastStore.error('Failed to delete tag')
    })
  },
}
