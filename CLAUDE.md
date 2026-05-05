# CLAUDE.md — Working Rules for "Цикл"

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

## ⚠️ Critical Gotchas & DB Constraints

- **SvelteKit Routes:** Directory is `src/pages/` (renamed in config), NOT `src/routes/`.
- **Tailwind v4:** No config file. Config lives in `app.css` via `@theme`. Starts with `@import "tailwindcss"`.
- **shadcn-svelte:** Add components via CLI (`npx shadcn-svelte@latest add`), NOT manually.
- **DB Schema:** DRAFT status. NEVER touch schema or migrations without explicit user confirmation.
- **DELETE Task:** `DELETE /api/tasks/:id` returns 409 if task has `archived` periods.
- **Scheduler:** Runs inside API process (`setInterval`). Do not move to a separate worker without discussion.
