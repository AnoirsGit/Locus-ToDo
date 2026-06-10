import { api } from './client'
import type { NoteNodeType, NoteNode } from '$entities/note'

// ── API DTO (flat, from server) ────────────────────────────────────────────

export type NoteDto = {
  id: string
  userId: string
  parentId: string | null
  nodeType: NoteNodeType
  content: string
  url: string | null
  sortOrder: number
  collapsed: boolean
  createdAt: string
  updatedAt: string
  children: NoteDto[]
}

// ── Conversions ────────────────────────────────────────────────────────────

export const dtoToNode = (dto: NoteDto): NoteNode => ({
  id:        dto.id,
  type:      dto.nodeType,
  content:   dto.content,
  url:       dto.url ?? undefined,
  collapsed: dto.collapsed,
  children:  dto.children.map(dtoToNode),
})

// ── Client ─────────────────────────────────────────────────────────────────

export const notesApi = {
  list: () => api.get<NoteDto[]>('/notes'),

  create: (input: {
    id?:        string
    parentId?:  string | null
    nodeType?:  NoteNodeType
    content?:   string
    url?:       string | null
    sortOrder?: number
  }) => api.post<NoteDto>('/notes', input),

  update: (id: string, patch: Partial<{
    nodeType:  NoteNodeType
    content:   string
    url:       string | null
    sortOrder: number
    collapsed: boolean
    parentId:  string | null
  }>) => api.patch<NoteDto>(`/notes/${id}`, patch),

  delete: (id: string) => api.delete<void>(`/notes/${id}`),
}
