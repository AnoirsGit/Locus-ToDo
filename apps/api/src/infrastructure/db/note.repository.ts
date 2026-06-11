import { randomUUID } from 'node:crypto'
import { db } from './client.js'

export type NoteNodeType = 'text' | 'heading1' | 'heading2' | 'bullet' | 'image' | 'link' | 'todo'

export type NoteRow = {
  id: string
  userId: string
  parentId: string | null
  nodeType: NoteNodeType
  content: string
  url: string | null
  sortOrder: number
  collapsed: boolean
  done: boolean
  createdAt: string
  updatedAt: string
}

export type NoteTree = NoteRow & { children: NoteTree[] }

const RETURNING = `id, user_id, parent_id, node_type, content, url, sort_order, collapsed, done, created_at, updated_at`

const buildTree = (rows: NoteRow[], parentId: string | null): NoteTree[] =>
  rows
    .filter(r => r.parentId === parentId)
    .sort((a, b) => a.sortOrder - b.sortOrder)
    .map(r => ({ ...r, children: buildTree(rows, r.id) }))

export const noteRepository = {
  async listForUser(userId: string): Promise<NoteTree[]> {
    const rows = await db<NoteRow[]>`
      SELECT ${db.unsafe(RETURNING)}
      FROM notes
      WHERE user_id = ${userId}
      ORDER BY sort_order ASC, created_at ASC
    `
    return buildTree(rows, null)
  },

  async create(input: {
    id?: string
    userId: string
    parentId: string | null
    nodeType: NoteNodeType
    content: string
    url?: string | null
    sortOrder: number
  }): Promise<NoteRow> {
    const id = input.id ?? randomUUID()
    const [row] = await db<NoteRow[]>`
      INSERT INTO notes (id, user_id, parent_id, node_type, content, url, sort_order)
      VALUES (
        ${id},
        ${input.userId}, ${input.parentId ?? null}, ${input.nodeType},
        ${input.content}, ${input.url ?? null}, ${input.sortOrder}
      )
      RETURNING ${db.unsafe(RETURNING)}
    `
    return row
  },

  async update(id: string, userId: string, patch: Partial<{
    nodeType: NoteNodeType
    content: string
    url: string | null
    sortOrder: number
    collapsed: boolean
    done: boolean
    parentId: string | null
  }>): Promise<NoteRow | null> {
    const rows = await db<NoteRow[]>`
      UPDATE notes SET
        node_type  = COALESCE(${patch.nodeType  ?? null}, node_type),
        content    = COALESCE(${patch.content   ?? null}, content),
        url        = ${patch.url !== undefined      ? patch.url        : db`url`},
        sort_order = COALESCE(${patch.sortOrder ?? null}, sort_order),
        collapsed  = COALESCE(${patch.collapsed ?? null}, collapsed),
        done       = COALESCE(${patch.done      ?? null}, done),
        parent_id  = ${patch.parentId !== undefined ? patch.parentId  : db`parent_id`},
        updated_at = now()
      WHERE id = ${id} AND user_id = ${userId}
      RETURNING ${db.unsafe(RETURNING)}
    `
    return rows[0] ?? null
  },

  async delete(id: string, userId: string): Promise<boolean> {
    const result = await db`DELETE FROM notes WHERE id = ${id} AND user_id = ${userId}`
    return result.count > 0
  },
}
