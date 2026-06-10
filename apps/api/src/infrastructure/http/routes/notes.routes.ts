import type { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import { authenticate } from '../plugins/authenticate.js'
import { listNotes, createNote, updateNote, deleteNote } from '../../../application/note/notes.usecase.js'

const uid = (req: any): string => (req.user as { id: string }).id

const nodeTypeSchema = z.enum(['text', 'heading1', 'heading2', 'bullet', 'image', 'link'])

const createSchema = z.object({
  id:        z.string().uuid().optional(),
  parentId:  z.string().uuid().nullable().optional(),
  nodeType:  nodeTypeSchema.optional(),
  content:   z.string().max(10000).optional(),
  url:       z.string().url().nullable().optional(),
  sortOrder: z.number().int().optional(),
})

const updateSchema = z.object({
  nodeType:  nodeTypeSchema.optional(),
  content:   z.string().max(10000).optional(),
  url:       z.string().url().nullable().optional(),
  sortOrder: z.number().int().optional(),
  collapsed: z.boolean().optional(),
  parentId:  z.string().uuid().nullable().optional(),
})

export const notesRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', authenticate)

  // GET /api/notes
  fastify.get('/', async (req) => listNotes(uid(req)))

  // POST /api/notes
  fastify.post('/', async (req, reply) => {
    const body = createSchema.parse(req.body)
    const note = await createNote(uid(req), body)
    return reply.status(201).send(note)
  })

  // PATCH /api/notes/:id
  fastify.patch('/:id', async (req, reply) => {
    const { id } = req.params as { id: string }
    const patch = updateSchema.parse(req.body)
    try {
      return await updateNote(id, uid(req), patch)
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })

  // DELETE /api/notes/:id
  fastify.delete('/:id', async (req, reply) => {
    const { id } = req.params as { id: string }
    try {
      await deleteNote(id, uid(req))
      return reply.status(204).send()
    } catch (err: any) {
      return reply.status(err.statusCode ?? 500).send({ error: err.message })
    }
  })
}
