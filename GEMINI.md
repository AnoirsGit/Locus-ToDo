# GEMINI.md — Working Rules

## Language
**Everything must be in English — code comments, docs, plans, AI responses, arch files.**

---

## 1. Session Init

Always read: `.claude/PROJECT-REFERENCE.md`

Then load by task context:

| Signal | Load |
|--------|------|
| DB, schema, migrations | `.claude/arch/database.md` |
| API, routes, backend | `.claude/arch/backend.md` |
| Web, Svelte, FSD | `.claude/arch/frontend.md` |
| Flutter, mobile | `.claude/arch/mobile.md` |
| Product requirements | `TECHNICAL-SPEC.md` |
| Branch work | `.claude/ai-ref-files/current/<branch>.md` |

---

## 2. Plan Mode

- Use `enter_plan_mode` for any task with 3+ steps or architectural decisions.
- Write the plan to `.claude/ai-ref-files/current/<branch>.md` with checkboxes.
- Confirm with the user before implementing.
- If something goes wrong — stop, re-plan, don't push forward blindly.

---

## 3. Arch File Updates

Update the relevant arch file **immediately** when code changes — not at the end.

| What changed | Update |
|---|---|
| Table / column / index | `.claude/arch/database.md` |
| Route / use-case / auth decision | `.claude/arch/backend.md` |
| Component / slice / store (web) | `.claude/arch/frontend.md` |
| Screen / provider (mobile) | `.claude/arch/mobile.md` |

---

## 4. Monorepo

```
apps/web     → SvelteKit 5, FSD, Tailwind v4   (port 5173)
apps/api     → Fastify 5, Hexagonal, PostgreSQL (port 3000)
apps/mobile  → Flutter 3, FSD, Riverpod
packages/shared → TypeScript types only
```

Commands: `pnpm dev` · `pnpm dev:web` · `pnpm dev:api` · `pnpm build` · `pnpm typecheck`

---

## 5. Code Style

- Arrow functions everywhere (no own `this`)
- `type` over `interface` in TypeScript
- Svelte 5 runes: `$state`, `$derived`, `$props()`, `$bindable()` — no Options API
- Zod at system boundaries only (API requests/responses)
- Backend hexagonal: `domain/` → `application/` → `infrastructure/`
- FSD: `pages → widgets → features → entities → shared` (downward only)
- No unnecessary comments — only complex business logic

---

## 6. Constraints

- **DB schema not confirmed** — no schema changes without explicit user OK.
- **Auth strategy (refresh tokens)** — open question.
- **API contracts are drafts.**
- Don't touch code outside the task scope.
- Don't add unrequested features.
- Never mark a task complete without proving it works via tests or manual verification.
