import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { userRepository } from '../../db/user.repository.js'
import { registerUseCase } from '../../../application/auth/register.usecase.js'
import { loginUseCase } from '../../../application/auth/login.usecase.js'
import { authenticate } from '../plugins/authenticate.js'
import { redis } from '../../redis/client.js'
import { createRefreshTokenService } from '../../auth/refresh-token.service.js'

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

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
})

const profileSchema = z.object({
  name:  z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
}).refine((d) => d.name !== undefined || d.email !== undefined, {
  message: 'At least one field required',
})

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  const sign = (payload: object) =>
    fastify.jwt.sign(payload, { expiresIn: process.env.JWT_EXPIRES_IN ?? '15m' })

  const tokens = createRefreshTokenService(redis)

  fastify.post('/register', async (req, reply) => {
    const input = registerSchema.parse(req.body)
    try {
      const result = await registerUseCase(userRepository, input, sign, tokens.create)
      return reply.status(201).send(result)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message ?? 'Internal server error' })
    }
  })

  fastify.post('/login', async (req, reply) => {
    const input = loginSchema.parse(req.body)
    try {
      const result = await loginUseCase(userRepository, input, sign, tokens.create)
      return reply.send(result)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message ?? 'Internal server error' })
    }
  })

  fastify.post('/refresh', async (req, reply) => {
    const { refreshToken } = refreshSchema.parse(req.body)

    const userId = await tokens.validate(refreshToken)
    if (!userId) {
      return reply.status(401).send({ error: 'Invalid or expired refresh token' })
    }

    const user = await userRepository.findById(userId)
    if (!user) {
      await tokens.revoke(refreshToken)
      return reply.status(401).send({ error: 'User not found' })
    }

    const newRefreshToken = await tokens.rotate(refreshToken, userId)
    const accessToken = sign({ id: user.id, email: user.email })

    return reply.send({ accessToken, refreshToken: newRefreshToken })
  })

  fastify.post('/logout', async (req, reply) => {
    const parsed = refreshSchema.safeParse(req.body)
    if (parsed.success) {
      await tokens.revoke(parsed.data.refreshToken)
    }
    return reply.status(204).send()
  })

  fastify.get('/me', { onRequest: [authenticate] }, async (req, reply) => {
    const { id } = req.user as { id: string }
    const user = await userRepository.findById(id)
    if (!user) return reply.status(404).send({ error: 'User not found' })
    return user
  })

  fastify.patch('/profile', { onRequest: [authenticate] }, async (req, reply) => {
    const { id } = req.user as { id: string }
    const input = profileSchema.parse(req.body)
    const user = await userRepository.update(id, input)
    if (!user) return reply.status(404).send({ error: 'User not found' })
    return user
  })
}
