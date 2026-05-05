# arch/backend.md

> Load when: API, business logic, backend layers, auth, scheduler.

## Hexagonal Architecture

```
apps/api/src/
  domain/           # Business logic, no framework deps
    task/task.port.ts         # ITaskRepository interface
    user/user.port.ts         # IUserRepository interface
    user/user.types.ts
  application/      # Use cases — orchestration only
    task/           # create, list, update, delete, toggle-period, replan
    auth/           # register, login
    period-utils.ts
  infrastructure/   # Adapters
    db/             # postgres client, task.repository.ts, user.repository.ts
    http/           # Fastify routes + authenticate plugin
      routes/       # auth.routes.ts, tasks.routes.ts, task-periods.routes.ts
    scheduler/      # scheduler.ts (setInterval, daily job)
  db/               # migrate.ts, seed.ts, migrations/001_initial.sql
  server.ts         # Entry point
```

Layer rule: dependencies point inward only. `domain` has no external deps.

---

## API Contracts

- Prefix: `/api` · Auth: `Bearer <access_token>` · Dates: ISO 8601
- Errors: `{ error: string, details?: unknown }`

| Method | Path | Auth |
|--------|------|------|
| POST | `/api/auth/register` | — |
| POST | `/api/auth/login` | — |
| GET | `/api/auth/me` | ✓ |
| GET | `/api/tasks` | ✓ |
| POST | `/api/tasks` | ✓ |
| PATCH | `/api/tasks/:id` | ✓ |
| DELETE | `/api/tasks/:id` | ✓ |
| PATCH | `/api/tasks/:id/periods/:periodId/toggle` | ✓ |
| PATCH | `/api/tasks/:id/periods/:periodId/replan` | ✓ |

---

## Authentication

**Status: open ⚠️** — refresh token strategy not decided.

Current: JWT access token (15 min). Refresh: Redis vs PostgreSQL sessions table — TBD.

---

## Scheduler

Runs daily (setInterval MVP). Converts to user's IANA timezone for period boundaries.

```
period ends + status = 'todo'    → 'overdue'   (penalty period starts)
penalty ends + status = 'overdue' → 'backlog'
period ends + status = 'done'    → 'archived'
```

Recurring tasks skip overdue/backlog: missed period → `archived` (failure), new `todo` auto-created.

DELETE blocked if any `archived` period exists for that task → 409.

---

## Key Decisions

| Decision | Reason |
|----------|--------|
| Fastify 5 | Performance, TypeScript first-class |
| Hexagonal arch | Isolate business logic from infra |
| Recurring via separate table | Clean 1:1 relation; presence = recurring |
| 2-stage overdue (todo→overdue→backlog) | Penalty period = second chance mechanic |
| DELETE blocked with archived periods | Protect historical data |
| Scheduler in API process (setInterval) | MVP; move to separate worker later |
| Startup DB connection verification | Ensure DB is reachable before accepting traffic |
