/**
 * Dev seed — creates a test user and populates mock tasks matching the frontend mocks.
 * Idempotent: skips if user already exists.
 *
 * Usage: pnpm --filter @locus/api db:seed
 * Credentials: dev@locus.dev / dev123456
 */
import { hash } from 'argon2'
import { db } from '../infrastructure/db/client.js'

// ─── Date helpers ─────────────────────────────────────────────────────────────

const pad = (n: number) => String(n).padStart(2, '0')

const toISO = (d: Date) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`

const addDays = (d: Date, n: number) => {
  const r = new Date(d)
  r.setDate(r.getDate() + n)
  return r
}

const monday = (d: Date) => {
  const r = new Date(d)
  const day = r.getDay()
  const diff = day === 0 ? -6 : 1 - day
  r.setDate(r.getDate() + diff)
  return r
}

const lastDayOfMonth = (year: number, month: number) =>
  new Date(year, month, 0).getDate()

// ─── Computed dates ──────────────────────────────────────────────────────────

const now = new Date()
const TODAY     = toISO(now)
const MON       = toISO(monday(now))
const TUE       = toISO(addDays(monday(now), 1))
const WED       = toISO(addDays(monday(now), 2))
const THU       = toISO(addDays(monday(now), 3))
const FRI       = toISO(addDays(monday(now), 4))
const SAT       = toISO(addDays(monday(now), 5))
const SUN       = toISO(addDays(monday(now), 6))

const WEEK_END  = SUN

const MONTH_START = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-01`
const MONTH_END   = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${lastDayOfMonth(now.getFullYear(), now.getMonth() + 1)}`
const YEAR_START  = `${now.getFullYear()}-01-01`
const YEAR_END    = `${now.getFullYear()}-12-31`

// ─── Helpers to insert tasks ─────────────────────────────────────────────────

const createTask = async (
  userId: string,
  title: string,
  level: 'day' | 'week' | 'month' | 'year',
  scheduledTime: string | null,
  isRecurring: boolean,
) => {
  const [task] = await db`
    INSERT INTO tasks (user_id, title, level, scheduled_time)
    VALUES (${userId}, ${title}, ${level}, ${scheduledTime})
    RETURNING id
  `
  if (isRecurring) {
    await db`INSERT INTO recurring_configs (task_id, is_active) VALUES (${task.id}, true)`
  }
  return task.id as string
}

const createPeriod = async (
  taskId: string,
  userId: string,
  level: 'day' | 'week' | 'month' | 'year',
  periodStart: string,
  periodEnd: string,
  status: 'todo' | 'done' | 'overdue' | 'backlog' | 'archived',
  opts: { targetDate?: string; deadlineMonth?: number; doneAt?: string } = {},
) => {
  await db`
    INSERT INTO task_periods (
      task_id, user_id, period_type, period_start, period_end,
      status, target_date, deadline_month, done_at
    ) VALUES (
      ${taskId}, ${userId}, ${level},
      ${periodStart}::date, ${periodEnd}::date,
      ${status},
      ${opts.targetDate ?? null},
      ${opts.deadlineMonth ?? null},
      ${opts.doneAt ?? null}
    )
  `
}

// ─── Seed ─────────────────────────────────────────────────────────────────────

const seed = async () => {
  // Check if user already exists
  const [existing] = await db`SELECT id FROM users WHERE email = 'dev@locus.dev'`
  if (existing) {
    console.log('[seed] user already exists, skipping')
    await db.end()
    return
  }

  const passwordHash = await hash('dev123456')
  const [user] = await db`
    INSERT INTO users (email, name, password_hash, timezone)
    VALUES ('dev@locus.dev', 'Dev User', ${passwordHash}, 'Europe/Moscow')
    RETURNING id
  `
  await db`INSERT INTO user_settings (user_id) VALUES (${user.id})`
  const uid = user.id as string

  console.log('[seed] user created:', uid)

  const doneAt = new Date().toISOString()

  // ── Day tasks — TODAY ──────────────────────────────────────────────────────

  const d1 = await createTask(uid, 'Медитация',            'day', '07:00', true)
  const d2 = await createTask(uid, 'Зарядка',              'day', '07:30', true)
  const d3 = await createTask(uid, 'Планирование дня',     'day', '09:00', false)
  const d4 = await createTask(uid, 'Прочитать 20 страниц', 'day', '21:00', true)
  const d5 = await createTask(uid, 'Разбор почты',         'day', null,    false)

  await createPeriod(d1, uid, 'day', TODAY, TODAY, 'done', { doneAt })
  await createPeriod(d2, uid, 'day', TODAY, TODAY, 'todo')
  await createPeriod(d3, uid, 'day', TODAY, TODAY, 'todo')
  await createPeriod(d4, uid, 'day', TODAY, TODAY, 'todo')
  await createPeriod(d5, uid, 'day', TODAY, TODAY, 'todo')

  // ── Day tasks — past days of this week ─────────────────────────────────────

  const dMon1 = await createTask(uid, 'Медитация',            'day', '07:00', false)
  const dMon2 = await createTask(uid, 'Созвон с командой',    'day', '10:00', false)
  const dMon3 = await createTask(uid, 'Планирование недели',  'day', '09:00', false)
  await createPeriod(dMon1, uid, 'day', MON, MON, 'archived', { doneAt })
  await createPeriod(dMon2, uid, 'day', MON, MON, 'archived', { doneAt })
  await createPeriod(dMon3, uid, 'day', MON, MON, 'archived', { doneAt })

  const dTue1 = await createTask(uid, 'Медитация',         'day', '07:00', false)
  const dTue2 = await createTask(uid, 'Зарядка',           'day', '07:30', false)
  const dTue3 = await createTask(uid, 'Позвонить маме',    'day', null,    false)
  await createPeriod(dTue1, uid, 'day', TUE, TUE, 'archived', { doneAt })
  await createPeriod(dTue2, uid, 'day', TUE, TUE, 'archived', { doneAt })
  await createPeriod(dTue3, uid, 'day', TUE, TUE, 'archived')

  const dWed1 = await createTask(uid, 'Медитация',               'day', '07:00', false)
  const dWed2 = await createTask(uid, 'Спортзал',                'day', '18:30', false)
  const dWed3 = await createTask(uid, 'Прочитать 20 страниц',   'day', '21:00', false)
  await createPeriod(dWed1, uid, 'day', WED, WED, 'archived', { doneAt })
  await createPeriod(dWed2, uid, 'day', WED, WED, 'archived', { doneAt })
  await createPeriod(dWed3, uid, 'day', WED, WED, 'archived', { doneAt })

  const dThu1 = await createTask(uid, 'Медитация',     'day', '07:00', false)
  const dThu2 = await createTask(uid, 'Ретроспектива', 'day', '17:00', false)
  const dThu3 = await createTask(uid, 'Зарядка',       'day', '07:30', false)
  await createPeriod(dThu1, uid, 'day', THU, THU, 'archived', { doneAt })
  await createPeriod(dThu2, uid, 'day', THU, THU, 'archived', { doneAt })
  await createPeriod(dThu3, uid, 'day', THU, THU, 'archived')

  const dFri1 = await createTask(uid, 'Медитация',           'day', '07:00', false)
  const dFri2 = await createTask(uid, 'Разбор почты',        'day', null,    false)
  const dFri3 = await createTask(uid, 'Еженедельный отчёт',  'day', '16:00', false)
  await createPeriod(dFri1, uid, 'day', FRI, FRI, 'archived', { doneAt })
  await createPeriod(dFri2, uid, 'day', FRI, FRI, 'archived', { doneAt })
  await createPeriod(dFri3, uid, 'day', FRI, FRI, 'archived')

  const dSat1 = await createTask(uid, 'Длинная пробежка', 'day', '09:00', false)
  const dSat2 = await createTask(uid, 'Читать книгу',     'day', '20:00', false)
  await createPeriod(dSat1, uid, 'day', SAT, SAT, 'archived', { doneAt })
  await createPeriod(dSat2, uid, 'day', SAT, SAT, 'archived', { doneAt })

  const dSun1 = await createTask(uid, 'Медитация',           'day', '08:00', false)
  const dSun2 = await createTask(uid, 'Планирование недели', 'day', '19:00', false)
  await createPeriod(dSun1, uid, 'day', SUN, SUN, 'archived', { doneAt })
  await createPeriod(dSun2, uid, 'day', SUN, SUN, 'archived', { doneAt })

  // ── Week tasks ─────────────────────────────────────────────────────────────

  const w1 = await createTask(uid, 'Завершить MVP-форму задач', 'week', null, false)
  const w2 = await createTask(uid, 'Написать тесты на store',   'week', null, false)
  const w3 = await createTask(uid, 'Код-ревью PR коллеги',      'week', null, false)
  await createPeriod(w1, uid, 'week', MON, WEEK_END, 'todo', { targetDate: TODAY })
  await createPeriod(w2, uid, 'week', MON, WEEK_END, 'todo')
  await createPeriod(w3, uid, 'week', MON, WEEK_END, 'done', { targetDate: WED, doneAt })

  // ── Month tasks ────────────────────────────────────────────────────────────

  const m1 = await createTask(uid, 'Запустить прод-деплой',       'month', null, false)
  const m2 = await createTask(uid, 'Обновить документацию API',   'month', null, false)
  const m3 = await createTask(uid, 'Провести 1-on-1 с командой',  'month', null, false)
  await createPeriod(m1, uid, 'month', MONTH_START, MONTH_END, 'todo')
  await createPeriod(m2, uid, 'month', MONTH_START, MONTH_END, 'todo')
  await createPeriod(m3, uid, 'month', MONTH_START, MONTH_END, 'done', { doneAt })

  // ── Year tasks ─────────────────────────────────────────────────────────────

  const y1 = await createTask(uid, 'Выпустить мобильное приложение', 'year', null, false)
  const y2 = await createTask(uid, 'Прочитать 24 книги',             'year', null, false)
  await createPeriod(y1, uid, 'year', YEAR_START, YEAR_END, 'todo', { deadlineMonth: 9 })
  await createPeriod(y2, uid, 'year', YEAR_START, YEAR_END, 'todo')

  console.log('[seed] done — dev@locus.dev / dev123456')
  await db.end()
}

seed().catch((e) => {
  console.error('[seed] error', e)
  process.exit(1)
})