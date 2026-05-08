import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { scheduler } from '../../scheduler/scheduler.js'

const tickBodySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
})

/**
 * Dev-only routes — registered only when NODE_ENV !== 'production'.
 * Prefix: /api/dev
 */
export const devRoutes: FastifyPluginAsync = async (fastify) => {
  /** POST /api/dev/tick  { date?: "YYYY-MM-DD" }
   *  Manually triggers a scheduler tick.
   *  Uses the supplied date as "today" for all users.
   */
  fastify.post('/tick', async (req, reply) => {
    const { date } = tickBodySchema.parse(req.body ?? {})
    try {
      const result = await scheduler.triggerTick(date)
      return reply.send({ ok: true, ...result })
    } catch (err: any) {
      return reply.status(500).send({ ok: false, error: err.message })
    }
  })
}
