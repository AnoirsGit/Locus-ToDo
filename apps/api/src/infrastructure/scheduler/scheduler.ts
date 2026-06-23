import cron from 'node-cron'
import { DateTime } from 'luxon'
import { db } from '../db/client.js'
import type { TaskLevel } from '@locus/shared'
import { computePeriodEnd, currentPeriodStart } from '../../application/period-utils.js'

/**
 * Scheduler runs every hour.
 * For each user (in their local timezone):
 *  1. Rollover ended recurring week/month/year tasks (archive + create next period)
 *  2. Archive done day-tasks from past days
 *  3. Archive failed (todo) day-tasks from past days
 *  4. NON-recurring: todo → overdue at period end
 *  5. NON-recurring: done → archived at period end
 *  6. NON-recurring: overdue → backlog at penalty period end
 *  7. Create new day-periods for recurring day-tasks
 */

type UserTimezone = { id: string; timezone: string }

const processUser = async (user: UserTimezone, overrideDate?: string) => {
  const now      = DateTime.now().setZone(user.timezone)
  const todayStr = overrideDate ?? now.toISODate()!

  await rolloverRecurringPeriods(user.id, todayStr)
  await archiveDayTasks(user.id, todayStr)
  await progressPeriodStatuses(user.id, todayStr)
  await rolloverRecurringDayTasks(user.id, todayStr)
}

/**
 * Handle recurring week/month/year tasks:
 * 1. Archive any ended period (done OR todo — both count as complete/failed, no overdue for recurring)
 * 2. Create the current period if none exists
 */
const rolloverRecurringPeriods = async (userId: string, today: string) => {
  // Archive all ended periods for recurring week/month/year tasks
  await db`
    UPDATE task_periods tp
    SET    status = 'archived', archived_at = now()
    FROM   tasks t
    JOIN   recurring_configs rc ON rc.task_id = t.id
    WHERE  tp.task_id     = t.id
      AND  t.user_id      = ${userId}
      AND  t.level        IN ('week', 'month', 'year')
      AND  rc.is_active   = true
      AND  tp.period_end  < ${today}::date
      AND  tp.status      IN ('todo', 'done', 'overdue')
  `

  // Find recurring tasks that have no active (non-archived) period
  const tasks = await db<{ id: string; level: TaskLevel }[]>`
    SELECT t.id, t.level
    FROM   tasks t
    JOIN   recurring_configs rc ON rc.task_id = t.id
    WHERE  t.user_id    = ${userId}
      AND  t.level      IN ('week', 'month', 'year')
      AND  rc.is_active = true
      AND  NOT EXISTS (
        SELECT 1 FROM task_periods tp
        WHERE  tp.task_id = t.id
          AND  tp.status  NOT IN ('archived')
      )
  `

  for (const task of tasks) {
    const periodStart = currentPeriodStart(task.level, today)
    const periodEnd   = computePeriodEnd(task.level, periodStart)
    await db`
      INSERT INTO task_periods (task_id, user_id, period_type, period_start, period_end)
      VALUES (
        ${task.id}, ${userId}, ${task.level},
        ${periodStart}::date, ${periodEnd}::date
      )
      ON CONFLICT DO NOTHING
    `
  }
}

/** Archive past day-tasks (done = success, todo = failure) */
const archiveDayTasks = async (userId: string, today: string) => {
  await db`
    UPDATE task_periods
    SET    status = 'archived', archived_at = now()
    WHERE  user_id     = ${userId}
      AND  period_type = 'day'
      AND  period_end  < ${today}::date
      AND  status      IN ('done', 'todo')
  `
}

/**
 * Status transitions for NON-recurring week/month/year tasks only.
 * Recurring tasks are handled by rolloverRecurringPeriods above.
 */
const progressPeriodStatuses = async (userId: string, today: string) => {
  const recurringTaskIds = db`
    SELECT task_id FROM recurring_configs WHERE is_active = true
  `

  // §6 Year task with a monthly deadline: the period stays the full year, but
  // the deadline narrows to deadline_month. Once that month has ended, resolve
  // immediately (skipping overdue). `period_start + N months` is the first day
  // after the deadline month, so today >= that means the month is fully over.

  // done → archived (completed by the deadline month — success)
  await db`
    UPDATE task_periods
    SET    status = 'archived', archived_at = now()
    WHERE  user_id        = ${userId}
      AND  period_type    = 'year'
      AND  deadline_month IS NOT NULL
      AND  status         = 'done'
      AND  ${today}::date >= (period_start + (deadline_month || ' months')::interval)::date
      AND  task_id        NOT IN (${recurringTaskIds})
  `

  // todo → backlog (missed the deadline month)
  await db`
    UPDATE task_periods
    SET    status = 'backlog', backlog_at = now()
    WHERE  user_id        = ${userId}
      AND  period_type    = 'year'
      AND  deadline_month IS NOT NULL
      AND  status         = 'todo'
      AND  ${today}::date >= (period_start + (deadline_month || ' months')::interval)::date
      AND  task_id        NOT IN (${recurringTaskIds})
  `

  // todo → overdue (period ended, non-recurring only)
  await db`
    UPDATE task_periods
    SET    status = 'overdue'
    WHERE  user_id     = ${userId}
      AND  period_type IN ('week', 'month', 'year')
      AND  period_end  < ${today}::date
      AND  status      = 'todo'
      AND  task_id     NOT IN (${recurringTaskIds})
  `

  // done → archived (period ended successfully, non-recurring only)
  await db`
    UPDATE task_periods
    SET    status = 'archived', archived_at = now()
    WHERE  user_id     = ${userId}
      AND  period_type IN ('week', 'month', 'year')
      AND  period_end  < ${today}::date
      AND  status      = 'done'
      AND  task_id     NOT IN (${recurringTaskIds})
  `

  // overdue → backlog (penalty period ended: same duration as original period)
  await db`
    UPDATE task_periods
    SET    status = 'backlog', backlog_at = now()
    WHERE  user_id = ${userId}
      AND  status  = 'overdue'
      AND  (
        (period_type = 'week'  AND period_end + INTERVAL '7 days'  < ${today}::date) OR
        (period_type = 'month' AND period_end + INTERVAL '1 month' < ${today}::date) OR
        (period_type = 'year'  AND period_end + INTERVAL '1 year'  < ${today}::date)
      )
  `
}

/**
 * Create new day-periods for recurring day-tasks that have no active period today.
 * If days_of_week is set, only create when today's DOW is in that array.
 */
const rolloverRecurringDayTasks = async (userId: string, today: string) => {
  await db`
    INSERT INTO task_periods (task_id, user_id, period_type, period_start, period_end)
    SELECT t.id, t.user_id, 'day', ${today}::date, ${today}::date
    FROM   tasks t
    JOIN   recurring_configs rc ON rc.task_id = t.id
    WHERE  t.user_id    = ${userId}
      AND  t.level      = 'day'
      AND  rc.is_active = true
      AND  (
        rc.days_of_week IS NULL
        OR EXTRACT(DOW FROM ${today}::date)::SMALLINT = ANY(rc.days_of_week)
      )
      AND  NOT EXISTS (
        SELECT 1 FROM task_periods tp
        WHERE  tp.task_id      = t.id
          AND  tp.period_start = ${today}::date
          AND  tp.status      != 'archived'
      )
  `
}

export const scheduler = {
  _task: null as ReturnType<typeof cron.schedule> | null,

  async start() {
    this._task = cron.schedule('0 * * * *', () => this._tick())
    console.log('[scheduler] started (hourly)')
    // Run one pass immediately on startup so task states are reconciled without
    // waiting for the top of the hour. Wrapped so a tick failure never crashes boot.
    try {
      const r = await this._tick()
      console.log(`[scheduler] startup tick done (users=${r.users}, date=${r.date})`)
    } catch (e) {
      console.error('[scheduler] startup tick failed', e)
    }
  },

  stop() {
    this._task?.stop()
  },

  async _tick(overrideDate?: string) {
    const users = await db<UserTimezone[]>`SELECT id, timezone FROM users`
    const results = await Promise.allSettled(users.map((u) => processUser(u, overrideDate)))
    results.forEach((r, i) => {
      if (r.status === 'rejected') {
        console.error(`[scheduler] error for user ${users[i]?.id}:`, r.reason)
      }
    })
    return { users: users.length, date: overrideDate ?? DateTime.now().toISODate() }
  },

  /** Trigger a tick with an optional date override — used by the dev API. */
  async triggerTick(overrideDate?: string) {
    return this._tick(overrideDate)
  },
}
