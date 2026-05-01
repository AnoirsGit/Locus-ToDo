import postgres from 'postgres'

const connectionString = process.env.DATABASE_URL ?? 'postgres://postgres:postgres@localhost:5432/locus_todo'

export const db = postgres(connectionString, {
  max: 10,
  idle_timeout: 30,
})
