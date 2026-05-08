# arch/database.md

> Load when: DB schema, migrations, queries, indexes, relations.
> **Status: PARTIALLY CONFIRMED — recurring_multiday + subtasks confirmed (2026-05-08)**

---

## Tables

### users
`id` uuid PK · `email` unique · `name` · `password_hash` · `timezone` (IANA) · `created_at`

### user_settings
`user_id` FK → users (1:1)

### tasks
`id` uuid PK · `user_id` FK (CASCADE) · `title` · `description` · `level` (day|week|month|year) · `scheduled_time` · `parent_task_id` FK → tasks ON DELETE RESTRICT (nullable) · `created_at` · `updated_at`

**003_subtasks.sql** — added `parent_task_id`. Subtask rules (app layer): level ≤ parent level, no recurring allowed, DELETE on parent blocked if subtasks have archived periods.

### recurring_configs
`id` uuid PK · `task_id` FK UNIQUE (CASCADE) · `is_active` · `days_of_week` SMALLINT[] (0-6 each, week only, max 6, null = any day) · `day_of_month` (1-31, month only) · `created_at`

Presence of a row = task is recurring. Level inherited from `tasks.level`.

**002_recurring_multiday.sql** — renamed `day_of_week SMALLINT` → `days_of_week SMALLINT[]`. Existing single-day values migrated to one-element arrays. Max 6 days enforced by DB constraint.

### task_periods
`id` uuid PK · `task_id` FK (CASCADE) · `user_id` FK (denorm) · `period_type` · `period_start` DATE · `period_end` DATE · `status` · `target_date` (week only) · `deadline_month` (year only) · `sort_order` · `done_at` · `backlog_at` · `archived_at` · `created_at` · `updated_at`

`UNIQUE (task_id, period_start) WHERE status != 'archived'`

---

## Status Lifecycle

```
todo ↔ done                 (user toggle — freely reversible within period)
todo → overdue              (period ends, not done — scheduler)
overdue → done              (user completes during penalty period)
overdue → backlog           (penalty period ends, not done — scheduler)
done / overdue → archived   (period ends — scheduler)
backlog → todo              (user replans — old period archived as failure)
```

**Penalty period duration** = same as task level: week → +1 week, month → +1 month, year → +1 year.

**Archived outcome** (derived from timestamps):
- `done_at ≤ period_end` → success on time
- `done_at > period_end` → success late (completed during penalty)
- `done_at IS NULL` → failure

`done_at` is set on check, nulled on uncheck.

---

## Key Rules

- `done` tasks stay visible in the task list (user sees checkmark, can undo)
- Recurring tasks skip overdue/backlog: missed period → `archived` (failure), next `todo` auto-created
- Recurring stats = Consistency % (regularity); non-recurring = Completion % (goal achievement) — never mixed
- DELETE blocked if any `archived` period exists for task → 409
- Replan: archives old backlog period as failure (`done_at = NULL`), creates new `todo`
- Day view = week tasks filtered by `target_date` (deadline stays weekly)
- `period_type` and `user_id` are denormalized on `task_periods` for fast queries — enforced at app layer
- `recurring_configs` validation at app layer: `day_of_week` week only, `day_of_month` month only

---

## Key Queries

```sql
-- Weekly task list
SELECT t.*, tp.*, rc.*
FROM task_periods tp
JOIN tasks t ON t.id = tp.task_id
LEFT JOIN recurring_configs rc ON rc.task_id = t.id
WHERE tp.user_id = :userId AND tp.period_type = 'week'
  AND tp.period_start = :weekStart AND tp.status IN ('todo', 'done', 'overdue');

-- Daily view
WHERE tp.period_start = :weekStart AND tp.target_date = :date AND tp.status IN ('todo', 'done', 'overdue');

-- Backlog
WHERE tp.user_id = :userId AND tp.status = 'backlog' ORDER BY tp.backlog_at ASC;

-- Archive
WHERE tp.user_id = :userId AND tp.status = 'archived' ORDER BY tp.archived_at DESC;
```

---

## Open Questions

- [ ] Soft-delete on tasks (`deleted_at` vs hard delete)?
- [ ] Refresh token storage (Redis TTL vs `sessions` table)?
- [ ] Partition `task_periods` by `user_id` at scale?
- [ ] Recurring week tasks with `days_of_week` — currently creates one week-period (uses `days_of_week` for display only). Full multi-period-per-day scheduling is a follow-up.
