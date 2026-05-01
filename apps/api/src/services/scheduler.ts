import { db } from '../db/client.js'

/**
 * Background scheduler — runs every minute.
 *
 * Two jobs:
 *  A) Auto-archive tasks that have been Done long enough.
 *  B) Fail overdue tasks that were never marked Done.
 */
export const scheduler = {
  _interval: null as NodeJS.Timeout | null,

  start() {
    this._interval = setInterval(() => this._tick(), 60_000)
    console.log('[scheduler] started')
  },

  stop() {
    if (this._interval) clearInterval(this._interval)
  },

  async _tick() {
    await Promise.allSettled([this._archiveDone(), this._failOverdue()])
  },

  /** Move done tasks to archived once the delay has passed */
  async _archiveDone() {
    await db`
      UPDATE tasks
      SET status = 'archived', archived_at = now()
      WHERE status = 'done'
        AND done_at + (archive_delay_minutes * INTERVAL '1 minute') <= now()
    `
  },

  /** Move overdue todo tasks to backlog with failed_at timestamp */
  async _failOverdue() {
    await db`
      UPDATE tasks
      SET status = 'backlog', failed_at = now()
      WHERE status = 'todo'
        AND deadline < now()
    `
  },
}
