# CLAUDE.md — Working Rules for "Цикл"

---

## 1. Session Init

**Always read on startup:**
- `.claude/PROJECT-REFERENCE.md`

**Then identify the task context and load only what's needed:**

| Signal in the task                                               | Load                          |
|------------------------------------------------------------------|-------------------------------|
| DB, tables, migrations, SQL, indexes, schema                     | `arch/database.md`            |
| API, routes, use cases, auth, scheduler, Fastify, Redis          | `arch/backend.md`             |
| Components, pages, stores, SvelteKit, Svelte, FSD (web)         | `arch/frontend.md`            |
| Flutter, screens, providers, Riverpod, go_router                 | `arch/mobile.md`              |
| Product requirements, business logic, what and why               | `TECHNICAL-SPEC.md`           |
| Any branch work                                                  | `.claude/ai-ref-files/current/<branch>.md` |

If the task spans multiple layers — load multiple files.  
If a file doesn't exist — create it.

---

## 2. Plan Mode (required)

- Enter plan mode for any task with 3+ steps or architectural decisions
- If something goes wrong — STOP, re-plan, don't push forward blindly
- Write the plan to `.claude/ai-ref-files/current/<branch>.md` with checkboxes
- Confirm the plan before implementing

---

## 3. Task Management in Session

1. **Plan first** — write to `.claude/ai-ref-files/current/<branch>.md`
2. **Confirm the plan** — verify before implementing
3. **Track progress** — check off items as you go
4. **Explain changes** — brief summary at each step
5. **Document results** — fill in the Resume section of the branch file
6. **Capture lessons** — add a Lessons section after corrections

---

## 4. Auto-update Arch Files

**Rule:** if something changed during work — update the relevant `arch/` file **immediately**, not at the end of the task.

| What changed                                              | Update                                              |
|-----------------------------------------------------------|-----------------------------------------------------|
| Table added/modified, index or column changed             | `arch/database.md` → tables + open questions        |
| New route, use case, port/adapter, auth decision          | `arch/backend.md` → structure + decisions           |
| New component/slice, store, FSD layer (web)               | `arch/frontend.md` → structure + decisions          |
| New screen, provider, FSD slice (mobile)                  | `arch/mobile.md` → structure + decisions            |
| Public API or app ports changed                           | `README.md`                                         |
| Table list or key monorepo facts changed                  | `PROJECT-REFERENCE.md` → DB summary                |

**Decision entry format** (each `arch/` file has a "Decisions" table):
```
| Date       | Decision               | Reason               |
| YYYY-MM-DD | What was done          | Why exactly this way |
```

Close open questions (`- [ ]` → `- [x]`) when resolved.

---

## 5. Self-improvement Loop

- After any correction from the user — add a lesson to the branch file
- Write rules to prevent repeating the same mistake
- Review needed lessons at session start if they exist

---

## 6. Verification Before Done

- Never mark a task complete without proving it works
- Ask yourself: "Would a staff engineer approve this?"
- Run checks, read logs, prove correctness

---

## 7. Monorepo Structure

```
apps/web        → SvelteKit 5, FSD          (port 5173)
apps/api        → Fastify 5, Hexagonal      (port 3000)
apps/mobile     → Flutter, FSD, Riverpod
packages/shared → TypeScript types only
```

**Commands:** `pnpm dev` · `pnpm dev:web` · `pnpm dev:api` · `pnpm build` · `pnpm typecheck`

---

## 8. Code Style

- **Arrow functions** — everywhere there's no need for own `this`
- **No unnecessary comments** — only complex business logic
- **`type` over `interface`** — in TypeScript
- **Svelte 5 runes** — `$state`, `$derived`, `$props()`, `$bindable()` — no Options API
- **Zod** — validation at boundaries (API requests/responses), not inside
- **Hexagonal (backend)** — business logic in `domain/`, infra in `infrastructure/`, orchestration in `application/`
- **FSD (web + mobile)** — import only downward: pages → widgets → features → entities → shared

---

## 9. Responsibility Boundaries

- **Don't touch** DB schema without explicit user confirmation
- **Don't add** features not explicitly requested
- **Don't refactor** code outside the task scope
- **Minimal impact** — change only what's needed

---

## 10. Known Constraints (current status)

- DB schema **not confirmed** — `arch/database.md` and `schema.sql` are drafts
- Auth strategy (refresh tokens) — **open question** (see `arch/backend.md`)
- API contracts **are drafts** — not finalized

---

## 11. Principles

- **Simplicity first** — minimal change, maximum effect
- **No laziness** — find the root cause, not a workaround
- **No speculation** — don't design for hypothetical requirements

---

*Update this file when working rules change. Architecture goes in `arch/*.md`.*
