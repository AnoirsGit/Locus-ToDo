import type { TaskWithPeriod } from './task.types'

const TODAY = '2026-05-04'
const MON   = '2026-04-27'
const TUE   = '2026-04-28'
const WED   = '2026-04-29'
const THU   = '2026-04-30'
const FRI   = '2026-05-01'
const SAT   = '2026-05-02'
const SUN   = '2026-05-03'

const now = new Date().toISOString()

const mk = (
  id: string,
  title: string,
  level: TaskWithPeriod['level'],
  status: TaskWithPeriod['period']['status'],
  periodStart: string,
  extra: Partial<TaskWithPeriod> & { targetDate?: string; scheduledTime?: string } = {},
): TaskWithPeriod => ({
  id,
  userId: 'u1',
  title,
  level,
  scheduledTime: extra.scheduledTime,
  description: extra.description,
  recurringConfig: extra.recurringConfig,
  createdAt: now,
  updatedAt: now,
  period: {
    id: `p-${id}`,
    taskId: id,
    userId: 'u1',
    periodType: level,
    periodStart,
    periodEnd: periodStart,
    status,
    targetDate: extra.targetDate,
    sortOrder: 0,
    doneAt: status === 'done' ? now : undefined,
    createdAt: now,
    updatedAt: now,
  },
})

export const MOCK_TASKS: TaskWithPeriod[] = [
  // ── Day tasks ─────────────────────────────────────────────
  mk('d1', 'Медитация',           'day', 'done', TODAY, { scheduledTime: '07:00', recurringConfig: { id: 'rc-d1', taskId: 'd1', isActive: true, createdAt: now } }),
  mk('d2', 'Зарядка',             'day', 'todo', TODAY, { scheduledTime: '07:30', recurringConfig: { id: 'rc-d2', taskId: 'd2', isActive: true, createdAt: now } }),
  mk('d3', 'Планирование дня',    'day', 'todo', TODAY, { scheduledTime: '09:00' }),
  mk('d4', 'Прочитать 20 страниц','day', 'todo', TODAY, { scheduledTime: '21:00', recurringConfig: { id: 'rc-d4', taskId: 'd4', isActive: true, createdAt: now } }),
  mk('d5', 'Разбор почты',        'day', 'todo', TODAY),

  // ── Past days (this week) ─────────────────────────────────
  mk('d-mon1', 'Медитация',        'day', 'done', MON, { scheduledTime: '07:00' }),
  mk('d-mon2', 'Созвон с командой','day', 'done', MON, { scheduledTime: '10:00' }),
  mk('d-mon3', 'Планирование недели','day','done',MON, { scheduledTime: '09:00' }),

  mk('d-tue1', 'Медитация',        'day', 'done', TUE, { scheduledTime: '07:00' }),
  mk('d-tue2', 'Зарядка',          'day', 'done', TUE, { scheduledTime: '07:30' }),
  mk('d-tue3', 'Позвонить маме',   'day', 'todo', TUE),

  mk('d-wed1', 'Медитация',        'day', 'done', WED, { scheduledTime: '07:00' }),
  mk('d-wed2', 'Спортзал',         'day', 'done', WED, { scheduledTime: '18:30' }),
  mk('d-wed3', 'Прочитать 20 страниц','day','done',WED,{ scheduledTime: '21:00' }),

  mk('d-thu1', 'Медитация',        'day', 'done', THU, { scheduledTime: '07:00' }),
  mk('d-thu2', 'Ретроспектива',    'day', 'done', THU, { scheduledTime: '17:00' }),
  mk('d-thu3', 'Зарядка',          'day', 'todo', THU, { scheduledTime: '07:30' }),

  mk('d-fri1', 'Медитация',        'day', 'done', FRI, { scheduledTime: '07:00' }),
  mk('d-fri2', 'Разбор почты',     'day', 'done', FRI),
  mk('d-fri3', 'Еженедельный отчёт','day','todo', FRI, { scheduledTime: '16:00' }),

  mk('d-sat1', 'Длинная пробежка', 'day', 'done', SAT, { scheduledTime: '09:00' }),
  mk('d-sat2', 'Читать книгу',     'day', 'done', SAT, { scheduledTime: '20:00' }),

  mk('d-sun1', 'Медитация',        'day', 'done', SUN, { scheduledTime: '08:00' }),
  mk('d-sun2', 'Планирование недели','day','done',SUN, { scheduledTime: '19:00' }),

  // ── Week tasks ────────────────────────────────────────────
  mk('w1', 'Завершить MVP-форму задач', 'week', 'todo', MON, { targetDate: TODAY }),
  mk('w2', 'Написать тесты на store',   'week', 'todo', MON),
  mk('w3', 'Код-ревью PR коллеги',      'week', 'done', MON, { targetDate: WED }),

  // ── Month tasks ───────────────────────────────────────────
  mk('m1', 'Запустить прод-деплой',     'month', 'todo', '2026-05-01'),
  mk('m2', 'Обновить документацию API', 'month', 'todo', '2026-05-01'),
  mk('m3', 'Провести 1-on-1 с командой','month', 'done', '2026-05-01'),

  // ── Year tasks ────────────────────────────────────────────
  mk('y1', 'Выпустить мобильное приложение', 'year', 'todo', '2026-01-01', { period: { deadlineMonth: 9 } } as any),
  mk('y2', 'Прочитать 24 книги',             'year', 'todo', '2026-01-01'),
]
