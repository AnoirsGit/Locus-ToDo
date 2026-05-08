import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { taskRepository } from '../../db/task.repository.js'
import { authenticate } from '../plugins/authenticate.js'
import { createTaskUseCase } from '../../../application/task/create-task.usecase.js'
import { listTasksUseCase, listBacklogUseCase, listArchiveUseCase } from '../../../application/task/list-tasks.usecase.js'
import { updateTaskUseCase } from '../../../application/task/update-task.usecase.js'
import { replanTaskUseCase } from '../../../application/task/replan-task.usecase.js'
import { deleteTaskUseCase } from '../../../application/task/delete-task.usecase.js'
import { toMonday } from '../../../application/period-utils.js'

// Validates that the string is a real calendar date (not just format)
const isoDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Must be YYYY-MM-DD')
  .refine((s) => {
    const d = new Date(s + 'T00:00:00Z')
    return !isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s
  }, 'Invalid date')

const recurringConfigSchema = z.object({
  daysOfWeek:  z.array(z.number().int().min(0).max(6)).min(1).max(6).optional(),
  dayOfMonth:  z.number().int().min(1).max(31).optional(),
  monthOfYear: z.number().int().min(1).max(12).optional(),
  isActive:    z.boolean(),
})

const LEVEL_ORDER: Record<string, number> = { day: 0, week: 1, month: 2, year: 3 }

const createSchema = z.object({
  title:           z.string().min(1).max(500),
  description:     z.string().optional(),
  level:           z.enum(['day', 'week', 'month', 'year']),
  periodStart:     isoDate,
  scheduledTime:   z.string().regex(/^\d{2}:\d{2}$/).optional(),
  targetDate:      isoDate.optional(),
  deadlineMonth:   z.number().int().min(1).max(12).optional(),
  parentTaskId:    z.string().uuid().optional(),
  recurringConfig: recurringConfigSchema.optional(),
})

const updateSchema = z.object({
  title:           z.string().min(1).max(500).optional(),
  description:     z.string().nullable().optional(),
  scheduledTime:   z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(),
  targetDate:      isoDate.nullable().optional(),
  deadlineMonth:   z.number().int().min(1).max(12).nullable().optional(),
  recurringConfig: recurringConfigSchema.nullable().optional(),
})

const replanSchema = z.object({
  periodStart: isoDate,
})

const listQuerySchema = z.object({
  periodType:  z.enum(['day', 'week', 'month', 'year']).optional(),
  periodStart: isoDate.optional(),
  status:      z.string().optional(),
  limit:       z.coerce.number().int().min(1).max(200).optional(),
  offset:      z.coerce.number().int().min(0).optional(),
  view:        z.enum(['day', 'week', 'month', 'year', 'backlog', 'archive']).optional(),
})

export const taskRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', authenticate)

  const userId = (req: { user: unknown }) => (req.user as { id: string }).id

  // GET /api/tasks?view=week
  // GET /api/tasks?periodType=week&periodStart=YYYY-MM-DD
  // GET /api/tasks?status=backlog
  // GET /api/tasks?status=archived&limit=50&offset=0
  fastify.get('/', async (req, reply) => {
    const q   = listQuerySchema.parse(req.query)
    const uid = userId(req)

    // Shorthand: ?view=X resolves to the correct period
    if (q.view) {
      if (q.view === 'backlog')  return listBacklogUseCase(taskRepository, uid)
      if (q.view === 'archive')  return listArchiveUseCase(taskRepository, uid, q.limit, q.offset)

      const today = new Date().toISOString().slice(0, 10)
      let periodStart: string
      if (q.view === 'week')  periodStart = toMonday(today)
      else if (q.view === 'month') {
        const d = new Date(today + 'T00:00:00Z')
        periodStart = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1)).toISOString().slice(0, 10)
      } else if (q.view === 'year') {
        periodStart = `${new Date().getUTCFullYear()}-01-01`
      } else {
        periodStart = today
      }
      return listTasksUseCase(taskRepository, uid, q.view, periodStart)
    }

    if (q.status === 'backlog')  return listBacklogUseCase(taskRepository, uid)
    if (q.status === 'archived') return listArchiveUseCase(taskRepository, uid, q.limit, q.offset)

    if (!q.periodType || !q.periodStart) {
      return reply.status(400).send({ error: 'periodType and periodStart are required (or use ?view=)' })
    }

    // Snap week periodStart to Monday to avoid drift
    const periodStart = q.periodType === 'week' ? toMonday(q.periodStart) : q.periodStart
    return listTasksUseCase(taskRepository, uid, q.periodType, periodStart)
  })

  // POST /api/tasks
  fastify.post('/', async (req, reply) => {
    const raw   = createSchema.parse(req.body)
    const input = {
      ...raw,
      periodStart: raw.level === 'week' ? toMonday(raw.periodStart) : raw.periodStart,
    }

    // Validate subtask level ≤ parent level
    if (input.parentTaskId) {
      const parent = await taskRepository.findPeriodById(input.parentTaskId, userId(req))
      if (!parent) return reply.status(404).send({ error: 'Parent task not found' })
      if (LEVEL_ORDER[input.level] > LEVEL_ORDER[parent.level]) {
        return reply.status(400).send({ error: `Subtask level must be ≤ parent level (${parent.level})` })
      }
    }

    try {
      const item = await createTaskUseCase(taskRepository, { ...input, userId: userId(req) })
      return reply.status(201).send(item)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // GET /api/tasks/:taskId/subtasks
  fastify.get('/:taskId/subtasks', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    try {
      return await taskRepository.listSubtasks(taskId, userId(req))
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // PATCH /api/tasks/:taskId
  fastify.patch('/:taskId', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    const patch = updateSchema.parse(req.body)
    try {
      return await updateTaskUseCase(taskRepository, taskId, userId(req), patch)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // POST /api/tasks/:taskId/replan
  fastify.post('/:taskId/replan', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    const raw = replanSchema.parse(req.body)
    // Snap week to Monday
    const periodStart = raw.periodStart // level unknown here, snapped in usecase
    try {
      return await replanTaskUseCase(taskRepository, taskId, userId(req), periodStart)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // DELETE /api/tasks/:taskId
  fastify.delete('/:taskId', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    try {
      await deleteTaskUseCase(taskRepository, taskId, userId(req))
      return reply.status(204).send()
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })
}
