import cron from 'node-cron'
import { DateTime } from 'luxon'
import { db } from '../db/client.js'

/**
 * Scheduler runs every hour.
 * For each user (in their local timezone):
 *  - Archive done day-tasks from past days
 *  - Archive todo day-tasks from past days (failure)
 *  - Create new day-periods for recurring day-tasks
 *  - Transition week/month/year: todo → overdue at period end
 *  - Transition week/month/year: done → archived at period end
 *  - Transition week/month/year: overdue → backlog at penalty period end
 */

type UserTimezone = { id: string; timezone: string }

const processUser = async (user: UserTimezone) => {
  const now = DateTime.now().setZone(user.timezone)
  const todayStr = now.toISODate()!

  await archiveDayTasks(user.id, todayStr)
  await progressPeriodStatuses(user.id, todayStr)
  await rolloverRecurringDayTasks(user.id, todayStr)
}

/** Move past day-tasks to archived */
const archiveDayTasks = async (userId: string, today: string) => {
  // done day-tasks from past days → archived
  await db`
    UPDATE task_periods
    SET status = 'archived', archived_at = now()
    WHERE user_id         = ${userId}
      AND period_type     = 'day'
      AND period_end      < ${today}::date
      AND status          = 'done'
  `
  // todo day-tasks from past days → archived (failure, done_at stays NULL)
  await db`
    UPDATE task_periods
    SET status = 'archived', archived_at = now()
    WHERE user_id         = ${userId}
      AND period_type     = 'day'
      AND period_end      < ${today}::date
      AND status          = 'todo'
  `
}

/** week/month/year status transitions based on period_end */
const progressPeriodStatuses = async (userId: string, today: string) => {
  // todo → overdue (period ended, first chance gone)
  await db`
    UPDATE task_periods
    SET status = 'overdue'
    WHERE user_id     = ${userId}
      AND period_type IN ('week', 'month', 'year')
      AND period_end  < ${today}::date
      AND status      = 'todo'
  `
  // done → archived (period ended successfully)
  await db`
    UPDATE task_periods
    SET status = 'archived', archived_at = now()
    WHERE user_id     = ${userId}
      AND period_type IN ('week', 'month', 'year')
      AND period_end  < ${today}::date
      AND status      = 'done'
  `
  // overdue → backlog (penalty period also ended)
  // penalty period end = period_end + 1 period duration
  await db`
    UPDATE task_periods
    SET status = 'backlog', backlog_at = now()
    WHERE user_id     = ${userId}
      AND status      = 'overdue'
      AND (
        (period_type = 'week'  AND period_end + INTERVAL '7 days'  < ${today}::date) OR
        (period_type = 'month' AND period_end + INTERVAL '1 month' < ${today}::date) OR
        (period_type = 'year'  AND period_end + INTERVAL '1 year'  < ${today}::date)
      )
  `
}

/** Create new day-periods for recurring day-tasks that have no period today */
const rolloverRecurringDayTasks = async (userId: string, today: string) => {
  await db`
    INSERT INTO task_periods (task_id, user_id, period_type, period_start, period_end)
    SELECT t.id, t.user_id, 'day', ${today}::date, ${today}::date
    FROM tasks t
    JOIN recurring_configs rc ON rc.task_id = t.id
    WHERE t.user_id = ${userId}
      AND t.level   = 'day'
      AND rc.is_active = true
      AND NOT EXISTS (
        SELECT 1 FROM task_periods tp
        WHERE tp.task_id      = t.id
          AND tp.period_start = ${today}::date
          AND tp.status      != 'archived'
      )
  `
}

export const scheduler = {
  _task: null as ReturnType<typeof cron.schedule> | null,

  start() {
    // Run at the top of every hour
    this._task = cron.schedule('0 * * * *', () => this._tick())
    console.log('[scheduler] started (hourly)')
  },

  stop() {
    this._task?.stop()
  },

  async _tick() {
    try {
      const users = await db<UserTimezone[]>`SELECT id, timezone FROM users`
      await Promise.allSettled(users.map(processUser))
    } catch (err) {
      console.error('[scheduler] tick error', err)
    }
  },
}
