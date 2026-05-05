/**
 * Dev seed — rich task data covering all levels, statuses, and recurring configs.
 * Idempotent: clears and rebuilds on every run.
 *
 * Usage: pnpm --filter @locus/api db:seed
 * Credentials: dev@locus.dev / dev123456
 */
import { hash } from 'argon2'
import { db } from '../infrastructure/db/client.js'

// ─── Date helpers (UTC — matches browser toISOString().split('T')[0]) ────────

const pad = (n: number) => String(n).padStart(2, '0')
const toISO = (d: Date) => d.toISOString().split('T')[0]
const addDays = (d: Date, n: number) => { const r = new Date(d); r.setUTCDate(r.getUTCDate() + n); return r }

const monday = (d: Date) => {
  const r = new Date(d)
  const day = r.getUTCDay()
  r.setUTCDate(r.getUTCDate() + (day === 0 ? -6 : 1 - day))
  return r
}

const weekOf = (d: Date) => {
  const mon = monday(d)
  return { start: toISO(mon), end: toISO(addDays(mon, 6)) }
}

const lastDayOfMonth = (y: number, m: number) => new Date(y, m, 0).getDate()

// ─── Current anchors ──────────────────────────────────────────────────────────

const NOW = new Date()
const Y   = NOW.getUTCFullYear()
const M   = NOW.getUTCMonth() + 1

const TODAY      = toISO(NOW)
const THIS_WEEK  = weekOf(NOW)
const PREV_WEEK  = weekOf(addDays(NOW, -7))
const NEXT_WEEK  = weekOf(addDays(NOW, 7))

const MONTH_START = `${Y}-${pad(M)}-01`
const MONTH_END   = `${Y}-${pad(M)}-${lastDayOfMonth(Y, M)}`

const prevM = M === 1 ? 12 : M - 1
const prevY = M === 1 ? Y - 1 : Y
const PREV_MONTH_START = `${prevY}-${pad(prevM)}-01`
const PREV_MONTH_END   = `${prevY}-${pad(prevM)}-${lastDayOfMonth(prevY, prevM)}`

const YEAR_START = `${Y}-01-01`
const YEAR_END   = `${Y}-12-31`

// ─── Insert helpers ───────────────────────────────────────────────────────────

type Level  = 'day' | 'week' | 'month' | 'year'
type Status = 'todo' | 'done' | 'overdue' | 'backlog' | 'archived'

const insertTask = async (
  userId: string,
  title: string,
  level: Level,
  scheduledTime: string | null = null,
) => {
  const [row] = await db`
    INSERT INTO tasks (user_id, title, level, scheduled_time)
    VALUES (${userId}, ${title}, ${level}, ${scheduledTime})
    RETURNING id
  `
  return row.id as string
}

const insertRecurring = async (
  taskId: string,
  opts: { dayOfWeek?: number; dayOfMonth?: number; monthOfYear?: number } = {},
) => {
  await db`
    INSERT INTO recurring_configs (task_id, day_of_week, day_of_month, month_of_year, is_active)
    VALUES (
      ${taskId},
      ${opts.dayOfWeek   ?? null},
      ${opts.dayOfMonth  ?? null},
      ${opts.monthOfYear ?? null},
      true
    )
  `
}

const insertPeriod = async (
  taskId: string,
  userId: string,
  level: Level,
  start: string,
  end: string,
  status: Status,
  opts: {
    targetDate?:    string
    deadlineMonth?: number
    doneAt?:        string
    backlogAt?:     string
    archivedAt?:    string
  } = {},
) => {
  await db`
    INSERT INTO task_periods (
      task_id, user_id, period_type,
      period_start, period_end, status,
      target_date, deadline_month,
      done_at, backlog_at, archived_at
    ) VALUES (
      ${taskId}, ${userId}, ${level},
      ${start}::date, ${end}::date, ${status},
      ${opts.targetDate    ?? null},
      ${opts.deadlineMonth ?? null},
      ${opts.doneAt        ?? null},
      ${opts.backlogAt     ?? null},
      ${opts.archivedAt    ?? null}
    )
  `
}

// ─── Seed ─────────────────────────────────────────────────────────────────────

const seed = async () => {
  console.log('[seed] clearing data...')
  await db`DELETE FROM user_settings`
  await db`DELETE FROM recurring_configs`
  await db`DELETE FROM task_periods`
  await db`DELETE FROM tasks`
  await db`DELETE FROM users WHERE email = 'dev@locus.dev'`

  const passwordHash = await hash('dev123456')
  const [user] = await db`
    INSERT INTO users (email, name, password_hash, timezone)
    VALUES ('dev@locus.dev', 'Alex Dev', ${passwordHash}, 'Europe/Moscow')
    RETURNING id
  `
  await db`INSERT INTO user_settings (user_id) VALUES (${user.id})`
  const uid = user.id as string
  console.log('[seed] user:', uid)

  const now = new Date().toISOString()

  // ─── 1. Recurring daily habits ────────────────────────────────────────────
  // These appear every day — seeded for today and a few past/future days

  const habits: Array<{ title: string; time: string }> = [
    { title: 'Morning workout',   time: '07:00' },
    { title: 'Meditation',        time: '07:30' },
    { title: 'Plan the day',      time: '09:00' },
    { title: 'Evening review',    time: '21:00' },
    { title: 'Write in journal',  time: '22:00' },
  ]

  for (const habit of habits) {
    const tid = await insertTask(uid, habit.title, 'day', habit.time)
    await insertRecurring(tid)

    // Past 5 days — mostly done (archived), one missed (failure)
    for (let i = -5; i <= -1; i++) {
      const date = toISO(addDays(NOW, i))
      const failed = i === -3 && habit.title === 'Morning workout'
      await insertPeriod(tid, uid, 'day', date, date,
        'archived',
        { doneAt: failed ? undefined : now, archivedAt: now },
      )
    }

    // Today — 3 done, 2 todo
    const todayDone = ['Morning workout', 'Meditation', 'Plan the day'].includes(habit.title)
    await insertPeriod(tid, uid, 'day', TODAY, TODAY,
      todayDone ? 'done' : 'todo',
      { doneAt: todayDone ? now : undefined },
    )

    // Next 3 days — todo
    for (let i = 1; i <= 3; i++) {
      const date = toISO(addDays(NOW, i))
      await insertPeriod(tid, uid, 'day', date, date, 'todo')
    }
  }

  // ─── 2. Day tasks without time (per-day todos) ────────────────────────────

  const dayTodos: Array<{ title: string; offset: number; status: Status }> = [
    { title: 'Buy groceries',            offset:  0, status: 'todo'     },
    { title: 'Reply to emails',          offset:  0, status: 'done'     },
    { title: 'Read 30 pages',            offset:  0, status: 'todo'     },
    { title: 'Call parents',             offset:  1, status: 'todo'     },
    { title: 'Take medicine',            offset:  1, status: 'todo'     },
    { title: 'Dentist appointment prep', offset:  2, status: 'todo'     },
    { title: 'Pay utility bills',        offset: -1, status: 'archived' },
    { title: 'Pick up package',          offset: -1, status: 'archived' },
    { title: 'Submit timesheet',         offset: -2, status: 'archived' },
  ]

  for (const t of dayTodos) {
    const date = toISO(addDays(NOW, t.offset))
    const tid = await insertTask(uid, t.title, 'day', null)
    await insertPeriod(tid, uid, 'day', date, date, t.status, {
      doneAt: t.status === 'archived' ? now : undefined,
      archivedAt: t.status === 'archived' ? now : undefined,
    })
  }

  // ─── 3. Week tasks ────────────────────────────────────────────────────────

  // Two weeks ago — archived (success on time, success late, failure)
  const twoWeeksAgo = weekOf(addDays(NOW, -14))
  const twoWeekAgoTasks: Array<{ title: string; outcome: 'on-time' | 'late' | 'failed' }> = [
    { title: 'Finalize DB migrations',         outcome: 'on-time' },
    { title: 'Add API rate limiting',           outcome: 'late'    }, // done during overdue period
    { title: 'Remove deprecated endpoints',     outcome: 'failed'  },
  ]
  for (const t of twoWeekAgoTasks) {
    const tid = await insertTask(uid, t.title, 'week', null)
    const doneAt = t.outcome === 'failed' ? undefined
      : t.outcome === 'late'    ? toISO(addDays(new Date(twoWeeksAgo.end), 3)) + 'T12:00:00Z'
      : toISO(addDays(new Date(twoWeeksAgo.start), 2)) + 'T12:00:00Z'
    await insertPeriod(tid, uid, 'week', twoWeeksAgo.start, twoWeeksAgo.end, 'archived', {
      doneAt, archivedAt: now,
    })
  }

  // Previous week — archived (mixed outcomes) + one that went to backlog
  const prevWeekTasks: Array<{ title: string; outcome: 'on-time' | 'late' | 'failed' }> = [
    { title: 'Set up CI/CD pipeline',       outcome: 'on-time' },
    { title: 'Write unit tests for auth',   outcome: 'on-time' },
    { title: 'Performance audit',           outcome: 'failed'  },
    { title: 'Update onboarding docs',      outcome: 'late'    },
  ]
  for (const t of prevWeekTasks) {
    const tid = await insertTask(uid, t.title, 'week', null)
    const doneAt = t.outcome === 'failed' ? undefined
      : t.outcome === 'late' ? toISO(addDays(new Date(PREV_WEEK.end), 2)) + 'T18:00:00Z'
      : toISO(addDays(new Date(PREV_WEEK.start), 1)) + 'T15:00:00Z'
    await insertPeriod(tid, uid, 'week', PREV_WEEK.start, PREV_WEEK.end, 'archived', {
      targetDate: toISO(addDays(new Date(PREV_WEEK.start), 3)),
      doneAt, archivedAt: now,
    })
  }

  // Current week tasks
  const curWeekTasks: Array<{ title: string; status: Status; targetDay: number }> = [
    { title: 'Implement task API endpoints', status: 'done',    targetDay: 0 },
    { title: 'Design database schema',       status: 'done',    targetDay: 1 },
    { title: 'Frontend integration',         status: 'todo',    targetDay: 2 },
    { title: 'Write API documentation',      status: 'todo',    targetDay: 3 },
    { title: 'Code review session',          status: 'todo',    targetDay: 4 },
    { title: 'Deploy to staging',            status: 'overdue', targetDay: 0 },
  ]
  for (const t of curWeekTasks) {
    const tid = await insertTask(uid, t.title, 'week', null)
    await insertPeriod(tid, uid, 'week', THIS_WEEK.start, THIS_WEEK.end, t.status, {
      targetDate: toISO(addDays(new Date(THIS_WEEK.start), t.targetDay)),
      doneAt: t.status === 'done' ? now : undefined,
    })
  }

  // Next week tasks
  for (const title of ['Refactor task store', 'Add push notifications', 'Mobile MVP screen']) {
    const tid = await insertTask(uid, title, 'week', null)
    await insertPeriod(tid, uid, 'week', NEXT_WEEK.start, NEXT_WEEK.end, 'todo', {
      targetDate: toISO(addDays(new Date(NEXT_WEEK.start), 2)),
    })
  }

  // Recurring: weekly team sync (every Monday)
  const syncId = await insertTask(uid, 'Weekly team sync', 'week', '10:00')
  await insertRecurring(syncId, { dayOfWeek: 1 })
  await insertPeriod(syncId, uid, 'week', THIS_WEEK.start, THIS_WEEK.end, 'todo', {
    targetDate: THIS_WEEK.start,
  })

  // Recurring: weekly review (every Friday)
  const reviewId = await insertTask(uid, 'Weekly review & planning', 'week', '17:00')
  await insertRecurring(reviewId, { dayOfWeek: 5 })
  await insertPeriod(reviewId, uid, 'week', THIS_WEEK.start, THIS_WEEK.end, 'todo', {
    targetDate: toISO(addDays(new Date(THIS_WEEK.start), 4)),
  })

  // ─── Week backlog (tasks that missed overdue window) ──────────────────────

  const weekBacklog: Array<{ title: string; weeksAgo: number }> = [
    { title: 'Migrate old data to new schema',    weeksAgo: 2 },
    { title: 'Security headers audit',            weeksAgo: 3 },
    { title: 'Remove unused feature flags',       weeksAgo: 1 },
  ]
  for (const t of weekBacklog) {
    const w = weekOf(addDays(NOW, -t.weeksAgo * 7))
    const tid = await insertTask(uid, t.title, 'week', null)
    await insertPeriod(tid, uid, 'week', w.start, w.end, 'backlog', { backlogAt: now })
  }

  // ─── 4. Month tasks ───────────────────────────────────────────────────────

  // 3 months ago — archived
  const threeMonthsAgoStart = (() => {
    const d = new Date(NOW); d.setUTCMonth(d.getUTCMonth() - 3); d.setUTCDate(1); return toISO(d)
  })()
  const threeMonthsAgoEnd = (() => {
    const d = new Date(NOW); d.setUTCMonth(d.getUTCMonth() - 2); d.setUTCDate(0); return toISO(d)
  })()
  for (const [title, done] of [
    ['Q1 OKR review', true], ['Renew domain subscriptions', true],
    ['Archive old project repos', false],
  ] as [string, boolean][]) {
    const tid = await insertTask(uid, title, 'month', null)
    await insertPeriod(tid, uid, 'month', threeMonthsAgoStart, threeMonthsAgoEnd, 'archived', {
      doneAt: done ? threeMonthsAgoEnd + 'T18:00:00Z' : undefined,
      archivedAt: now,
    })
  }

  // Previous month — archived (on-time, late, failed)
  const prevMonthArchive: Array<{ title: string; outcome: 'on-time' | 'late' | 'failed' }> = [
    { title: 'Read "Clean Architecture"',   outcome: 'on-time' },
    { title: 'Complete online SQL course',  outcome: 'late'    },
    { title: 'Audit project dependencies',  outcome: 'failed'  },
    { title: 'Update team wiki',            outcome: 'on-time' },
  ]
  for (const t of prevMonthArchive) {
    const tid = await insertTask(uid, t.title, 'month', null)
    const doneAt = t.outcome === 'failed' ? undefined
      : t.outcome === 'late' ? MONTH_START + 'T10:00:00Z'  // done in next month = late
      : PREV_MONTH_END + 'T20:00:00Z'
    await insertPeriod(tid, uid, 'month', PREV_MONTH_START, PREV_MONTH_END, 'archived', {
      doneAt, archivedAt: now,
    })
  }

  // Current month tasks
  for (const title of [
    'Read 2 professional books',
    'Learn 50 new English words',
    'Close all backlog tasks',
    'Prepare quarterly report',
  ]) {
    const tid = await insertTask(uid, title, 'month', null)
    await insertPeriod(tid, uid, 'month', MONTH_START, MONTH_END, 'todo')
  }

  // Recurring: monthly finances review (1st of month)
  const finId = await insertTask(uid, 'Monthly finances review', 'month', null)
  await insertRecurring(finId, { dayOfMonth: 1 })
  await insertPeriod(finId, uid, 'month', MONTH_START, MONTH_END, 'todo')

  // Recurring: gym subscription renewal (15th of month)
  const gymId = await insertTask(uid, 'Gym subscription renewal', 'month', null)
  await insertRecurring(gymId, { dayOfMonth: 15 })
  await insertPeriod(gymId, uid, 'month', MONTH_START, MONTH_END, 'todo')

  // Quarterly: car service (Q2 = June, Q4 = December)
  const carServiceId = await insertTask(uid, 'Car technical service (Q2)', 'month', null)
  await insertRecurring(carServiceId, { monthOfYear: 6 })
  await insertPeriod(carServiceId, uid, 'month', MONTH_START, MONTH_END, 'todo')

  const carServiceQ4Id = await insertTask(uid, 'Car technical service (Q4)', 'month', null)
  await insertRecurring(carServiceQ4Id, { monthOfYear: 12 })
  await insertPeriod(carServiceQ4Id, uid, 'month', MONTH_START, MONTH_END, 'todo')

  // ─── Month backlog ────────────────────────────────────────────────────────

  const monthBacklog: Array<{ title: string; monthsAgo: number }> = [
    { title: 'Set up monitoring & alerts',    monthsAgo: 1 },
    { title: 'Negotiate new hosting plan',    monthsAgo: 2 },
    { title: 'Document API versioning policy', monthsAgo: 3 },
  ]
  for (const t of monthBacklog) {
    const start = (() => {
      const d = new Date(NOW); d.setUTCMonth(d.getUTCMonth() - t.monthsAgo); d.setUTCDate(1); return toISO(d)
    })()
    const end = (() => {
      const d = new Date(NOW); d.setUTCMonth(d.getUTCMonth() - t.monthsAgo + 1); d.setUTCDate(0); return toISO(d)
    })()
    const tid = await insertTask(uid, t.title, 'month', null)
    await insertPeriod(tid, uid, 'month', start, end, 'backlog', { backlogAt: now })
  }

  // ─── 5. Year tasks ────────────────────────────────────────────────────────

  // Previous year — archived
  const prevYearStart = `${Y - 1}-01-01`
  const prevYearEnd   = `${Y - 1}-12-31`
  const prevYearTasks: Array<{ title: string; outcome: 'on-time' | 'late' | 'failed' }> = [
    { title: 'Ship mobile app MVP',              outcome: 'on-time' },
    { title: 'Learn Rust basics',                outcome: 'failed'  },
    { title: 'Complete leadership course',       outcome: 'late'    },
    { title: 'Build emergency savings fund',     outcome: 'on-time' },
  ]
  for (const t of prevYearTasks) {
    const tid = await insertTask(uid, t.title, 'year', null)
    const doneAt = t.outcome === 'failed' ? undefined
      : t.outcome === 'late' ? `${Y}-02-15T12:00:00Z`
      : `${Y - 1}-11-20T12:00:00Z`
    await insertPeriod(tid, uid, 'year', prevYearStart, prevYearEnd, 'archived', {
      doneAt, archivedAt: now,
    })
  }

  // Current year goals
  const yearTasks: Array<{ title: string; deadlineMonth: number }> = [
    { title: 'Pass AWS Solutions Architect cert',  deadlineMonth: 6  },
    { title: 'Run a half-marathon',                deadlineMonth: 9  },
    { title: 'Launch side project MVP',            deadlineMonth: 12 },
    { title: 'Read 24 books this year',            deadlineMonth: 12 },
    { title: 'Save 3-month emergency fund',        deadlineMonth: 10 },
  ]
  for (const t of yearTasks) {
    const tid = await insertTask(uid, t.title, 'year', null)
    await insertPeriod(tid, uid, 'year', YEAR_START, YEAR_END, 'todo', {
      deadlineMonth: t.deadlineMonth,
    })
  }

  // Recurring: annual performance review (every December)
  const annualId = await insertTask(uid, 'Annual performance self-review', 'year', null)
  await insertRecurring(annualId)
  await insertPeriod(annualId, uid, 'year', YEAR_START, YEAR_END, 'todo', { deadlineMonth: 12 })

  // ─── Year backlog ─────────────────────────────────────────────────────────

  const yearBacklogId1 = await insertTask(uid, 'Publish technical blog', 'year', null)
  await insertPeriod(yearBacklogId1, uid, 'year', prevYearStart, prevYearEnd, 'backlog', { backlogAt: now })

  const yearBacklogId2 = await insertTask(uid, 'Get driving license', 'year', null)
  await insertPeriod(yearBacklogId2, uid, 'year', `${Y - 2}-01-01`, `${Y - 2}-12-31`, 'backlog', { backlogAt: now })

  console.log('[seed] done ✓')
  console.log('  login: dev@locus.dev / dev123456')
  await db.end()
}

seed().catch((e) => {
  console.error('[seed] error', e)
  process.exit(1)
})
