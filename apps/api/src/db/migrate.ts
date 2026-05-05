import { readFile, readdir } from 'node:fs/promises'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { db } from '../infrastructure/db/client.js'

const __dir = dirname(fileURLToPath(import.meta.url))

const run = async () => {
  await db`
    CREATE TABLE IF NOT EXISTS migration_history (
      id          SERIAL PRIMARY KEY,
      filename    TEXT NOT NULL UNIQUE,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `

  const files = (await readdir(join(__dir, 'migrations')))
    .filter((f) => f.endsWith('.sql'))
    .sort()

  for (const file of files) {
    const [row] = await db`SELECT id FROM migration_history WHERE filename = ${file}`
    if (row) {
      console.log(`[migrate] skip   ${file}`)
      continue
    }

    const sql = await readFile(join(__dir, 'migrations', file), 'utf-8')
    await db.unsafe(sql)
    await db`INSERT INTO migration_history (filename) VALUES (${file})`
    console.log(`[migrate] applied ${file}`)
  }

  console.log('[migrate] done')
  await db.end()
}

run().catch((e) => {
  console.error('[migrate] error', e)
  process.exit(1)
})
