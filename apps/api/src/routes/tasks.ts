import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { db } from '../db/client.js'
import type { TaskLevel } from '@locus/shared'

const createTaskSchema = z.object({
  title: z.string().min(1).max(500),
  description: z.string().optional(),
  level: z.enum(['week', 'month', 'year']),
  deadline: z.string().datetime(),
  deadlineMonth: z.number().min(1).max(12).optional(),
  archiveDelayMinutes: z.number().min(0).default(120),
})

const updateTaskSchema = z.object({
  title: z.string().min(1).max(500).optional(),
  description: z.string().optional(),
  status: z.enum(['todo', 'done', 'archived', 'failed', 'backlog']).optional(),
  archiveDelayMinutes: z.number().min(0).optional(),
})

export const taskRoutes: FastifyPluginAsync = async (fastify) => {
  // Auth guard
  fastify.addHook('onRequest', async (req, reply) => {
    try {
      await req.jwtVerify()
    } catch {
      reply.status(401).send({ error: 'Unauthorized' })
    }
  })

  // GET /api/tasks?level=week&status=todo
  fastify.get('/', async (req) => {
    const { level, status } = req.query as { level?: TaskLevel; status?: string }
    const userId = (req.user as { id: string }).id

    const conditions: string[] = ['user_id = $1']
    const params: unknown[] = [userId]
    let idx = 2

    if (level) {
      conditions.push(`level = $${idx++}`)
      params.push(level)
    }
    if (status) {
      conditions.push(`status = $${idx++}`)
      params.push(status)
    }

    const where = conditions.join(' AND ')
    const tasks = await db.unsafe(
      `SELECT * FROM tasks WHERE ${where} ORDER BY deadline ASC`,
      params as string[],
    )
    return tasks
  })

  // POST /api/tasks
  fastify.post('/', async (req, reply) => {
    const userId = (req.user as { id: string }).id
    const body = createTaskSchema.parse(req.body)

    const [task] = await db`
      INSERT INTO tasks (
        user_id, title, description, level, deadline,
        deadline_month, archive_delay_minutes
      ) VALUES (
        ${userId}, ${body.title}, ${body.description ?? null},
        ${body.level}, ${body.deadline},
        ${body.deadlineMonth ?? null}, ${body.archiveDelayMinutes}
      )
      RETURNING *
    `
    return reply.status(201).send(task)
  })

  // PATCH /api/tasks/:id
  fastify.patch('/:id', async (req, reply) => {
    const userId = (req.user as { id: string }).id
    const { id } = req.params as { id: string }
    const body = updateTaskSchema.parse(req.body)

    const updates: Record<string, unknown> = { ...body }

    // When marking done, record timestamp
    if (body.status === 'done') {
      updates.done_at = new Date().toISOString()
    }

    const setClauses = Object.keys(updates)
      .map((k, i) => `${toSnake(k)} = $${i + 3}`)
      .join(', ')

    if (!setClauses) return reply.status(400).send({ error: 'No fields to update' })

    const [task] = await db.unsafe(
      `UPDATE tasks SET ${setClauses} WHERE id = $1 AND user_id = $2 RETURNING *`,
      [id, userId, ...Object.values(updates)] as string[],
    )

    if (!task) return reply.status(404).send({ error: 'Not found' })
    return task
  })

  // DELETE /api/tasks/:id
  fastify.delete('/:id', async (req, reply) => {
    const userId = (req.user as { id: string }).id
    const { id } = req.params as { id: string }

    const [task] = await db`
      DELETE FROM tasks WHERE id = ${id} AND user_id = ${userId} RETURNING id
    `
    if (!task) return reply.status(404).send({ error: 'Not found' })
    return reply.status(204).send()
  })
}

const toSnake = (s: string) =>
  s.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`)
