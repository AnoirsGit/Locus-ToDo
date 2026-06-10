import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { authenticate } from '../plugins/authenticate.js'
import {
  listTags, createTag, updateTag, deleteTag,
  getAllTaskTagsForUser,
  getTaskTags, setTaskTags, getNoteTags, setNoteTags,
} from '../../../application/tag/tags.usecase.js'

const uid = (req: any): string => (req.user as { id: string }).id

const createSchema = z.object({
  name:  z.string().min(1).max(50),
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/).nullable().optional(),
})

const updateSchema = z.object({
  name:  z.string().min(1).max(50).optional(),
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/).nullable().optional(),
})

const tagIdsSchema = z.object({ tagIds: z.array(z.string().uuid()) })

export const tagsRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', authenticate)

  // GET /api/tags
  fastify.get('/', async (req) => listTags(uid(req)))

  // POST /api/tags
  fastify.post('/', async (req, reply) => {
    const { name, color } = createSchema.parse(req.body)
    try {
      const tag = await createTag(uid(req), name, color)
      return reply.status(201).send(tag)
    } catch (err: any) {
      if (err.code === '23505') return reply.status(409).send({ error: 'Tag name already exists' })
      return reply.status(500).send({ error: err.message })
    }
  })

  // PATCH /api/tags/:id
  fastify.patch('/:id', async (req, reply) => {
    const { id } = req.params as { id: string }
    const patch = updateSchema.parse(req.body)
    try {
      return await updateTag(id, uid(req), patch)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // DELETE /api/tags/:id
  fastify.delete('/:id', async (req, reply) => {
    const { id } = req.params as { id: string }
    try {
      await deleteTag(id, uid(req))
      return reply.status(204).send()
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // GET /api/tags/task-assignments — all task-tag pairs for the authenticated user
  fastify.get('/task-assignments', async (req) => getAllTaskTagsForUser(uid(req)))

  // GET /api/tags/tasks/:taskId
  fastify.get('/tasks/:taskId', async (req) => {
    const { taskId } = req.params as { taskId: string }
    return getTaskTags(taskId)
  })

  // PUT /api/tags/tasks/:taskId  { tagIds: [...] }
  fastify.put('/tasks/:taskId', async (req, reply) => {
    const { taskId } = req.params as { taskId: string }
    const { tagIds } = tagIdsSchema.parse(req.body)
    await setTaskTags(taskId, tagIds)
    return reply.status(204).send()
  })

  // GET /api/tags/notes/:noteId
  fastify.get('/notes/:noteId', async (req) => {
    const { noteId } = req.params as { noteId: string }
    return getNoteTags(noteId)
  })

  // PUT /api/tags/notes/:noteId  { tagIds: [...] }
  fastify.put('/notes/:noteId', async (req, reply) => {
    const { noteId } = req.params as { noteId: string }
    const { tagIds } = tagIdsSchema.parse(req.body)
    await setNoteTags(noteId, tagIds)
    return reply.status(204).send()
  })
}
