import { tagRepository, type Tag } from '../../infrastructure/db/tag.repository.js'

export const listTags = (userId: string): Promise<Tag[]> =>
  tagRepository.listForUser(userId)

export const createTag = (userId: string, name: string, color?: string | null): Promise<Tag> =>
  tagRepository.create(userId, name.trim(), color)

export const updateTag = async (
  id: string,
  userId: string,
  patch: { name?: string; color?: string | null },
): Promise<Tag> => {
  const row = await tagRepository.update(id, userId, {
    name:  patch.name?.trim(),
    color: patch.color,
  })
  if (!row) throw Object.assign(new Error('Tag not found'), { statusCode: 404 })
  return row
}

export const deleteTag = async (id: string, userId: string): Promise<void> => {
  const ok = await tagRepository.delete(id, userId)
  if (!ok) throw Object.assign(new Error('Tag not found'), { statusCode: 404 })
}

export const getAllTaskTagsForUser = (userId: string) => tagRepository.getAllTaskTagsForUser(userId)
export const getAllNoteTagsForUser = (userId: string) => tagRepository.getAllNoteTagsForUser(userId)
export const getTaskTags  = (taskId: string)  => tagRepository.getTaskTags(taskId)
export const setTaskTags  = (taskId: string, tagIds: string[]) => tagRepository.setTaskTags(taskId, tagIds)
export const getNoteTags  = (noteId: string)  => tagRepository.getNoteTags(noteId)
export const setNoteTags  = (noteId: string, tagIds: string[]) => tagRepository.setNoteTags(noteId, tagIds)
