import Fastify from 'fastify'
import cors from '@fastify/cors'
import jwt from '@fastify/jwt'
import { authRoutes } from './infrastructure/http/routes/auth.routes.js'
import { taskRoutes } from './infrastructure/http/routes/tasks.routes.js'
import { taskPeriodRoutes } from './infrastructure/http/routes/task-periods.routes.js'
import { statsRoutes } from './infrastructure/http/routes/stats.routes.js'
import { notesRoutes } from './infrastructure/http/routes/notes.routes.js'
import { tagsRoutes } from './infrastructure/http/routes/tags.routes.js'
import { scheduler } from './infrastructure/scheduler/scheduler.js'
import { db } from './infrastructure/db/client.js'
import { redis } from './infrastructure/redis/client.js'

const server = Fastify({ logger: true })

const start = async () => {
  await server.register(cors, {
    origin: process.env.CORS_ORIGIN ?? 'http://localhost:5173',
    credentials: true,
  })

  await server.register(jwt, {
    secret: process.env.JWT_SECRET ?? 'dev-secret-change-in-production',
    sign: { expiresIn: process.env.JWT_EXPIRES_IN ?? '15m' },
  })

  await server.register(authRoutes,       { prefix: '/api/auth' })
  await server.register(taskRoutes,       { prefix: '/api/tasks' })
  await server.register(taskPeriodRoutes, { prefix: '/api/task-periods' })
  await server.register(statsRoutes,      { prefix: '/api/stats' })
  await server.register(notesRoutes,      { prefix: '/api/notes' })
  await server.register(tagsRoutes,       { prefix: '/api/tags' })

  server.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }))

  server.setErrorHandler((err: any, _req, reply) => {
    if (err.validation) {
      return reply.status(400).send({ error: 'Validation error', details: err.validation })
    }
    server.log.error(err)
    return reply.status(err.statusCode ?? 500).send({ error: err.message ?? 'Internal server error' })
  })

  for (let attempt = 1; attempt <= 10; attempt++) {
    try {
      await db`SELECT 1`
      server.log.info('Database connection established successfully')
      break
    } catch (err) {
      if (attempt === 10) throw err
      server.log.warn(`DB not ready (attempt ${attempt}/10), retrying in 2s…`)
      await new Promise(r => setTimeout(r, 2000))
    }
  }

  await redis.connect()
  server.log.info('Redis connection established successfully')

  await server.listen({
    port: Number(process.env.PORT ?? 3000),
    host: process.env.HOST ?? '0.0.0.0',
  })

  await scheduler.start()

  const shutdown = async () => {
    await redis.quit()
    await server.close()
    process.exit(0)
  }
  process.once('SIGTERM', shutdown)
  process.once('SIGINT', shutdown)
}

start().catch((err) => {
  console.error(err)
  process.exit(1)
})