import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { db } from '../db/client.js'
import { createHash } from 'node:crypto'

const registerSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  password: z.string().min(8),
})

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
})

const hashPassword = (password: string) =>
  createHash('sha256').update(password).digest('hex')

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.post('/register', async (req, reply) => {
    const { email, name, password } = registerSchema.parse(req.body)

    const [existing] = await db`SELECT id FROM users WHERE email = ${email}`
    if (existing) return reply.status(409).send({ error: 'Email already in use' })

    const [user] = await db`
      INSERT INTO users (email, name, password_hash)
      VALUES (${email}, ${name}, ${hashPassword(password)})
      RETURNING id, email, name, created_at
    `

    const token = fastify.jwt.sign({ id: user.id, email: user.email })
    return reply.status(201).send({ user, token })
  })

  fastify.post('/login', async (req, reply) => {
    const { email, password } = loginSchema.parse(req.body)

    const [user] = await db`
      SELECT id, email, name, password_hash, created_at
      FROM users WHERE email = ${email}
    `

    if (!user || user.password_hash !== hashPassword(password)) {
      return reply.status(401).send({ error: 'Invalid credentials' })
    }

    const token = fastify.jwt.sign({ id: user.id, email: user.email })
    return { user: { id: user.id, email: user.email, name: user.name }, token }
  })

  fastify.get('/me', { onRequest: [fastify.authenticate] }, async (req) => {
    const { id } = req.user as { id: string }
    const [user] = await db`SELECT id, email, name, created_at FROM users WHERE id = ${id}`
    return user
  })
}
