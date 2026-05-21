## Language

**Everything must be in English — code comments, docs, plans, AI responses, arch files.**

## Load Context

Always read: `@.claude/PROJECT-REFERENCE.md`
Load based on task:

- DB / schema / migrations → `@.claude/arch/database.md`
- API / backend / auth → `@.claude/arch/backend.md`
- Web / SvelteKit / UI → `@.claude/arch/frontend.md`
- Mobile / Flutter → `@.claude/arch/mobile.md`
- Product rules → `@TECHNICAL-SPEC.md`
- Branch work → `@.claude/ai-ref-files/current/<branch>.md`

## Workflow & Scope

- **Plan Mode:** Tasks with 3+ steps require a plan in the `<branch>.md` file with checkboxes. Confirm before coding.
- **Prove It:** NEVER mark a task complete without running checks and proving it works.
- **Immediate Sync:** Update `arch/` files _immediately_ when architecture changes.
- **Learn:** Add a "Lessons" section to the branch file after user corrections.
- **Strict Scope:** Do not refactor or add unrequested features outside the current task.

## Monorepo

- `apps/web` → SvelteKit 5, FSD, Tailwind v4 (port 5173)
- `apps/api` → Fastify 5, Hexagonal, PostgreSQL (port 3000)
- `apps/mobile` → Flutter 3, FSD, Riverpod
- `packages/shared` → TypeScript types only
  _Commands:_ `pnpm dev` · `pnpm dev:web` · `pnpm dev:api` · `pnpm build` · `pnpm typecheck`

## Code Style

- **TS:** Arrow functions everywhere. `type` over `interface`.
- **Svelte 5:** Runes only (`$state`, `$derived`, etc.). Stores MUST use `.svelte.ts` extension.
- **Backend:** Hexagonal (`domain/` → `application/` → `infrastructure/`). Zod validation at boundaries only.
- **FSD:** Downward imports only (`pages → widgets → features → entities → shared`). Same-layer slices must NOT import each other directly (use `@x/` pattern).
- **Comments:** Only for complex business logic.

## Roadmap — Priority Order

> Work top-to-bottom. Do not jump ahead. Each phase unlocks the next.

### Phase 1 — Close the loop ✅ DONE
- [x] **Confirm DB schema** — `001_initial.sql` + `002_recurring_multiday.sql` + `003_subtasks.sql` confirmed
- [x] **Run migrations + seed** — verified against live PostgreSQL, seed data in place
- [x] **Connect web → API: tasks** — `tasksApi` + all features use real endpoints, optimistic updates
- [x] **Connect web → API: auth** — login/register/refresh/logout all wired
- [x] **Implement scheduler** — hourly cron, all transitions implemented (todo→overdue→backlog, recurring rollover, day archiving)

### Phase 2 — Complete core features ✅ DONE
- [x] **Recurring tasks** — scheduler + UI toggle in CreateTaskForm + EditTaskForm (web + mobile)
- [x] **Mobile: main task screen** — Today/Week/Month/Year/Kanban views, progress cards, context sections
- [x] **Mobile: task CRUD** — create, toggle, delete, update, recurring via TaskFormSheet
- [x] **Stats page** — completion %, trends (web client-side + mobile Flutter page)
- [x] **Stats: backend API** — `GET /api/stats?today=YYYY-MM-DD`, SQL aggregates, full historical data; stats page rewritten to load from API

### Phase 3 — Quality & polish ✅ DONE
- [x] **Error handling** — global toast system (`toastStore`), API client fires `toastStore.error()` on all non-auth failures; `<Toasts />` mounted in app layout
- [x] **Mobile: offline mode** — Drift SQLite DB + outbox sync queue + `LocalTaskRepository` + `SyncWorker` — all wired in `TasksNotifier`
- [x] **Mobile: push notifications** — `NotificationService` (pre-deadline + evening summary), `NotificationPrefs` UI in Settings, initialized in `main.dart`
- [x] **Notes → API** — `notes` table (migration 004), full CRUD backend (`note.repository.ts` + usecase + routes); web `noteStore` loads from API on mount, syncs all mutations (create w/ client UUIDs, debounced PATCH content, PATCH collapsed/type/parentId, DELETE)
- [x] **Web: logout UI** — button in user card in sidebar calling `authApi.logout()` + redirect to `/login`

### Phase 4 — Backlog ideas ✅ DONE
- [x] **Subtasks** — `SubtaskChecklist.svelte` in `entities/task/ui/`; lazy-loaded in `TaskCard` via toggle button; `GET /api/tasks/:id/subtasks` + inline add + toggle
- [x] **Recurring: multiple days per week** — already fully implemented (migration 002, `days_of_week SMALLINT[]`, UI day-picker in TaskFormFields, API array handling, TaskCard display)
- [x] **Mobile: notes screen** — `NotesPage` + `NoteRow` (recursive tree, expand/collapse, inline edit, add child/root); replaces DocsPage at `/notes`
- [x] **Tag system** — `tags` + `task_tags` + `note_tags` tables (migration 005); full CRUD backend; web: `tagStore`, `TagChip`, `TagPicker` in `entities/tag/`; tag picker in `EditTaskForm` (loads on open, saves on submit via `PUT /api/tags/tasks/:id`)

---

## ⚠️ Critical Gotchas & DB Constraints

- **SvelteKit Routes:** Directory is `src/pages/` (renamed in config), NOT `src/routes/`.
- **Tailwind v4:** No config file. Config lives in `app.css` via `@theme`. Starts with `@import "tailwindcss"`.
- **shadcn-svelte:** Add components via CLI (`npx shadcn-svelte@latest add`), NOT manually.
- **DB Schema:** DRAFT status. NEVER touch schema or migrations without explicit user confirmation.
- **DELETE Task:** `DELETE /api/tasks/:id` returns 409 if task has `archived` periods.
- **Scheduler:** Runs inside API process (`setInterval`). Do not move to a separate worker without discussion.
