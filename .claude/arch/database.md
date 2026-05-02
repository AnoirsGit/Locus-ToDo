# arch/database.md

> Load when: DB schema, migrations, queries, indexes, table relations.

## Status: DRAFT -- not confirmed

---

## Tables

### `users`
```
id            UUID PK  DEFAULT gen_random_uuid()
email         TEXT     UNIQUE NOT NULL
name          TEXT     NOT NULL
password_hash TEXT     NOT NULL
avatar_url    TEXT
timezone      TEXT     NOT NULL DEFAULT 'UTC'   -- IANA tz, e.g. 'Europe/Moscow'
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
```

---

### `tasks`
```
id            UUID PK  DEFAULT gen_random_uuid()
user_id       UUID FK -> users.id  ON DELETE CASCADE
title         TEXT NOT NULL
description   TEXT
level         TEXT NOT NULL CHECK ('week' | 'month' | 'year')
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()  -- trigger
```

---

### `recurring_configs`
> Presence of a row = task is recurring. No row = one-off task.
> Level is inherited from `tasks.level` (no duplication).

```
id            UUID PK  DEFAULT gen_random_uuid()
task_id       UUID FK -> tasks.id  ON DELETE CASCADE  UNIQUE
day_of_week   SMALLINT CHECK (0-6)   -- week-level: 0=Sun ... 6=Sat. NULL = any day
day_of_month  SMALLINT CHECK (1-31)  -- month-level: NULL = 1st
month_of_year SMALLINT CHECK (1-12)  -- month-level: если задано, задача генерируется только в этот месяц (не каждый месяц). NULL = каждый месяц
is_active     BOOLEAN DEFAULT true
allow_overdue BOOLEAN DEFAULT false  -- future: allow penalty period for recurring tasks
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
```

> `allow_overdue = false` (default): пропущенный период сразу `archived` (failure), новый `todo` на следующий цикл — регулярная задача не накапливает долги.  
> `allow_overdue = true` (future): применяется штрафной период, как у обычных задач.  
> **Текущий MVP:** поле зарезервировано, всегда `false`. Логика штрафного периода для recurring не реализуется.

---

### `task_periods`
> One record = one appearance of a task in one time period.
> This is the task list. Query by period_start to get the weekly/monthly/yearly list.

```
id              UUID PK  DEFAULT gen_random_uuid()
task_id         UUID FK -> tasks.id  ON DELETE CASCADE
user_id         UUID FK -> users.id  (denormalized for fast queries)

period_type     TEXT NOT NULL CHECK ('week' | 'month' | 'year')
period_start    DATE NOT NULL   -- Mon of week / 1st of month / Jan 1st
period_end      DATE NOT NULL   -- Sun / last day of month / Dec 31st

status          TEXT NOT NULL DEFAULT 'todo'
                     CHECK ('todo' | 'done' | 'overdue' | 'backlog' | 'archived')

target_date     DATE            -- week-tasks only: planned day within the week (nullable)
deadline_month  SMALLINT CHECK (1-12)  -- year-tasks only: month by which task should be done

sort_order      INTEGER NOT NULL DEFAULT 0

done_at         TIMESTAMPTZ
backlog_at      TIMESTAMPTZ
archived_at     TIMESTAMPTZ

created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()  -- trigger

UNIQUE (task_id, period_start) WHERE status != 'archived'
-- partial unique index: allows archived + active period on same date
-- enables replan back to the same period
```

**Denormalization note:** `period_type` must always match `tasks.level` for the same task.
This is enforced at the application layer, not by a DB constraint.
It exists to avoid joining `tasks` on every list query (same rationale as `user_id`).

---

## Relations

```
users --< tasks                (1:N, CASCADE DELETE)
tasks --< recurring_configs    (1:1, CASCADE DELETE)
tasks --< task_periods         (1:N, CASCADE DELETE)
users --< task_periods         (denormalized FK, no CASCADE)
```

---

## Task Lifecycle

```
todo <-> done                       (check / uncheck — user toggles freely)
todo --> overdue                    (period ended, task not done — scheduler: first period)
done --> archived (done_at set)     (period ended, task was done — scheduler)
overdue --> done                    (user completes during penalty period)
overdue --> backlog                 (penalty period ended, task not done — scheduler: second period)
backlog --> todo                    (replanned to a new period — old period archived)
backlog --> archived (no done_at)   (user gave up)
```

### Штрафной период (overdue — второй шанс)

Когда первый период заканчивается без выполнения, задача переходит в `overdue` вместо прямого попадания в `backlog`.
- Задача остаётся видимой в текущем виде (Дня/Недели/Месяца) с маркером **"Долг с прошлого периода"**
- Пользователь может выполнить задачу: `overdue → done → archived` (выполнено с просрочкой, `done_at > period_end`)
- По окончании штрафного периода невыполненные `overdue` → `backlog`

**Длительность штрафного периода = длительность базового уровня задачи:**

| Уровень задачи | Штрафной период        | Пример                                         |
|----------------|------------------------|------------------------------------------------|
| `week`         | 1 неделя               | Не сделал в марте (нед. 4) → штраф до конца апреля (нед. 1) |
| `month`        | 1 месяц (весь месяц)   | Не сделал в марте → штраф весь апрель          |
| `year`         | 1 год                  | Не сделал в 2026 → штраф весь 2027             |

**Статистика:** успех разделяется на "вовремя" (`done_at <= period_end`) и "с просрочкой" (`done_at > period_end`).

### `done` is a checkbox, not a disappearance

`done` tasks stay visible in the current period task list with a checkmark.
User can undo: `done -> todo` (uncheck) at any time within the period.
At period end, scheduler archives `done` periods (success).

**`done_at` behavior on toggle:**
- `todo -> done`: set `done_at = now()`
- `done -> todo` (uncheck): set `done_at = NULL`
- This ensures `done_at` is only set on tasks that are actually done at archive time.

### Archived outcome (derived, not stored)

`archived` is terminal. The outcome is derived from timestamps:
- `done_at IS NOT NULL` + `done_at <= period_end` = **success on time**
- `done_at IS NOT NULL` + `done_at > period_end` = **success late** (completed during overdue penalty period)
- `done_at IS NULL` = **failure** (task was given up or expired)

This covers statistics: success (on time / late) vs failures from `archived` periods.

### Replanning from backlog

When user replans a backlog task to a new period:
1. Old `task_period` (backlog) -> `archived` (with `done_at = NULL` -> counts as failure in stats)
2. New `task_period` created with `status = 'todo'` in the target period

This keeps the backlog query clean — no phantom entries.

### Recurring tasks skip backlog

When a recurring task's period ends without completion:
- Old period -> `archived` (failure, `done_at = NULL`)
- New period auto-created with `status = 'todo'` for next cycle

Recurring tasks never sit in `backlog` — they auto-renew by definition.

### recurring_configs validation (app layer)

- `day_of_week` is only valid when `tasks.level = 'week'`; must be NULL otherwise
- `day_of_month` is only valid when `tasks.level = 'month'`; must be NULL otherwise
- `month_of_year` is only valid when `tasks.level = 'month'`; must be NULL otherwise
  - If set: task is generated once a year, on day 1 of that month (e.g. `month_of_year = 3` → 1 March only)
  - If NULL: task is generated every month (standard monthly recurring)
- Year-level recurring tasks have no day/month fields (all NULL)
- Enforced at application layer, not DB constraint

### Timezone and scheduling

- `users.timezone` stores IANA timezone (e.g. 'Europe/Moscow')
- Scheduler runs periodically (e.g. hourly) in UTC, converts per user timezone to determine period boundaries
- Frontend marks `overdue` tasks with "Долг с прошлого периода" badge (status already set by scheduler)

### Overdue (DB status, штрафной период)

`overdue` — полноценный статус в БД. Задача получает его от шедулера по окончании первого периода, если не выполнена.
- Остаётся в текущем виде с маркером "Долг с прошлого периода"
- По окончании штрафного периода: `overdue → backlog` (шедулер)
- Если выполнена в штрафном периоде: `overdue → done → archived` (done_at > period_end = выполнено с просрочкой)

### Day view

`target_date` on week-level task_periods. Frontend filters by target_date for daily display.
Task deadline is still tied to the week -- if not done by target_date, user can still complete it any other day within the week.

### Year tasks with deadline_month

`deadline_month` narrows the year-task's effective deadline to the end of a specific month.
`period_start = Jan 1`, `period_end = Dec 31` (always full year).
Scheduler checks: if month > deadline_month AND status = 'todo' --> move to `backlog`.

---

## Key Queries

```sql
-- Weekly task list (includes done tasks — shown as checked)
SELECT t.*, tp.*, rc.*
FROM task_periods tp
JOIN tasks t ON t.id = tp.task_id
LEFT JOIN recurring_configs rc ON rc.task_id = t.id
WHERE tp.user_id = :userId
  AND tp.period_type = 'week'
  AND tp.period_start = :weekStart
  AND tp.status IN ('todo', 'done', 'overdue');

-- Daily view (filter within week)
SELECT t.*, tp.*
FROM task_periods tp
JOIN tasks t ON t.id = tp.task_id
WHERE tp.user_id = :userId
  AND tp.period_type = 'week'
  AND tp.period_start = :weekStart
  AND tp.target_date = :date
  AND tp.status IN ('todo', 'done', 'overdue');

-- Backlog (clean — no replanned phantoms)
SELECT t.*, tp.*
FROM task_periods tp
JOIN tasks t ON t.id = tp.task_id
WHERE tp.user_id = :userId
  AND tp.status = 'backlog'
ORDER BY tp.backlog_at ASC;

-- Archive
SELECT t.*, tp.*
FROM task_periods tp
JOIN tasks t ON t.id = tp.task_id
WHERE tp.user_id = :userId
  AND tp.status = 'archived'
ORDER BY tp.archived_at DESC;

-- Statistics (non-recurring): % выполнения жёстких целей (проектные задачи)
SELECT
  COUNT(*) FILTER (WHERE done_at IS NOT NULL AND done_at <= period_end) AS completed_on_time,
  COUNT(*) FILTER (WHERE done_at IS NOT NULL AND done_at > period_end)  AS completed_late,
  COUNT(*) FILTER (WHERE done_at IS NULL)                               AS failed
FROM task_periods tp
WHERE tp.user_id = :userId
  AND tp.status = 'archived'
  AND NOT EXISTS (SELECT 1 FROM recurring_configs rc WHERE rc.task_id = tp.task_id);

-- Statistics (recurring): Consistency — стабильность повторяемых привычек/ритуалов
SELECT
  COUNT(*) FILTER (WHERE done_at IS NOT NULL) AS completed,
  COUNT(*) FILTER (WHERE done_at IS NULL)     AS missed,
  ROUND(
    COUNT(*) FILTER (WHERE done_at IS NOT NULL)::numeric /
    NULLIF(COUNT(*), 0) * 100, 1
  ) AS consistency_pct
FROM task_periods tp
WHERE tp.user_id = :userId
  AND tp.status = 'archived'
  AND EXISTS (SELECT 1 FROM recurring_configs rc WHERE rc.task_id = tp.task_id);
```

> **Изоляция статистики:** recurring-задачи трекают *Consistency* (% регулярности), не-recurring — *Completion* (% выполнения целей). Смешивать нельзя — они измеряют разные вещи.

---

## Indexes (proposed)

```sql
idx_task_periods_user_period  ON task_periods(user_id, period_type, period_start)
idx_task_periods_task_id      ON task_periods(task_id)
idx_task_periods_status       ON task_periods(status) WHERE status IN ('todo', 'done', 'overdue', 'backlog')
idx_task_periods_target_date  ON task_periods(target_date) WHERE target_date IS NOT NULL
idx_recurring_configs_task    ON recurring_configs(task_id)
idx_tasks_user_id             ON tasks(user_id)
```

---

## Open Questions

- [ ] Soft-delete on tasks -- `deleted_at` or hard-delete?
- [ ] `sessions` table for refresh tokens or Redis TTL?
- [ ] Partition `task_periods` by `user_id` at scale?

---

## Decisions

| Date       | Decision                                      | Reason                                         |
|------------|-----------------------------------------------|------------------------------------------------|
| 2026-05-01 | `task_periods` separate table                 | Per-period task list, historical tracking         |
| 2026-05-01 | `archived` as explicit status in task_periods | Consistent status enum, queryable directly     |
| 2026-05-01 | `recurring_configs` separate table            | Clean 1:1 relation; presence = recurring       |
| 2026-05-01 | `user_id` denormalized on `task_periods`      | Avoid join on every list query               |
| 2026-05-01 | `period_type` denormalized on `task_periods`  | Must match tasks.level; enforced in app layer  |
| 2026-05-01 | UNIQUE (task_id, period_start)                | One task appears once per period               |
| 2026-05-01 | `backlog` is a DB status                      | Explicit state for unplanned tasks             |
| 2026-05-02 | Statuses: todo, done, overdue, backlog, archived | `overdue` = штрафной период (второй шанс); failed не существует в БД — производный исход из archived с done_at IS NULL |
| 2026-05-02 | `overdue` — штрафной период (второй шанс)     | Дисциплина: одна попытка перепланирования до попадания в backlog; жёсткая модель MVP |
| 2026-05-02 | Длительность overdue = длительность базового уровня | week → +1 нед, month → +1 мес, year → +1 год; симметрично периоду задачи |
| 2026-05-02 | `month_of_year` в recurring_configs           | month-задача с month_of_year генерируется раз в год в конкретный месяц, не ежемесячно |
| 2026-05-02 | Статистика: вовремя vs с просрочкой           | done_at <= period_end = вовремя; done_at > period_end = с просрочкой |
| 2026-05-01 | `target_date` on task_periods                 | Day view = filtered week view, deadline stays weekly |
| 2026-05-01 | `sort_order` on task_periods                  | Drag-and-drop reordering within a period       |
| 2026-05-01 | `level` removed from recurring_configs        | Inherited from tasks.level, avoids desync      |
| 2026-05-01 | `deadline_month` semantics clarified          | Period = full year, scheduler checks month end |
| 2026-05-01 | `done` = checkbox, stays in task list            | User sees completed tasks, can undo            |
| 2026-05-01 | `done <-> todo` is freely toggleable          | Undo support within period                     |
| 2026-05-01 | Archived outcome derived from done_at         | done_at present = success, absent = failure    |
| 2026-05-01 | Replan archives old backlog period            | Prevents phantom entries in backlog query      |
| 2026-05-01 | Recurring tasks skip backlog                  | Auto-renew; missed period archived as failure  |
| 2026-05-01 | `backlog_at` timestamp added                  | Sort backlog by age, show "since" in UI        |
| 2026-05-02 | `done_at` nulled on uncheck                   | Only tasks actually done have done_at at archive time |
| 2026-05-02 | Partial UNIQUE (task_id, period_start)         | WHERE status != 'archived'; allows replan to same period |
| 2026-05-02 | recurring_configs validation at app layer      | day_of_week only for week, day_of_month only for month |
| 2026-05-02 | `users.timezone` field                         | Scheduler and frontend use user's IANA timezone |
| 2026-05-02 | Hard delete blocked if archived periods exist  | Нельзя удалить задачу с хотя бы одним archived-периодом — защита исторических данных; API возвращает ошибку |
| 2026-05-02 | Frontend предупреждает перед удалением         | Даже без archived-периодов — диалог подтверждения: действие необратимо |
