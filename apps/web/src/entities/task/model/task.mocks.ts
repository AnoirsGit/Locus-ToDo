import type { TaskWithPeriod } from './task.types'

const TODAY = '2026-05-03'
const MON   = '2026-04-27'
const TUE   = '2026-04-28'
const WED   = '2026-04-29'
const THU   = '2026-04-30'
const FRI   = '2026-05-01'
const SAT   = '2026-05-02'
// SUN = TODAY
const WEEK_START = '2026-04-28'
const WEEK_END = '2026-05-04'
const MONTH_START = '2026-05-01'
const MONTH_END = '2026-05-31'
const YEAR_START = '2026-01-01'
const YEAR_END = '2026-12-31'

export const MOCK_TASKS: TaskWithPeriod[] = [
  // ── Day — Пн 27 апр ─────────────────────────────────────────────
  {
    id: 't-d-mon-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: MON, updatedAt: MON,
    recurringConfig: { id: 'rc-d1', taskId: 't-d-mon-1', isActive: true, createdAt: MON },
    period: {
      id: 'p-d-mon-1', taskId: 't-d-mon-1', userId: 'u1',
      periodType: 'day', periodStart: MON, periodEnd: MON,
      status: 'done', sortOrder: 0, doneAt: `${MON}T07:15:00Z`,
      createdAt: MON, updatedAt: MON,
    },
  },
  {
    id: 't-d-mon-2', userId: 'u1', title: 'Разбор почты',
    level: 'day', createdAt: MON, updatedAt: MON,
    period: {
      id: 'p-d-mon-2', taskId: 't-d-mon-2', userId: 'u1',
      periodType: 'day', periodStart: MON, periodEnd: MON,
      status: 'done', sortOrder: 1, doneAt: `${MON}T09:30:00Z`,
      createdAt: MON, updatedAt: MON,
    },
  },
  {
    id: 't-d-mon-3', userId: 'u1', title: 'Спортзал',
    level: 'day', createdAt: MON, updatedAt: MON,
    recurringConfig: { id: 'rc-d2', taskId: 't-d-mon-3', isActive: true, createdAt: MON },
    period: {
      id: 'p-d-mon-3', taskId: 't-d-mon-3', userId: 'u1',
      periodType: 'day', periodStart: MON, periodEnd: MON,
      status: 'done', sortOrder: 2, doneAt: `${MON}T18:00:00Z`,
      createdAt: MON, updatedAt: MON,
    },
  },

  // ── Day — Вт 28 апр ─────────────────────────────────────────────
  {
    id: 't-d-tue-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: TUE, updatedAt: TUE,
    recurringConfig: { id: 'rc-d3', taskId: 't-d-tue-1', isActive: true, createdAt: TUE },
    period: {
      id: 'p-d-tue-1', taskId: 't-d-tue-1', userId: 'u1',
      periodType: 'day', periodStart: TUE, periodEnd: TUE,
      status: 'done', sortOrder: 0, doneAt: `${TUE}T07:10:00Z`,
      createdAt: TUE, updatedAt: TUE,
    },
  },
  {
    id: 't-d-tue-2', userId: 'u1', title: 'Прочитать 20 страниц',
    level: 'day', createdAt: TUE, updatedAt: TUE,
    recurringConfig: { id: 'rc-d4', taskId: 't-d-tue-2', isActive: true, createdAt: TUE },
    period: {
      id: 'p-d-tue-2', taskId: 't-d-tue-2', userId: 'u1',
      periodType: 'day', periodStart: TUE, periodEnd: TUE,
      status: 'done', sortOrder: 1, doneAt: `${TUE}T22:00:00Z`,
      createdAt: TUE, updatedAt: TUE,
    },
  },

  // ── Day — Ср 29 апр ─────────────────────────────────────────────
  {
    id: 't-d-wed-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: WED, updatedAt: WED,
    recurringConfig: { id: 'rc-d5', taskId: 't-d-wed-1', isActive: true, createdAt: WED },
    period: {
      id: 'p-d-wed-1', taskId: 't-d-wed-1', userId: 'u1',
      periodType: 'day', periodStart: WED, periodEnd: WED,
      status: 'done', sortOrder: 0, doneAt: `${WED}T07:05:00Z`,
      createdAt: WED, updatedAt: WED,
    },
  },
  {
    id: 't-d-wed-2', userId: 'u1', title: 'Созвон с командой',
    level: 'day', createdAt: WED, updatedAt: WED,
    period: {
      id: 'p-d-wed-2', taskId: 't-d-wed-2', userId: 'u1',
      periodType: 'day', periodStart: WED, periodEnd: WED,
      status: 'done', sortOrder: 1, doneAt: `${WED}T11:00:00Z`,
      createdAt: WED, updatedAt: WED,
    },
  },
  {
    id: 't-d-wed-3', userId: 'u1', title: 'Прочитать 20 страниц',
    level: 'day', createdAt: WED, updatedAt: WED,
    recurringConfig: { id: 'rc-d6', taskId: 't-d-wed-3', isActive: true, createdAt: WED },
    period: {
      id: 'p-d-wed-3', taskId: 't-d-wed-3', userId: 'u1',
      periodType: 'day', periodStart: WED, periodEnd: WED,
      status: 'todo', sortOrder: 2,
      createdAt: WED, updatedAt: WED,
    },
  },

  // ── Day — Чт 30 апр ─────────────────────────────────────────────
  {
    id: 't-d-thu-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: THU, updatedAt: THU,
    recurringConfig: { id: 'rc-d7', taskId: 't-d-thu-1', isActive: true, createdAt: THU },
    period: {
      id: 'p-d-thu-1', taskId: 't-d-thu-1', userId: 'u1',
      periodType: 'day', periodStart: THU, periodEnd: THU,
      status: 'done', sortOrder: 0, doneAt: `${THU}T07:20:00Z`,
      createdAt: THU, updatedAt: THU,
    },
  },
  {
    id: 't-d-thu-2', userId: 'u1', title: 'Спортзал',
    level: 'day', createdAt: THU, updatedAt: THU,
    recurringConfig: { id: 'rc-d8', taskId: 't-d-thu-2', isActive: true, createdAt: THU },
    period: {
      id: 'p-d-thu-2', taskId: 't-d-thu-2', userId: 'u1',
      periodType: 'day', periodStart: THU, periodEnd: THU,
      status: 'todo', sortOrder: 1,
      createdAt: THU, updatedAt: THU,
    },
  },

  // ── Day — Пт 1 мая ──────────────────────────────────────────────
  {
    id: 't-d-fri-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: FRI, updatedAt: FRI,
    recurringConfig: { id: 'rc-d9', taskId: 't-d-fri-1', isActive: true, createdAt: FRI },
    period: {
      id: 'p-d-fri-1', taskId: 't-d-fri-1', userId: 'u1',
      periodType: 'day', periodStart: FRI, periodEnd: FRI,
      status: 'done', sortOrder: 0, doneAt: `${FRI}T07:00:00Z`,
      createdAt: FRI, updatedAt: FRI,
    },
  },
  {
    id: 't-d-fri-2', userId: 'u1', title: 'Ретроспектива недели',
    level: 'day', createdAt: FRI, updatedAt: FRI,
    period: {
      id: 'p-d-fri-2', taskId: 't-d-fri-2', userId: 'u1',
      periodType: 'day', periodStart: FRI, periodEnd: FRI,
      status: 'done', sortOrder: 1, doneAt: `${FRI}T17:30:00Z`,
      createdAt: FRI, updatedAt: FRI,
    },
  },
  {
    id: 't-d-fri-3', userId: 'u1', title: 'Прочитать 20 страниц',
    level: 'day', createdAt: FRI, updatedAt: FRI,
    recurringConfig: { id: 'rc-d10', taskId: 't-d-fri-3', isActive: true, createdAt: FRI },
    period: {
      id: 'p-d-fri-3', taskId: 't-d-fri-3', userId: 'u1',
      periodType: 'day', periodStart: FRI, periodEnd: FRI,
      status: 'todo', sortOrder: 2,
      createdAt: FRI, updatedAt: FRI,
    },
  },

  // ── Day — Сб 2 мая ──────────────────────────────────────────────
  {
    id: 't-d-sat-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: SAT, updatedAt: SAT,
    recurringConfig: { id: 'rc-d11', taskId: 't-d-sat-1', isActive: true, createdAt: SAT },
    period: {
      id: 'p-d-sat-1', taskId: 't-d-sat-1', userId: 'u1',
      periodType: 'day', periodStart: SAT, periodEnd: SAT,
      status: 'done', sortOrder: 0, doneAt: `${SAT}T09:00:00Z`,
      createdAt: SAT, updatedAt: SAT,
    },
  },
  {
    id: 't-d-sat-2', userId: 'u1', title: 'Длинная пробежка',
    level: 'day', createdAt: SAT, updatedAt: SAT,
    period: {
      id: 'p-d-sat-2', taskId: 't-d-sat-2', userId: 'u1',
      periodType: 'day', periodStart: SAT, periodEnd: SAT,
      status: 'done', sortOrder: 1, doneAt: `${SAT}T10:30:00Z`,
      createdAt: SAT, updatedAt: SAT,
    },
  },

  // ── Day — Вс 3 мая (today) ──────────────────────────────────────
  {
    id: 't-d-sun-1', userId: 'u1', title: 'Медитация',
    level: 'day', createdAt: TODAY, updatedAt: TODAY,
    recurringConfig: { id: 'rc-d12', taskId: 't-d-sun-1', isActive: true, createdAt: TODAY },
    period: {
      id: 'p-d-sun-1', taskId: 't-d-sun-1', userId: 'u1',
      periodType: 'day', periodStart: TODAY, periodEnd: TODAY,
      status: 'todo', sortOrder: 0,
      createdAt: TODAY, updatedAt: TODAY,
    },
  },
  {
    id: 't-d-sun-2', userId: 'u1', title: 'Прочитать 20 страниц',
    level: 'day', createdAt: TODAY, updatedAt: TODAY,
    recurringConfig: { id: 'rc-d13', taskId: 't-d-sun-2', isActive: true, createdAt: TODAY },
    period: {
      id: 'p-d-sun-2', taskId: 't-d-sun-2', userId: 'u1',
      periodType: 'day', periodStart: TODAY, periodEnd: TODAY,
      status: 'done', sortOrder: 1, doneAt: `${TODAY}T08:30:00Z`,
      createdAt: TODAY, updatedAt: TODAY,
    },
  },
  {
    id: 't-d-sun-3', userId: 'u1', title: 'Позвонить маме',
    level: 'day', createdAt: TODAY, updatedAt: TODAY,
    period: {
      id: 'p-d-sun-3', taskId: 't-d-sun-3', userId: 'u1',
      periodType: 'day', periodStart: TODAY, periodEnd: TODAY,
      status: 'todo', sortOrder: 2,
      createdAt: TODAY, updatedAt: TODAY,
    },
  },

  // ── Week — todo ─────────────────────────────────────────────────
  {
    id: 't-w1', userId: 'u1',
    title: 'Написать план на неделю',
    level: 'week', createdAt: WEEK_START, updatedAt: WEEK_START,
    period: {
      id: 'p-w1', taskId: 't-w1', userId: 'u1',
      periodType: 'week', periodStart: WEEK_START, periodEnd: WEEK_END,
      status: 'todo', sortOrder: 0, targetDate: '2026-04-28',
      createdAt: WEEK_START, updatedAt: WEEK_START,
    },
  },
  // ── Week — done ─────────────────────────────────────────────────
  {
    id: 't-w2', userId: 'u1',
    title: 'Проверить email и ответить на письма',
    level: 'week', createdAt: WEEK_START, updatedAt: WEEK_START,
    period: {
      id: 'p-w2', taskId: 't-w2', userId: 'u1',
      periodType: 'week', periodStart: WEEK_START, periodEnd: WEEK_END,
      status: 'done', sortOrder: 1, doneAt: '2026-04-29T10:00:00Z',
      createdAt: WEEK_START, updatedAt: WEEK_START,
    },
  },
  // ── Week — overdue (штрафной период) ────────────────────────────
  {
    id: 't-w3', userId: 'u1',
    title: 'Подготовить презентацию для команды',
    level: 'week', createdAt: '2026-04-21', updatedAt: '2026-04-21',
    period: {
      id: 'p-w3', taskId: 't-w3', userId: 'u1',
      periodType: 'week', periodStart: '2026-04-21', periodEnd: '2026-04-27',
      status: 'overdue', sortOrder: 2,
      createdAt: '2026-04-21', updatedAt: '2026-04-28',
    },
  },
  // ── Week — todo + recurring ──────────────────────────────────────
  {
    id: 't-w4', userId: 'u1',
    title: 'Утренняя зарядка',
    level: 'week', createdAt: WEEK_START, updatedAt: WEEK_START,
    recurringConfig: {
      id: 'rc-1', taskId: 't-w4', dayOfWeek: 1, isActive: true,
      createdAt: WEEK_START,
    },
    period: {
      id: 'p-w4', taskId: 't-w4', userId: 'u1',
      periodType: 'week', periodStart: WEEK_START, periodEnd: WEEK_END,
      status: 'todo', sortOrder: 3,
      createdAt: WEEK_START, updatedAt: WEEK_START,
    },
  },

  // ── Month — todo ─────────────────────────────────────────────────
  {
    id: 't-m1', userId: 'u1',
    title: 'Прочитать «Атомные привычки»',
    level: 'month', createdAt: MONTH_START, updatedAt: MONTH_START,
    period: {
      id: 'p-m1', taskId: 't-m1', userId: 'u1',
      periodType: 'month', periodStart: MONTH_START, periodEnd: MONTH_END,
      status: 'todo', sortOrder: 0,
      createdAt: MONTH_START, updatedAt: MONTH_START,
    },
  },
  // ── Month — done ─────────────────────────────────────────────────
  {
    id: 't-m2', userId: 'u1',
    title: 'Пройти курс по TypeScript',
    level: 'month', createdAt: MONTH_START, updatedAt: MONTH_START,
    period: {
      id: 'p-m2', taskId: 't-m2', userId: 'u1',
      periodType: 'month', periodStart: MONTH_START, periodEnd: MONTH_END,
      status: 'done', sortOrder: 1, doneAt: '2026-05-02T14:00:00Z',
      createdAt: MONTH_START, updatedAt: MONTH_START,
    },
  },
  // ── Month — overdue ──────────────────────────────────────────────
  {
    id: 't-m3', userId: 'u1',
    title: 'Обновить резюме',
    level: 'month', createdAt: '2026-04-01', updatedAt: '2026-04-01',
    period: {
      id: 'p-m3', taskId: 't-m3', userId: 'u1',
      periodType: 'month', periodStart: '2026-04-01', periodEnd: '2026-04-30',
      status: 'overdue', sortOrder: 2,
      createdAt: '2026-04-01', updatedAt: '2026-05-01',
    },
  },

  // ── Year — todo + deadlineMonth ──────────────────────────────────
  {
    id: 't-y1', userId: 'u1',
    title: 'Запустить пет-проект',
    level: 'year', createdAt: YEAR_START, updatedAt: YEAR_START,
    period: {
      id: 'p-y1', taskId: 't-y1', userId: 'u1',
      periodType: 'year', periodStart: YEAR_START, periodEnd: YEAR_END,
      status: 'todo', sortOrder: 0, deadlineMonth: 6,
      createdAt: YEAR_START, updatedAt: YEAR_START,
    },
  },
  // ── Year — todo ──────────────────────────────────────────────────
  {
    id: 't-y2', userId: 'u1',
    title: 'Пробежать полумарафон',
    level: 'year', createdAt: YEAR_START, updatedAt: YEAR_START,
    period: {
      id: 'p-y2', taskId: 't-y2', userId: 'u1',
      periodType: 'year', periodStart: YEAR_START, periodEnd: YEAR_END,
      status: 'todo', sortOrder: 1,
      createdAt: YEAR_START, updatedAt: YEAR_START,
    },
  },
  // ── Year — done ──────────────────────────────────────────────────
  {
    id: 't-y3', userId: 'u1',
    title: 'Накопить на MacBook',
    level: 'year', createdAt: YEAR_START, updatedAt: YEAR_START,
    period: {
      id: 'p-y3', taskId: 't-y3', userId: 'u1',
      periodType: 'year', periodStart: YEAR_START, periodEnd: YEAR_END,
      status: 'done', sortOrder: 2, doneAt: '2026-03-15T09:00:00Z',
      createdAt: YEAR_START, updatedAt: YEAR_START,
    },
  },

  // ── Backlog — week ───────────────────────────────────────────────
  {
    id: 't-b1', userId: 'u1',
    title: 'Починить велосипед',
    level: 'week', createdAt: '2026-04-14', updatedAt: '2026-04-28',
    period: {
      id: 'p-b1', taskId: 't-b1', userId: 'u1',
      periodType: 'week', periodStart: '2026-04-14', periodEnd: '2026-04-20',
      status: 'backlog', sortOrder: 0, backlogAt: '2026-04-28T00:00:00Z',
      createdAt: '2026-04-14', updatedAt: '2026-04-28',
    },
  },
  // ── Backlog — month ──────────────────────────────────────────────
  {
    id: 't-b2', userId: 'u1',
    title: 'Разобрать старые документы',
    level: 'month', createdAt: '2026-03-01', updatedAt: '2026-05-01',
    period: {
      id: 'p-b2', taskId: 't-b2', userId: 'u1',
      periodType: 'month', periodStart: '2026-03-01', periodEnd: '2026-03-31',
      status: 'backlog', sortOrder: 1, backlogAt: '2026-05-01T00:00:00Z',
      createdAt: '2026-03-01', updatedAt: '2026-05-01',
    },
  },
  // ── Backlog — year ───────────────────────────────────────────────
  {
    id: 't-b3', userId: 'u1',
    title: 'Написать статью в блог',
    level: 'year', createdAt: '2025-01-01', updatedAt: '2026-01-01',
    period: {
      id: 'p-b3', taskId: 't-b3', userId: 'u1',
      periodType: 'year', periodStart: '2025-01-01', periodEnd: '2025-12-31',
      status: 'backlog', sortOrder: 2, backlogAt: '2026-01-01T00:00:00Z',
      createdAt: '2025-01-01', updatedAt: '2026-01-01',
    },
  },

  // ── Archive — успех (вовремя) ────────────────────────────────────
  {
    id: 't-a1', userId: 'u1',
    title: 'Оплатить коммунальные услуги',
    level: 'week', createdAt: '2026-04-14', updatedAt: '2026-04-20',
    period: {
      id: 'p-a1', taskId: 't-a1', userId: 'u1',
      periodType: 'week', periodStart: '2026-04-14', periodEnd: '2026-04-20',
      status: 'archived', sortOrder: 0,
      doneAt: '2026-04-16T11:00:00Z', archivedAt: '2026-04-20T23:59:00Z',
      createdAt: '2026-04-14', updatedAt: '2026-04-20',
    },
  },
  // ── Archive — успех с просрочкой ─────────────────────────────────
  {
    id: 't-a2', userId: 'u1',
    title: 'Закрыть задолженность по онлайн-курсу',
    level: 'week', createdAt: '2026-04-14', updatedAt: '2026-04-27',
    period: {
      id: 'p-a2', taskId: 't-a2', userId: 'u1',
      periodType: 'week', periodStart: '2026-04-14', periodEnd: '2026-04-20',
      status: 'archived', sortOrder: 1,
      doneAt: '2026-04-22T15:00:00Z', archivedAt: '2026-04-27T23:59:00Z',
      createdAt: '2026-04-14', updatedAt: '2026-04-27',
    },
  },
  // ── Archive — провал (done_at null) ──────────────────────────────
  {
    id: 't-a3', userId: 'u1',
    title: 'Выучить испанский за год',
    level: 'year', createdAt: '2025-01-01', updatedAt: '2026-01-01',
    period: {
      id: 'p-a3', taskId: 't-a3', userId: 'u1',
      periodType: 'year', periodStart: '2025-01-01', periodEnd: '2025-12-31',
      status: 'archived', sortOrder: 3,
      archivedAt: '2026-01-01T00:00:00Z',
      createdAt: '2025-01-01', updatedAt: '2026-01-01',
    },
  },
]
