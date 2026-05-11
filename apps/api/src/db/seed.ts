/**
 * TEST SEED — each task name describes its full lifecycle with exact dates.
 * Run on: auto-computed from NOW at seed time.
 *
 * Scheduler transitions (what this seed tests):
 *   DAY  todo/done  → archived   when period_end < today
 *   WEEK todo       → overdue    when period_end < today
 *   WEEK overdue    → backlog    when period_end + 7d < today
 *   WEEK done       → archived   when period_end < today
 *   MONTH todo      → overdue    when period_end < today
 *   MONTH overdue   → backlog    when period_end + 1mo < today
 *   YEAR todo       → overdue    when period_end < today
 *   YEAR overdue    → backlog    when period_end + 1yr < today
 *   RECURRING       → archived   at period_end (no overdue), new period auto-created
 *
 * Usage: pnpm --filter @locus/api db:seed
 * Login: dev@locus.dev / dev123456
 */
import { hash } from 'argon2'
import { db } from '../infrastructure/db/client.js'

// ─── Helpers ─────────────────────────────────────────────────────────────────

const pad    = (n: number) => String(n).padStart(2, '0')
const toISO  = (d: Date)   => d.toISOString().split('T')[0]

const addDays = (iso: string, n: number) => {
  const d = new Date(iso + 'T00:00:00Z')
  d.setUTCDate(d.getUTCDate() + n)
  return toISO(d)
}
const addMonths = (iso: string, n: number) => {
  const d = new Date(iso + 'T00:00:00Z')
  d.setUTCMonth(d.getUTCMonth() + n)
  return toISO(d)
}
const addYears = (iso: string, n: number) => {
  const d = new Date(iso + 'T00:00:00Z')
  d.setUTCFullYear(d.getUTCFullYear() + n)
  return toISO(d)
}

const monday = (iso: string) => {
  const d = new Date(iso + 'T00:00:00Z')
  const dow = d.getUTCDay()
  d.setUTCDate(d.getUTCDate() + (dow === 0 ? -6 : 1 - dow))
  return toISO(d)
}
const monthStart = (iso: string) => {
  const d = new Date(iso + 'T00:00:00Z')
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-01`
}
const monthEnd = (iso: string) => {
  const d = new Date(iso + 'T00:00:00Z')
  return toISO(new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)))
}
const yearStart = (iso: string) => `${iso.slice(0, 4)}-01-01`
const yearEnd   = (iso: string) => `${iso.slice(0, 4)}-12-31`

// Short display date: "10.05.26"
const dd = (iso: string) => {
  const [y, m, d] = iso.split('-')
  return `${d}.${m}.${y.slice(2)}`
}

// ─── Anchors from NOW ─────────────────────────────────────────────────────────

const NOW = new Date()
const TODAY = toISO(NOW)

// Week anchors
const W0_MON = monday(TODAY)                    // this week Mon
const W0_SUN = addDays(W0_MON, 6)              // this week Sun
const W_1_MON = addDays(W0_MON, -7)            // prev week Mon
const W_1_SUN = addDays(W_1_MON, 6)            // prev week Sun
const W_2_MON = addDays(W0_MON, -14)           // 2 weeks ago Mon
const W_2_SUN = addDays(W_2_MON, 6)            // 2 weeks ago Sun
const W_3_MON = addDays(W0_MON, -21)           // 3 weeks ago
const W_3_SUN = addDays(W_3_MON, 6)
const W1_MON  = addDays(W0_MON, 7)             // next week Mon
const W1_SUN  = addDays(W1_MON, 6)             // next week Sun

// Month anchors
const M0_S = monthStart(TODAY)                  // this month start
const M0_E = monthEnd(TODAY)                    // this month end
const M_1_S = monthStart(addMonths(TODAY, -1))  // prev month start
const M_1_E = monthEnd(addMonths(TODAY, -1))    // prev month end
const M_2_S = monthStart(addMonths(TODAY, -2))
const M_2_E = monthEnd(addMonths(TODAY, -2))
const M_3_S = monthStart(addMonths(TODAY, -3))
const M_3_E = monthEnd(addMonths(TODAY, -3))

// Year anchors
const Y0_S = yearStart(TODAY)                   // this year start
const Y0_E = yearEnd(TODAY)                     // this year end
const Y_1_S = yearStart(addYears(TODAY, -1))    // last year
const Y_1_E = yearEnd(addYears(TODAY, -1))
const Y_2_S = yearStart(addYears(TODAY, -2))
const Y_2_E = yearEnd(addYears(TODAY, -2))

// Transition dates (when scheduler will move each status)
// WEEK: todo→overdue when period_end < today  → day after W0_SUN
// WEEK: overdue→backlog when period_end + 7d < today → W0_SUN + 8 days
const W0_OVERDUE_AT  = addDays(W0_SUN, 1)       // day after this week ends
const W0_BACKLOG_AT  = addDays(W0_SUN, 8)       // week overdue expires
const W_1_BACKLOG_AT = addDays(W_1_SUN, 8)      // prev week overdue expires

// MONTH
const M0_OVERDUE_AT = addDays(M0_E, 1)
const M0_BACKLOG_AT = addDays(monthEnd(addMonths(M0_E, 1)), 1) // M0_E + 1 month + 1 day
const M_1_BACKLOG_AT = addDays(monthEnd(addMonths(M_1_E, 1)), 1)

// YEAR
const Y0_OVERDUE_AT = addDays(Y0_E, 1)          // 01.01 next year
const Y0_BACKLOG_AT = addYears(Y0_OVERDUE_AT, 1) // 01.01 year after next

// ─── DB helpers ───────────────────────────────────────────────────────────────

type Level  = 'day' | 'week' | 'month' | 'year'
type Status = 'todo' | 'done' | 'overdue' | 'backlog' | 'archived'

const insertTask = async (userId: string, title: string, level: Level, scheduledTime: string | null = null) => {
  const [row] = await db`
    INSERT INTO tasks (user_id, title, level, scheduled_time)
    VALUES (${userId}, ${title}, ${level}, ${scheduledTime})
    RETURNING id
  `
  return row.id as string
}

const insertRecurring = async (taskId: string, opts: { daysOfWeek?: number[]; dayOfMonth?: number } = {}) => {
  await db`
    INSERT INTO recurring_configs (task_id, days_of_week, day_of_month, is_active)
    VALUES (${taskId}, ${opts.daysOfWeek ?? null}, ${opts.dayOfMonth ?? null}, true)
  `
}

const insertPeriod = async (
  taskId: string, userId: string, level: Level,
  start: string, end: string, status: Status,
  opts: { targetDate?: string; doneAt?: string; backlogAt?: string; archivedAt?: string } = {},
) => {
  await db`
    INSERT INTO task_periods (
      task_id, user_id, period_type, period_start, period_end, status,
      target_date, done_at, backlog_at, archived_at
    ) VALUES (
      ${taskId}, ${userId}, ${level}, ${start}::date, ${end}::date, ${status},
      ${opts.targetDate ?? null},
      ${opts.doneAt    ?? null},
      ${opts.backlogAt ?? null},
      ${opts.archivedAt ?? null}
    )
  `
}

// ─── Seed ─────────────────────────────────────────────────────────────────────

const seed = async () => {
  console.log('[seed] clearing...')
  await db`DELETE FROM user_settings`
  await db`DELETE FROM recurring_configs`
  await db`DELETE FROM task_periods`
  await db`DELETE FROM tasks`
  await db`DELETE FROM users WHERE email = 'dev@locus.dev'`

  const [user] = await db`
    INSERT INTO users (email, name, password_hash, timezone)
    VALUES ('dev@locus.dev', 'Test Dev', ${await hash('dev123456')}, 'UTC')
    RETURNING id
  `
  await db`INSERT INTO user_settings (user_id) VALUES (${user.id})`
  const uid = user.id as string

  const now = NOW.toISOString()

  console.log(`[seed] TODAY=${TODAY}  W0=${W0_MON}–${W0_SUN}  M0=${M0_S}–${M0_E}  Y0=${Y0_S}–${Y0_E}`)

  // ────────────────────────────────────────────────────────────────────────────
  // DAY TASKS
  // Transition: todo/done → archived when period_end < today (next day)
  // ────────────────────────────────────────────────────────────────────────────

  // Today — will archive tomorrow
  let id = await insertTask(uid, `DAY ✓ done ${dd(TODAY)} → archived ${dd(addDays(TODAY, 1))}`, 'day')
  await insertPeriod(id, uid, 'day', TODAY, TODAY, 'done', { doneAt: now })

  id = await insertTask(uid, `DAY ○ todo ${dd(TODAY)} → archived(fail) ${dd(addDays(TODAY, 1))}`, 'day')
  await insertPeriod(id, uid, 'day', TODAY, TODAY, 'todo')

  // Tomorrow — still safe
  const TMR = addDays(TODAY, 1)
  id = await insertTask(uid, `DAY ○ todo ${dd(TMR)} → archived(?) ${dd(addDays(TMR, 1))}`, 'day')
  await insertPeriod(id, uid, 'day', TMR, TMR, 'todo')

  // Yesterday — already archived by scheduler
  const YST = addDays(TODAY, -1)
  id = await insertTask(uid, `DAY archived ✓ done ${dd(YST)}`, 'day')
  await insertPeriod(id, uid, 'day', YST, YST, 'archived', { doneAt: YST + 'T18:00:00Z', archivedAt: now })

  id = await insertTask(uid, `DAY archived ✗ missed ${dd(YST)}`, 'day')
  await insertPeriod(id, uid, 'day', YST, YST, 'archived', { archivedAt: now })

  const D2 = addDays(TODAY, -2)
  id = await insertTask(uid, `DAY archived ✓ late — done ${dd(TODAY)} (period ${dd(D2)})`, 'day')
  await insertPeriod(id, uid, 'day', D2, D2, 'archived', { doneAt: TODAY + 'T10:00:00Z', archivedAt: now })

  // Recurring day habit (runs every day, auto-creates period)
  id = await insertTask(uid, `DAY recurring ↻ daily habit — period ${dd(TODAY)}, next auto-created daily`, 'day', '07:00')
  await insertRecurring(id)
  await insertPeriod(id, uid, 'day', TODAY, TODAY, 'todo')
  // Yesterday archived
  await insertPeriod(id, uid, 'day', YST, YST, 'archived', { doneAt: YST + 'T07:30:00Z', archivedAt: now })

  // Recurring Mon+Wed+Fri
  id = await insertTask(uid, `DAY recurring ↻ Mon+Wed+Fri — only runs on those days`, 'day', '09:00')
  await insertRecurring(id, { daysOfWeek: [1, 3, 5] })
  await insertPeriod(id, uid, 'day', TODAY, TODAY, 'todo')

  // ────────────────────────────────────────────────────────────────────────────
  // WEEK TASKS
  // todo  → overdue at ${W0_OVERDUE_AT} (day after period ends)
  // overdue → backlog at ${W0_BACKLOG_AT} (period_end + 7d + 1)
  // done  → archived at ${W0_OVERDUE_AT}
  // ────────────────────────────────────────────────────────────────────────────

  // Current week — will transition when scheduler runs after ${W0_SUN}
  id = await insertTask(uid, `WEEK ✓ done ${dd(W0_MON)}–${dd(W0_SUN)} → archived ${dd(W0_OVERDUE_AT)}`, 'week')
  await insertPeriod(id, uid, 'week', W0_MON, W0_SUN, 'done', { doneAt: now })

  id = await insertTask(uid, `WEEK ○ todo ${dd(W0_MON)}–${dd(W0_SUN)} → overdue ${dd(W0_OVERDUE_AT)} → backlog ${dd(W0_BACKLOG_AT)}`, 'week')
  await insertPeriod(id, uid, 'week', W0_MON, W0_SUN, 'todo')

  // Next week — far future
  id = await insertTask(uid, `WEEK ○ todo ${dd(W1_MON)}–${dd(W1_SUN)} → overdue ${dd(addDays(W1_SUN, 1))} → backlog ${dd(addDays(W1_SUN, 8))}`, 'week')
  await insertPeriod(id, uid, 'week', W1_MON, W1_SUN, 'todo')

  // Prev week — currently overdue, goes to backlog at ${W_1_BACKLOG_AT}
  id = await insertTask(uid, `WEEK ⚠ overdue (missed ${dd(W_1_MON)}–${dd(W_1_SUN)}) → backlog ${dd(W_1_BACKLOG_AT)}`, 'week')
  await insertPeriod(id, uid, 'week', W_1_MON, W_1_SUN, 'overdue')

  // 2 weeks ago — in backlog (overdue expired)
  id = await insertTask(uid, `WEEK backlog (missed ${dd(W_2_MON)}–${dd(W_2_SUN)}, overdue expired ${dd(addDays(W_2_SUN, 8))})`, 'week')
  await insertPeriod(id, uid, 'week', W_2_MON, W_2_SUN, 'backlog', { backlogAt: addDays(W_2_SUN, 8) + 'T00:00:00Z' })

  // 3 weeks ago — archived outcomes
  id = await insertTask(uid, `WEEK archived ✓ ontime (period ${dd(W_3_MON)}–${dd(W_3_SUN)}, done ${dd(addDays(W_3_MON, 2))})`, 'week')
  await insertPeriod(id, uid, 'week', W_3_MON, W_3_SUN, 'archived', {
    doneAt: addDays(W_3_MON, 2) + 'T14:00:00Z', archivedAt: now,
  })

  id = await insertTask(uid, `WEEK archived ✓ late (period ${dd(W_3_MON)}–${dd(W_3_SUN)}, done ${dd(addDays(W_3_SUN, 4))})`, 'week')
  await insertPeriod(id, uid, 'week', W_3_MON, W_3_SUN, 'archived', {
    doneAt: addDays(W_3_SUN, 4) + 'T10:00:00Z', archivedAt: now,
  })

  id = await insertTask(uid, `WEEK archived ✗ failed (period ${dd(W_3_MON)}–${dd(W_3_SUN)}, never done)`, 'week')
  await insertPeriod(id, uid, 'week', W_3_MON, W_3_SUN, 'archived', { archivedAt: now })

  // Recurring week — Mon+Thu standup (no overdue, auto-archives + creates new)
  id = await insertTask(uid, `WEEK recurring ↻ Mon+Thu standup — archived ${dd(W0_OVERDUE_AT)}, new ${dd(W1_MON)}–${dd(W1_SUN)} auto`, 'week', '10:00')
  await insertRecurring(id, { daysOfWeek: [1, 4] })
  await insertPeriod(id, uid, 'week', W0_MON, W0_SUN, 'todo', { targetDate: W0_MON })

  // ────────────────────────────────────────────────────────────────────────────
  // MONTH TASKS
  // todo  → overdue at ${M0_OVERDUE_AT}
  // overdue → backlog at ${M0_BACKLOG_AT}
  // done  → archived at ${M0_OVERDUE_AT}
  // ────────────────────────────────────────────────────────────────────────────

  id = await insertTask(uid, `MONTH ✓ done ${dd(M0_S)}–${dd(M0_E)} → archived ${dd(M0_OVERDUE_AT)}`, 'month')
  await insertPeriod(id, uid, 'month', M0_S, M0_E, 'done', { doneAt: now })

  id = await insertTask(uid, `MONTH ○ todo ${dd(M0_S)}–${dd(M0_E)} → overdue ${dd(M0_OVERDUE_AT)} → backlog ${dd(M0_BACKLOG_AT)}`, 'month')
  await insertPeriod(id, uid, 'month', M0_S, M0_E, 'todo')

  id = await insertTask(uid, `MONTH ⚠ overdue (missed ${dd(M_1_S)}–${dd(M_1_E)}) → backlog ${dd(M_1_BACKLOG_AT)}`, 'month')
  await insertPeriod(id, uid, 'month', M_1_S, M_1_E, 'overdue')

  id = await insertTask(uid, `MONTH backlog (missed ${dd(M_2_S)}–${dd(M_2_E)}, overdue expired)`, 'month')
  await insertPeriod(id, uid, 'month', M_2_S, M_2_E, 'backlog', { backlogAt: now })

  id = await insertTask(uid, `MONTH archived ✓ ontime (${dd(M_3_S)}–${dd(M_3_E)}, done ${dd(addDays(M_3_E, -5))})`, 'month')
  await insertPeriod(id, uid, 'month', M_3_S, M_3_E, 'archived', {
    doneAt: addDays(M_3_E, -5) + 'T12:00:00Z', archivedAt: now,
  })

  id = await insertTask(uid, `MONTH archived ✓ late (${dd(M_3_S)}–${dd(M_3_E)}, done ${dd(addDays(M_3_E, 10))})`, 'month')
  await insertPeriod(id, uid, 'month', M_3_S, M_3_E, 'archived', {
    doneAt: addDays(M_3_E, 10) + 'T09:00:00Z', archivedAt: now,
  })

  id = await insertTask(uid, `MONTH archived ✗ failed (${dd(M_3_S)}–${dd(M_3_E)}, never done)`, 'month')
  await insertPeriod(id, uid, 'month', M_3_S, M_3_E, 'archived', { archivedAt: now })

  // Recurring month — 1st of month
  id = await insertTask(uid, `MONTH recurring ↻ 1st of month — archived ${dd(M0_OVERDUE_AT)}, new ${dd(addMonths(M0_S, 1))} auto`, 'month')
  await insertRecurring(id, { dayOfMonth: 1 })
  await insertPeriod(id, uid, 'month', M0_S, M0_E, 'todo')

  // ────────────────────────────────────────────────────────────────────────────
  // YEAR TASKS
  // todo  → overdue at ${Y0_OVERDUE_AT}
  // overdue → backlog at ${Y0_BACKLOG_AT}
  // done  → archived at ${Y0_OVERDUE_AT}
  // ────────────────────────────────────────────────────────────────────────────

  id = await insertTask(uid, `YEAR ✓ done ${dd(Y0_S)}–${dd(Y0_E)} → archived ${dd(Y0_OVERDUE_AT)}`, 'year')
  await insertPeriod(id, uid, 'year', Y0_S, Y0_E, 'done', { doneAt: now })

  id = await insertTask(uid, `YEAR ○ todo ${dd(Y0_S)}–${dd(Y0_E)} → overdue ${dd(Y0_OVERDUE_AT)} → backlog ${dd(Y0_BACKLOG_AT)}`, 'year')
  await insertPeriod(id, uid, 'year', Y0_S, Y0_E, 'todo')

  id = await insertTask(uid, `YEAR ⚠ overdue (missed ${dd(Y_1_S)}–${dd(Y_1_E)}) → backlog ${dd(addDays(Y_1_E, 1))} +1yr`, 'year')
  await insertPeriod(id, uid, 'year', Y_1_S, Y_1_E, 'overdue')

  id = await insertTask(uid, `YEAR backlog (missed ${dd(Y_2_S)}–${dd(Y_2_E)}, overdue expired)`, 'year')
  await insertPeriod(id, uid, 'year', Y_2_S, Y_2_E, 'backlog', { backlogAt: now })

  id = await insertTask(uid, `YEAR archived ✓ ontime (${Y_1_S.slice(0, 4)}, done ${dd(addDays(Y_1_E, -30))})`, 'year')
  await insertPeriod(id, uid, 'year', Y_1_S, Y_1_E, 'archived', {
    doneAt: addDays(Y_1_E, -30) + 'T12:00:00Z', archivedAt: now,
  })

  id = await insertTask(uid, `YEAR archived ✓ late (${Y_1_S.slice(0, 4)}, done ${dd(addDays(Y0_S, 45))})`, 'year')
  await insertPeriod(id, uid, 'year', Y_1_S, Y_1_E, 'archived', {
    doneAt: addDays(Y0_S, 45) + 'T12:00:00Z', archivedAt: now,
  })

  id = await insertTask(uid, `YEAR archived ✗ failed (${Y_2_S.slice(0, 4)}, never done)`, 'year')
  await insertPeriod(id, uid, 'year', Y_2_S, Y_2_E, 'archived', { archivedAt: now })

  // ────────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ────────────────────────────────────────────────────────────────────────────

  console.log('\n[seed] done ✓')
  console.log('  login: dev@locus.dev / dev123456\n')
  console.log('  KEY DATES TO TEST WITH DEV TIME WIDGET:')
  console.log(`  ${addDays(TODAY, 1).replace(/-/g, '.')}  → day tasks archived`)
  console.log(`  ${W0_OVERDUE_AT.replace(/-/g, '.')}  → week done→archived, week todo→overdue`)
  console.log(`  ${W0_BACKLOG_AT.replace(/-/g, '.')}  → week overdue→backlog`)
  console.log(`  ${W_1_BACKLOG_AT.replace(/-/g, '.')}  → prev week overdue→backlog`)
  console.log(`  ${M0_OVERDUE_AT.replace(/-/g, '.')}  → month done→archived, month todo→overdue`)
  console.log(`  ${M0_BACKLOG_AT.replace(/-/g, '.')}  → month overdue→backlog`)
  console.log(`  ${Y0_OVERDUE_AT.replace(/-/g, '.')}  → year done→archived, year todo→overdue`)
  console.log(`  ${Y0_BACKLOG_AT.replace(/-/g, '.')}  → year overdue→backlog`)

  await db.end()
}

seed().catch((e) => { console.error('[seed] error', e); process.exit(1) })
