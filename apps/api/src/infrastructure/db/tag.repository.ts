import { db } from './client.js'

export type Tag = {
  id: string
  userId: string
  name: string
  color: string | null
  createdAt?: string
}

export const tagRepository = {
  async listForUser(userId: string): Promise<Tag[]> {
    return db<Tag[]>`
      SELECT id, user_id, name, color
      FROM tags
      WHERE user_id = ${userId}
      ORDER BY name ASC
    `
  },

  async create(userId: string, name: string, color?: string | null): Promise<Tag> {
    const [row] = await db<Tag[]>`
      INSERT INTO tags (user_id, name, color)
      VALUES (${userId}, ${name}, ${color ?? null})
      RETURNING id, user_id, name, color
    `
    return row
  },

  async update(id: string, userId: string, patch: { name?: string; color?: string | null }): Promise<Tag | null> {
    const rows = await db<Tag[]>`
      UPDATE tags SET
        name  = COALESCE(${patch.name  ?? null}, name),
        color = ${patch.color !== undefined ? patch.color : db`color`}
      WHERE id = ${id} AND user_id = ${userId}
      RETURNING id, user_id, name, color
    `
    return rows[0] ?? null
  },

  async delete(id: string, userId: string): Promise<boolean> {
    const result = await db`DELETE FROM tags WHERE id = ${id} AND user_id = ${userId}`
    return result.count > 0
  },

  // ── Junction: all task-tag assignments for a user ────────────────────────

  async getAllTaskTagsForUser(userId: string): Promise<{ taskId: string; tags: Tag[] }[]> {
    const rows = await db<{ taskId: string; id: string; name: string; color: string | null }[]>`
      SELECT tt.task_id, t.id, t.name, t.color
      FROM task_tags tt
      JOIN tags t ON t.id = tt.tag_id
      JOIN tasks tk ON tk.id = tt.task_id
      WHERE tk.user_id = ${userId}
      ORDER BY tt.task_id, t.name
    `
    const map = new Map<string, Tag[]>()
    for (const r of rows) {
      const list = map.get(r.taskId) ?? []
      list.push({ id: r.id, userId, name: r.name, color: r.color })
      map.set(r.taskId, list)
    }
    return Array.from(map.entries()).map(([taskId, tags]) => ({ taskId, tags }))
  },

  async getAllNoteTagsForUser(userId: string): Promise<{ noteId: string; tags: Tag[] }[]> {
    const rows = await db<{ noteId: string; id: string; name: string; color: string | null }[]>`
      SELECT nt.note_id, t.id, t.name, t.color
      FROM note_tags nt
      JOIN tags t ON t.id = nt.tag_id
      JOIN notes n ON n.id = nt.note_id
      WHERE n.user_id = ${userId}
      ORDER BY nt.note_id, t.name
    `
    const map = new Map<string, Tag[]>()
    for (const r of rows) {
      const list = map.get(r.noteId) ?? []
      list.push({ id: r.id, userId, name: r.name, color: r.color })
      map.set(r.noteId, list)
    }
    return Array.from(map.entries()).map(([noteId, tags]) => ({ noteId, tags }))
  },

  // ── Junction: tasks ───────────────────────────────────────────────────────

  async getTaskTags(taskId: string): Promise<Tag[]> {
    return db<Tag[]>`
      SELECT t.id, t.user_id, t.name, t.color
      FROM tags t
      JOIN task_tags tt ON tt.tag_id = t.id
      WHERE tt.task_id = ${taskId}
      ORDER BY t.name ASC
    `
  },

  async setTaskTags(taskId: string, tagIds: string[]): Promise<void> {
    await db`DELETE FROM task_tags WHERE task_id = ${taskId}`
    if (tagIds.length === 0) return
    await db`
      INSERT INTO task_tags (task_id, tag_id)
      SELECT ${taskId}, unnest(${tagIds}::uuid[])
      ON CONFLICT DO NOTHING
    `
  },

  // ── Junction: notes ───────────────────────────────────────────────────────

  async getNoteTags(noteId: string): Promise<Tag[]> {
    return db<Tag[]>`
      SELECT t.id, t.user_id, t.name, t.color
      FROM tags t
      JOIN note_tags nt ON nt.tag_id = t.id
      WHERE nt.note_id = ${noteId}
      ORDER BY t.name ASC
    `
  },

  async setNoteTags(noteId: string, tagIds: string[]): Promise<void> {
    await db`DELETE FROM note_tags WHERE note_id = ${noteId}`
    if (tagIds.length === 0) return
    await db`
      INSERT INTO note_tags (note_id, tag_id)
      SELECT ${noteId}, unnest(${tagIds}::uuid[])
      ON CONFLICT DO NOTHING
    `
  },
}
