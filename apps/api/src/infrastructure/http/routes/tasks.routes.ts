import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { taskRepository } from '../../db/task.repository.js'
import { authenticate } from '../plugins/authenticate.js'
import { createTaskUseCase } from '../../../application/task/create-task.usecase.js'
import { listTasksUseCase, listBacklogUseCase, listArchiveUseCase } from '../../../application/task/list-tasks.usecase.js'
import { updateTaskUseCase } from '../../../application/task/update-task.usecase.js'
import { replanTaskUseCase } from '../../../application/task/replan-task.usecase.js'
import { deleteTaskUseCase } from '../../../application/task/delete-task.usecase.js'

const createSchema = z.object({
  title:         z.string().min(1).max(500),
  description:   z.string().optional(),
  level:         z.enum(['day', 'week', 'month', 'year']),
  periodStart:   z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  scheduledTime: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  targetDate:    z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  deadlineMonth: z.number().int().min(1).max(12).optional(),
  recurringConfig: z.object({
    dayOfWeek:  z.number().int().min(0).max(6).optional(),
    dayOfMonth: z.number().int().min(1).max(31).optional(),
    isActive:   z.boolean(),
  }).optional(),
})

const updateSchema = z.object({
  title:         z.string().min(1).max(500).optional(),
  description:   z.string().nullable().optional(),
  scheduledTime: z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(),
})

const replanSchema = z.object({
  periodStart: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
})

const listQuerySchema = z.object({
  periodType:  z.enum(['day', 'week', 'month', 'year']).optional(),
  periodStart: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  status:      z.string().optional(),
  limit:       z.coerce.number().int().min(1).max(200).optional(),
  offset:      z.coerce.number().int().min(0).optional(),
})

export const taskRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', authenticate)

  const userId = (req: { user: unknown }) => (req.user as { id: string }).id

  // GET /api/tasks?periodType=week&periodStart=YYYY-MM-DD
  // GET /api/tasks?status=backlog
  // GET /api/tasks?status=archived&limit=50&offset=0
  fastify.get('/', async (req, reply) => {
    const q = listQuerySchema.parse(req.query)
    const uid = userId(req)

    if (q.status === 'backlog') return listBacklogUseCase(taskRepository, uid)
    if (q.status === 'archived') return listArchiveUseCase(taskRepository, uid, q.limit, q.offset)

    if (!q.periodType || !q.periodStart) {
      return reply.status(400).send({ error: 'periodType and periodStart are required' })
    }
    return listTasksUseCase(taskRepository, uid, q.periodType, q.periodStart)
  })

  // POST /api/tasks
  fastify.post('/', async (req, reply) => {
    const input = createSchema.parse(req.body)
    try {
      const item = await createTaskUseCase(taskRepository, { ...input, userId: userId(req) })
      return reply.status(201).send(item)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // PATCH /api/tasks/:taskId  — update task metadata
  fastify.patch('/:taskId', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    const patch = updateSchema.parse(req.body)
    try {
      return await updateTaskUseCase(taskRepository, taskId, userId(req), patch)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // POST /api/tasks/:taskId/replan  — replan from backlog to new period
  fastify.post('/:taskId/replan', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    const { periodStart } = replanSchema.parse(req.body)

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
