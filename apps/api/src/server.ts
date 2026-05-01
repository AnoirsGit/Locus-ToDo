import Fastify from 'fastify'
import cors from '@fastify/cors'
import jwt from '@fastify/jwt'
import { taskRoutes } from './routes/tasks.js'
import { authRoutes } from './routes/auth.js'
import { db } from './db/client.js'
import { scheduler } from './services/scheduler.js'

const server = Fastify({ logger: true })

const start = async () => {
  await server.register(cors, {
    origin: process.env.CORS_ORIGIN ?? 'http://localhost:5173',
    credentials: true,
  })

  await server.register(jwt, {
    secret: process.env.JWT_SECRET ?? 'dev-secret',
  })

  await server.register(authRoutes, { prefix: '/api/auth' })
  await server.register(taskRoutes, { prefix: '/api/tasks' })

  server.get('/health', async () => ({ status: 'ok' }))

  await server.listen({
    port: Number(process.env.PORT ?? 3000),
    host: process.env.HOST ?? '0.0.0.0',
  })

  scheduler.start()
}

start().catch((err) => {
  console.error(err)
  process.exit(1)
})
