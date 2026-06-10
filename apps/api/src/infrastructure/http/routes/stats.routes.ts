import type { FastifyPluginAsync } from 'fastify'
import { authenticate } from '../plugins/authenticate.js'
import { statsUseCase } from '../../../application/stats/stats.usecase.js'

export const statsRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', authenticate)

  // GET /api/stats?today=YYYY-MM-DD
  fastify.get('/', async (req) => {
    const { id } = req.user as { id: string }
    const today = (req.query as { today?: string }).today
      ?? new Date().toISOString().slice(0, 10)
    return statsUseCase(id, today)
  })
}
