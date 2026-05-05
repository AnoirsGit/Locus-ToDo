import type { FastifyRequest, FastifyReply } from 'fastify'

/** Prehandler that verifies JWT. Use as: { onRequest: [authenticate] } */
export const authenticate = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    await req.jwtVerify()
  } catch {
    reply.status(401).send({ error: 'Unauthorized' })
  }
}
