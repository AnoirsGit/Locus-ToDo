# PROJECT-REFERENCE — Цикл

> Loaded every session. Keep it short — navigation facts only.

## What is this

"Цикл" — a self-disciplined task manager across three time horizons (Week / Month / Year).  
Tasks auto-archive on completion. Missed deadlines get one penalty period (`overdue`), then move to `backlog`.

---

## Monorepo

| Package         | Path              | Port | Stack                         |
|-----------------|-------------------|------|-------------------------------|
| `@locus/web`    | `apps/web`        | 5173 | SvelteKit 5, TypeScript, Vite |
| `@locus/api`    | `apps/api`        | 3000 | Fastify 5, PostgreSQL, Redis  |
| `locus_mobile`  | `apps/mobile`     | —    | Flutter 3, Riverpod           |
| `@locus/shared` | `packages/shared` | —    | TypeScript types only         |

**Commands:** `pnpm dev` · `pnpm dev:web` · `pnpm dev:api` · `pnpm build` · `pnpm typecheck`

---

## Key Files

| File                               | Status       | Description                        |
|------------------------------------|--------------|------------------------------------|
| `CLAUDE.md`                        | current      | Working rules for Claude           |
| `TECHNICAL-SPEC.md`                | draft        | Full product spec                  |
| `.claude/arch/database.md`         | draft ⚠️     | DB schema — not confirmed          |
| `.claude/arch/backend.md`          | draft        | Hexagonal arch, API, auth          |
| `.claude/arch/frontend.md`         | draft        | FSD, SvelteKit 5, stores           |
| `.claude/arch/mobile.md`           | draft        | FSD, Flutter, Riverpod             |
| `apps/api/src/db/schema.sql`       | draft ⚠️     | DB schema — not confirmed          |
| `apps/api/.env.example`            | current      | Env vars template                  |

---

## DB — Short Summary (draft ⚠️)

> Full detail: `.claude/arch/database.md`

| Table                | Key columns                                                        |
|----------------------|--------------------------------------------------------------------|
| `users`              | id, email, name, password_hash                                     |
| `tasks`              | id, user_id, title, description, level                             |
| `recurring_configs`  | id, task_id (UNIQUE), day_of_week, day_of_month, is_active         |
| `task_periods`       | id, task_id, user_id, period_type, period_start/end, status, target_date, sort_order |

Relations: `tasks.user_id → users.id`, `recurring_configs.task_id → tasks.id`, `task_periods.task_id → tasks.id`

Statuses: `todo | done | overdue | backlog | archived` (`overdue` = DB status, штрафной период; failed = derived: `archived` + `done_at IS NULL`)

**Not confirmed:** indexes, partitioning, soft-delete strategy, refresh token storage.

---

## Project Status

- [ ] Confirm DB schema
- [ ] Confirm API contracts
- [ ] Set up Docker Compose
- [ ] Implement auth
- [ ] Implement task CRUD (web + api)
- [ ] Implement scheduler (auto-archive / auto-fail)
- [ ] Implement recurring tasks
- [ ] Mobile: main task screen

---

## Git Conventions

Branches: `feat/`, `fix/`, `chore/` · Commits: `feat: ...`, `fix: ...`, `chore: ...`
