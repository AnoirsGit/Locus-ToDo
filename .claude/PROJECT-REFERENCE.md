# Project Reference

> Loaded every session. Navigation facts only.

Self-discipline task manager across three time horizons (Week / Month / Year).
Missed deadlines get one penalty period (`overdue`), then move to `backlog`.

---

## Monorepo

| Package | Path | Port | Stack |
|---------|------|------|-------|
| `@locus/web` | `apps/web` | 5173 | SvelteKit 5, Tailwind v4 |
| `@locus/api` | `apps/api` | 3000 | Fastify 5, PostgreSQL, Redis |
| `locus_mobile` | `apps/mobile` | — | Flutter 3, Riverpod |
| `@locus/shared` | `packages/shared` | — | TypeScript types only |

Commands: `pnpm dev` · `pnpm dev:web` · `pnpm dev:api` · `pnpm build` · `pnpm typecheck`

---

## Key Files

| File | Status | Description |
|------|--------|-------------|
| `CLAUDE.md` | current | Working rules |
| `TECHNICAL-SPEC.md` | draft | Product spec |
| `.claude/arch/*.md` | draft | Architecture docs |
| `apps/api/src/db/migrations/001_initial.sql` | draft ⚠️ | DB schema — not confirmed |
| `apps/api/.env.example` | current | Env vars template |
| `docker-compose.yml` | current | PostgreSQL + Redis |

---

## DB Summary (draft ⚠️)

Tables: `users` · `user_settings` · `tasks` · `recurring_configs` · `task_periods`

Task levels: `day | week | month | year`
Task statuses: `todo | done | overdue | backlog | archived`

Relations: `users →< tasks →< task_periods`, `tasks →< recurring_configs` (1:1)

---

## Project Status

- [x] Monorepo setup (pnpm workspaces, shared types)
- [x] Docker Compose (PostgreSQL + Redis)
- [x] Web UI (SvelteKit 5, FSD, dual theme, mock data)
- [x] API scaffold (hexagonal arch, auth + task routes, scheduler, migrations, seed)
- [ ] Confirm DB schema
- [ ] Connect web to real API (replace mocks)
- [ ] Implement scheduler (auto-archive / overdue)
- [ ] Implement recurring tasks
- [ ] Mobile: main task screen

---

## Git

Branches: `feat/`, `fix/`, `chore/` · Commits: `feat:`, `fix:`, `chore:`
