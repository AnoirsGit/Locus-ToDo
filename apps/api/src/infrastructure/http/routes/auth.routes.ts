import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { userRepository } from '../../db/user.repository.js'
import { registerUseCase } from '../../../application/auth/register.usecase.js'
import { loginUseCase } from '../../../application/auth/login.usecase.js'
import { authenticate } from '../plugins/authenticate.js'

const registerSchema = z.object({
  email:    z.string().email(),
  name:     z.string().min(1).max(100),
  password: z.string().min(8),
  timezone: z.string().optional(),
})

const loginSchema = z.object({
  email:    z.string().email(),
  password: z.string(),
})

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  const sign = (payload: object) => fastify.jwt.sign(payload)

  fastify.post('/register', async (req, reply) => {
    const input = registerSchema.parse(req.body)
    try {
      const result = await registerUseCase(userRepository, input, sign)
      return reply.status(201).send(result)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message ?? 'Internal server error' })
    }
  })

  fastify.post('/login', async (req, reply) => {
    const input = loginSchema.parse(req.body)
    try {
      const result = await loginUseCase(userRepository, input, sign)
      return reply.send(result)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message ?? 'Internal server error' })
    }
  })

  fastify.get('/me', { onRequest: [authenticate] }, async (req, reply) => {
    const { id } = req.user as { id: string }
    const user = await userRepository.findById(id)
    if (!user) return reply.status(404).send({ error: 'User not found' })
    return user
  })
}
