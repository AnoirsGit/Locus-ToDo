import { api } from './client'

export type TagDto = {
  id: string
  userId: string
  name: string
  color: string | null
}

/** Entities that can carry tags. Maps directly to the URL path segment. */
export type TagEntityKind = 'tasks' | 'notes'

// Bulk-assignment endpoints use a singular path segment.
const assignmentsPath = (kind: TagEntityKind) =>
  kind === 'tasks' ? '/tags/task-assignments' : '/tags/note-assignments'

type RawAssignment = { taskId?: string; noteId?: string; tags: TagDto[] }

export const tagsApi = {
  list: () => api.get<TagDto[]>('/tags'),

  create: (name: string, color?: string | null) =>
    api.post<TagDto>('/tags', { name, color }),

  update: (id: string, patch: { name?: string; color?: string | null }) =>
    api.patch<TagDto>(`/tags/${id}`, patch),

  delete: (id: string) => api.delete<void>(`/tags/${id}`),

  // ── Assignments (generic over entity kind) ──────────────────────────────────

  /** All entity→tags pairs for the user, normalized to `{ id, tags }`. */
  getAllAssignments: (kind: TagEntityKind) =>
    api.get<RawAssignment[]>(assignmentsPath(kind)).then(rows =>
      rows.map(r => ({ id: (r.taskId ?? r.noteId)!, tags: r.tags })),
    ),

  getEntityTags: (kind: TagEntityKind, id: string) =>
    api.get<TagDto[]>(`/tags/${kind}/${id}`),

  setEntityTags: (kind: TagEntityKind, id: string, tagIds: string[]) =>
    api.put<void>(`/tags/${kind}/${id}`, { tagIds }),

  // ── Named wrappers (kept for existing external callers) ─────────────────────

  getTaskTags: (taskId: string) => tagsApi.getEntityTags('tasks', taskId),
  setTaskTags: (taskId: string, tagIds: string[]) => tagsApi.setEntityTags('tasks', taskId, tagIds),
  getNoteTags: (noteId: string) => tagsApi.getEntityTags('notes', noteId),
  setNoteTags: (noteId: string, tagIds: string[]) => tagsApi.setEntityTags('notes', noteId, tagIds),
}
