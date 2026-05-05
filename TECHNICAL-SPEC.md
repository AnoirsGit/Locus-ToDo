# Technical Specification: Locus (self-discipline task manager)

> Version: Draft v1.3 | Date: 2026-05-04

---

## 1. Core Concept

A task manager that enforces self-discipline.
If a task is not completed on time — it moves to `backlog` and waits for rescheduling.
If completed — it goes to `archived`.

---

## 2. Task Levels

The system is divided into three time scales. Primary display method — checkbox list.

| Level | Period | Purpose               |
|-------|--------|-----------------------|
| Day   | Day    | Scheduled daily tasks |
| Week  | Week   | Operational tasks     |
| Month | Month  | Mid-term goals        |
| Year  | Year   | Strategic objectives  |

---

## 3. Task Lifecycle

### Path A — Completion

1. User checks the box → status `done` (task stays in list with checkbox)
2. Checkbox can be unchecked at any point within the period → `todo` (`done_at` is cleared)
3. At period end the scheduler moves `done` → `archived` (success, `done_at` preserved)

### Path B — Overdue (two-stage)

1. Deadline arrives (end of week / month / year)
2. Task is not marked `done`
3. System moves task to `overdue` (penalty period begins)
4. Task remains visible in the current view (Day / Week / Month) with a **"Carried over from previous period"** marker
5. User can complete the task during the penalty period → `overdue → done → archived` (completed late)
6. At the end of the penalty period uncompleted tasks → `backlog`
7. From backlog: replan → new `todo`, or discard → `archived` (failure)
8. When replanning, the old backlog period is archived as a failure

### Recurring Tasks and Overdue

Recurring tasks **never enter backlog**. A missed period is immediately archived as a failure; a new `todo` is auto-created for the next cycle.

### Task Statuses

```
todo <-> done                         (checkbox, free toggle)
done -> archived (done_at set)        (success, end of period)
todo -> overdue                       (first period missed — scheduler)
overdue -> done                       (completed during penalty period)
overdue -> backlog                    (penalty period missed — scheduler)
backlog -> archived (no done_at)      (failure, discarded)
backlog -> todo                       (replanned, old period -> archived)
```

> **There is no `failed` status in the DB.** "Failure" is a derived outcome: `archived` + `done_at IS NULL`.

### Archive Outcome (derived)

`archived` is the terminal status. Outcome is determined by `done_at`:
- `done_at IS NOT NULL` + `done_at <= period_end` = completed on time (success)
- `done_at IS NOT NULL` + `done_at > period_end` = completed late (success, but overdue)
- `done_at IS NULL` = task failed or discarded (failure)

### Overdue (DB status, penalty period)

`overdue` is a first-class status. Assigned by the scheduler when the original period ends without completion.
- Remains visible in the current view with a **"Carried over from previous period"** marker
- User can complete it: `overdue → done` (counted as "completed late")
- At the end of the penalty period without completion: `overdue → backlog`

---

## 4. Smart Display (Top-Down)

Higher-level tasks are always shown in lower-level views.

### Day View
A filtered view within the week. Week tasks with `target_date` matching today.
- Primary: week tasks where `target_date` = today
- Context: remaining active week tasks
- Context: active month tasks
- Context: active year tasks

The deadline is tied to the week, not the day. If not done Wednesday — still completable Thursday.

### Week View
- Primary: week tasks for the current week
- Context: month tasks + year tasks

### Month View
- Primary: month tasks for the current month
- Context: year tasks

### Year View
- Only year tasks

### Level Badge
Every task displays a level badge (Day / Week / Month / Year) so the scope of the goal is always visible.

---

## 5. Recurring Tasks

Recurring tasks are automatically created at the start of each period with status `todo`.

### Configuration
- **Day task**: every day, optionally specify time of day (HH:MM)
- **Week task**: every week, optionally specify day of week (Mon–Sun)
- **Month task**: every month, optionally specify day of month (1–31)
- **Year task**: every year

---

## 6. Year Tasks with Monthly Deadline

A year task can have a deadline in a specific month (`deadline_month`).
The task period is always the full year (Jan 1 – Dec 31).
At the end of the specified month the scheduler checks status:
- `done` → archived as success
- `todo` → moves to `backlog`

---

## 7. API (draft)

| Method | Path                    | Description                   |
|--------|-------------------------|-------------------------------|
| POST   | /api/auth/register      | Register                      |
| POST   | /api/auth/login         | Login                         |
| POST   | /api/auth/refresh       | Refresh tokens                |
| GET    | /api/auth/me            | Current user                  |
| GET    | /api/tasks              | List tasks (filters)          |
| POST   | /api/tasks              | Create task                   |
| PATCH  | /api/tasks/:id          | Update task metadata          |
| DELETE | /api/tasks/:id          | Delete task                   |
| POST   | /api/tasks/:id/replan   | Replan from backlog           |
| GET    | /api/task-periods       | List periods                  |
| PATCH  | /api/task-periods/:id   | Update period status (toggle) |

> API contracts are not yet finalized. Request/response shapes and query params will be confirmed during backend development.

**DELETE /api/tasks/:id validation rule:**
The backend blocks deletion (400/409) if the task has at least one `task_period` with status `archived`.
The frontend must always show a confirmation dialog before deleting any task — the user is warned that the action permanently destroys all period history.

---

## 8. Open Questions (to confirm)

- [ ] Final DB table structure (draft in `arch/database.md`)
- [ ] Refresh token strategy (Redis vs DB)
- [ ] Push notifications in the mobile app
- [ ] Shared access / collaboration
- [ ] Offline mode: `done_at` collision — from mobile client vs `now()` on server when offline. **Deferred to future versions.**
- [ ] Overdue logic for recurring tasks: fully exclude `overdue` status (current MVP) or expose as setting (`allow_overdue` per recurring task). Default: recurring tasks skip the penalty period and are archived immediately.

---

## 9. Confirmed Decisions (MVP)

- [x] Penalty period (`overdue`) — strict two-stage overdue model (todo → overdue → backlog). Discipline enforcement is the core MVP feature.
- [x] No `failed` status in DB — failure is defined as `archived` with `done_at IS NULL`.
- [x] `recurring_configs` — separate relational table (not JSONB).
- [x] Hard delete blocked when archived periods exist; frontend always shows a confirmation dialog.
- [x] **Stats isolation:** recurring tasks → *Consistency* metric (habit regularity %); all others → *Completion* metric (goal completion %). Computed in separate queries, never mixed.

---

*This document is updated alongside the project.*
