import type { NoteNode } from './note.types'

export const MOCK_NOTES: NoteNode[] = [
  {
    id: 'n1',
    type: 'heading1',
    content: 'Work',
    children: [
      {
        id: 'n1-1',
        type: 'heading2',
        content: 'Q3 Goals',
        children: [
          { id: 'n1-1-1', type: 'bullet', content: 'Launch API v1', children: [] },
          { id: 'n1-1-2', type: 'bullet', content: 'Connect web to real API', children: [
            { id: 'n1-1-2-1', type: 'text', content: 'Replace all mock data with live endpoints', children: [] },
            { id: 'n1-1-2-2', type: 'link', content: 'API docs', url: 'http://localhost:3000/docs', children: [] },
          ]},
          { id: 'n1-1-3', type: 'bullet', content: 'Implement scheduler', children: [] },
        ],
      },
      {
        id: 'n1-2',
        type: 'heading2',
        content: 'Resources',
        children: [
          { id: 'n1-2-1', type: 'link', content: 'Fastify docs', url: 'https://fastify.dev', children: [] },
          { id: 'n1-2-2', type: 'image', content: 'Architecture diagram', url: 'https://placehold.co/400x200', children: [] },
        ],
      },
    ],
  },
  {
    id: 'n2',
    type: 'heading1',
    content: 'Personal',
    children: [
      {
        id: 'n2-1',
        type: 'heading2',
        content: 'Reading list',
        children: [
          { id: 'n2-1-1', type: 'bullet', content: 'The Pragmatic Programmer', children: [] },
          { id: 'n2-1-2', type: 'bullet', content: 'Designing Data-Intensive Applications', children: [] },
        ],
      },
      {
        id: 'n2-2',
        type: 'text',
        content: 'Random thoughts go here. Just write freely.',
        children: [],
      },
    ],
  },
  {
    id: 'n3',
    type: 'heading1',
    content: 'Ideas',
    children: [
      { id: 'n3-1', type: 'bullet', content: 'Offline mode for mobile', children: [] },
      { id: 'n3-2', type: 'bullet', content: 'Recurring notes / templates', children: [] },
      { id: 'n3-3', type: 'bullet', content: 'Tag system across notes and tasks', children: [] },
    ],
  },
]
