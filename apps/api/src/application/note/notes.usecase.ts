import { noteRepository, type NoteNodeType, type NoteTree, type NoteRow } from '../../infrastructure/db/note.repository.js'

export const listNotes = (userId: string): Promise<NoteTree[]> =>
  noteRepository.listForUser(userId)

export const createNote = (userId: string, input: {
  id?: string
  parentId?: string | null
  nodeType?: NoteNodeType
  content?: string
  url?: string | null
  sortOrder?: number
}): Promise<NoteRow> =>
  noteRepository.create({
    id:        input.id,
    userId,
    parentId:  input.parentId  ?? null,
    nodeType:  input.nodeType  ?? 'bullet',
    content:   input.content   ?? '',
    url:       input.url       ?? null,
    sortOrder: input.sortOrder ?? 0,
  })

export const updateNote = async (
  id: string,
  userId: string,
  patch: Partial<{
    nodeType: NoteNodeType
    content: string
    url: string | null
    sortOrder: number
    collapsed: boolean
    done: boolean
    parentId: string | null
  }>,
): Promise<NoteRow> => {
  const row = await noteRepository.update(id, userId, patch)
  if (!row) throw Object.assign(new Error('Note not found'), { statusCode: 404 })
  return row
}

export const deleteNote = async (id: string, userId: string): Promise<void> => {
  const ok = await noteRepository.delete(id, userId)
  if (!ok) throw Object.assign(new Error('Note not found'), { statusCode: 404 })
}
