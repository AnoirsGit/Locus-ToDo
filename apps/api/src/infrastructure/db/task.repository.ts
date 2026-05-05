import type { ITaskRepository, CreateTaskInput, UpdateTaskInput, ListPeriodsInput } from '../../domain/task/task.port.js'
import type { TaskWithPeriod, TaskPeriod, TaskLevel, TaskStatus } from '@locus/shared'
import { db } from './client.js'

// ─── Row type returned by DB (snake_case → camelCase via postgres.camel) ─────

type TaskRow = {
  id: string; userId: string; title: string; description?: string
  level: TaskLevel; scheduledTime?: string
  createdAt: string; updatedAt: string
}

type PeriodRow = {
  pId: string; pTaskId: string; pUserId: string
  pPeriodType: TaskLevel; pPeriodStart: string; pPeriodEnd: string
  pStatus: TaskStatus
  pTargetDate?: string; pDeadlineMonth?: number; pSortOrder: number
  pDoneAt?: string; pBacklogAt?: string; pArchivedAt?: string
  pCreatedAt: string; pUpdatedAt: string
}

type RcRow = {
  rcId: string; rcTaskId: string
  rcDayOfWeek?: number; rcDayOfMonth?: number; rcMonthOfYear?: number
  rcIsActive: boolean; rcCreatedAt: string
}

type JoinedRow = TaskRow & PeriodRow & RcRow

const toTaskWithPeriod = (r: JoinedRow): TaskWithPeriod => ({
  id: r.id,
  userId: r.userId,
  title: r.title,
  description: r.description,
  level: r.level,
  scheduledTime: r.scheduledTime,
  recurringConfig: r.rcId
    ? { id: r.rcId, taskId: r.rcTaskId, dayOfWeek: r.rcDayOfWeek, dayOfMonth: r.rcDayOfMonth, isActive: r.rcIsActive, createdAt: r.rcCreatedAt }
    : undefined,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
  period: {
    id: r.pId,
    taskId: r.pTaskId,
    userId: r.pUserId,
    periodType: r.pPeriodType,
    periodStart: r.pPeriodStart,
    periodEnd: r.pPeriodEnd,
    status: r.pStatus,
    targetDate: r.pTargetDate,
    deadlineMonth: r.pDeadlineMonth,
    sortOrder: r.pSortOrder,
    doneAt: r.pDoneAt,
    backlogAt: r.pBacklogAt,
    archivedAt: r.pArchivedAt,
    createdAt: r.pCreatedAt,
    updatedAt: r.pUpdatedAt,
  },
})

const JOIN_SELECT = `
  SELECT
    t.id, t.user_id, t.title, t.description, t.level,
    t.scheduled_time, t.created_at, t.updated_at,
    tp.id          AS p_id,
    tp.task_id     AS p_task_id,
    tp.user_id     AS p_user_id,
    tp.period_type AS p_period_type,
    tp.period_start::text AS p_period_start,
    tp.period_end::text   AS p_period_end,
    tp.status      AS p_status,
    tp.target_date::text  AS p_target_date,
    tp.deadline_month     AS p_deadline_month,
    tp.sort_order  AS p_sort_order,
    tp.done_at     AS p_done_at,
    tp.backlog_at  AS p_backlog_at,
    tp.archived_at AS p_archived_at,
    tp.created_at  AS p_created_at,
    tp.updated_at  AS p_updated_at,
    rc.id          AS rc_id,
    rc.task_id     AS rc_task_id,
    rc.day_of_week AS rc_day_of_week,
    rc.day_of_month AS rc_day_of_month,
    rc.month_of_year AS rc_month_of_year,
    rc.is_active   AS rc_is_active,
    rc.created_at  AS rc_created_at
  FROM tasks t
  JOIN task_periods tp ON tp.task_id = t.id
  LEFT JOIN recurring_configs rc ON rc.task_id = t.id
`

export const taskRepository: ITaskRepository = {
  async listPeriods({ userId, periodType, periodStart, statuses }) {
    const statusList = statuses ?? ['todo', 'done', 'overdue']
    const rows = await db.unsafe<JoinedRow[]>(
      `${JOIN_SELECT}
       WHERE t.user_id = $1
         AND tp.period_type = $2
         AND tp.period_start = $3::date
         AND tp.status = ANY($4)
       ORDER BY tp.sort_order ASC, t.scheduled_time ASC NULLS LAST`,
      [userId, periodType, periodStart, statusList],
    )
    return rows.map(toTaskWithPeriod)
  },

  async listBacklog(userId) {
    const rows = await db.unsafe<JoinedRow[]>(
      `${JOIN_SELECT}
       WHERE t.user_id = $1 AND tp.status = 'backlog'
       ORDER BY tp.backlog_at ASC`,
      [userId],
    )
    return rows.map(toTaskWithPeriod)
  },

  async listArchive(userId, limit, offset) {
    const rows = await db.unsafe<JoinedRow[]>(
      `${JOIN_SELECT}
       WHERE t.user_id = $1 AND tp.status = 'archived'
       ORDER BY tp.archived_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset],
    )
    return rows.map(toTaskWithPeriod)
  },

  async findPeriodById(periodId, userId) {
    const [row] = await db.unsafe<JoinedRow[]>(
      `${JOIN_SELECT} WHERE tp.id = $1 AND t.user_id = $2`,
      [periodId, userId],
    )
    return row ? toTaskWithPeriod(row) : null
  },

  async createTask(input) {
    const task = await db.begin(async (sql) => {
      const [t] = await sql`
        INSERT INTO tasks (user_id, title, description, level, scheduled_time)
        VALUES (
          ${input.userId}, ${input.title}, ${input.description ?? null},
          ${input.level}, ${input.scheduledTime ?? null}
        )
        RETURNING id
      `

      if (input.recurringConfig) {
        const rc = input.recurringConfig
        await sql`
          INSERT INTO recurring_configs (task_id, day_of_week, day_of_month, is_active)
          VALUES (${t.id}, ${rc.dayOfWeek ?? null}, ${rc.dayOfMonth ?? null}, ${rc.isActive})
        `
      }

      const [period] = await sql`
        INSERT INTO task_periods (
          task_id, user_id, period_type, period_start, period_end,
          target_date, deadline_month
        ) VALUES (
          ${t.id}, ${input.userId}, ${input.level},
          ${input.periodStart}::date, ${input.periodEnd}::date,
          ${input.targetDate ?? null}, ${input.deadlineMonth ?? null}
        )
        RETURNING id
      `

      return { taskId: t.id, periodId: period.id }
    })

    const item = await this.findPeriodById(task.periodId, input.userId)
    return item!
  },

  async updateTask(taskId, userId, patch) {
    const entries = Object.entries(patch).filter(([, v]) => v !== undefined)
    if (entries.length === 0) return null

    const setCols = entries.map(([k], i) => `${toSnake(k)} = $${i + 3}`).join(', ')
    const values = [taskId, userId, ...entries.map(([, v]) => v)]

    const [row] = await db.unsafe(
      `UPDATE tasks SET ${setCols} WHERE id = $1 AND user_id = $2 RETURNING id`,
      values as string[],
    )
    if (!row) return null

    const [period] = await db<{ id: string }[]>`
      SELECT id FROM task_periods WHERE task_id = ${taskId} AND status != 'archived'
      ORDER BY created_at DESC LIMIT 1
    `
    if (!period) return null
    return this.findPeriodById(period.id, userId)
  },

  async updatePeriodStatus(periodId, userId, status, timestamps = {}) {
    const now = new Date().toISOString()
    const doneAt  = 'doneAt'  in timestamps ? timestamps.doneAt  : undefined
    const backlogAt = timestamps.backlogAt
    const archivedAt = timestamps.archivedAt

    const sets: string[] = ['status = $3']
    const vals: unknown[] = [periodId, userId, status]
    let idx = 4

    if (doneAt !== undefined) { sets.push(`done_at = $${idx++}`);    vals.push(doneAt) }
    if (backlogAt)            { sets.push(`backlog_at = $${idx++}`);  vals.push(backlogAt) }
    if (archivedAt)           { sets.push(`archived_at = $${idx++}`); vals.push(archivedAt) }

    const [row] = await db.unsafe<TaskPeriod[]>(
      `UPDATE task_periods SET ${sets.join(', ')}
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      vals as string[],
    )
    return row ?? null
  },

  async createPeriod({ taskId, userId, level, periodStart, periodEnd, targetDate, deadlineMonth }) {
    const [period] = await db`
      INSERT INTO task_periods (task_id, user_id, period_type, period_start, period_end, target_date, deadline_month)
      VALUES (
        ${taskId}, ${userId}, ${level},
        ${periodStart}::date, ${periodEnd}::date,
        ${targetDate ?? null}, ${deadlineMonth ?? null}
      )
      RETURNING id
    `
    const item = await this.findPeriodById(period.id, userId)
    return item!
  },

  async findBacklogPeriodByTaskId(taskId, userId) {
    const [row] = await db.unsafe<JoinedRow[]>(
      `${JOIN_SELECT} WHERE t.id = $1 AND t.user_id = $2 AND tp.status = 'backlog' LIMIT 1`,
      [taskId, userId],
    )
    return row ? toTaskWithPeriod(row) : null
  },

  async hasArchivedPeriods(taskId) {
    const [row] = await db`
      SELECT 1 FROM task_periods WHERE task_id = ${taskId} AND status = 'archived' LIMIT 1
    `
    return !!row
  },

  async deleteTask(taskId, userId) {
    const [row] = await db`
      DELETE FROM tasks WHERE id = ${taskId} AND user_id = ${userId} RETURNING id
    `
    return !!row
  },
}

const toSnake = (s: string) => s.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`)
