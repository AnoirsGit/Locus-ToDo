import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { taskRepository } from '../../db/task.repository.js'
import { authenticate } from '../plugins/authenticate.js'
import { togglePeriodUseCase } from '../../../application/task/toggle-period.usecase.js'

const toggleSchema = z.object({
  status: z.enum(['todo', 'done']),
})

export const taskPeriodRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', authenticate)

  const userId = (req: { user: unknown }) => (req.user as { id: string }).id

  // PATCH /api/task-periods/:periodId — toggle done/todo
  fastify.patch('/:periodId', async (req, reply) => {
    const { periodId } = req.params as { periodId: string }
    const { status } = toggleSchema.parse(req.body)
    try {
      return await togglePeriodUseCase(taskRepository, periodId, userId(req), status)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })
}
