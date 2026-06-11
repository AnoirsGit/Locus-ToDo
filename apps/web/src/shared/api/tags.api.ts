import { api } from './client'

export type TagDto = {
  id: string
  userId: string
  name: string
  color: string | null
}

export const tagsApi = {
  list: () => api.get<TagDto[]>('/tags'),

  create: (name: string, color?: string | null) =>
    api.post<TagDto>('/tags', { name, color }),

  update: (id: string, patch: { name?: string; color?: string | null }) =>
    api.patch<TagDto>(`/tags/${id}`, patch),

  delete: (id: string) => api.delete<void>(`/tags/${id}`),

  getAllTaskAssignments: () =>
    api.get<{ taskId: string; tags: TagDto[] }[]>('/tags/task-assignments'),

  getTaskTags: (taskId: string) => api.get<TagDto[]>(`/tags/tasks/${taskId}`),

  setTaskTags: (taskId: string, tagIds: string[]) =>
    api.put<void>(`/tags/tasks/${taskId}`, { tagIds }),

  getAllNoteAssignments: () =>
    api.get<{ noteId: string; tags: TagDto[] }[]>('/tags/note-assignments'),

  getNoteTags: (noteId: string) => api.get<TagDto[]>(`/tags/notes/${noteId}`),

  setNoteTags: (noteId: string, tagIds: string[]) =>
    api.put<void>(`/tags/notes/${noteId}`, { tagIds }),
}
