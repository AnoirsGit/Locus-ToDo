# Project-wide Quality-of-Life / UX polish — todo

> Created 2026-06-10. Grounded in code audit, not generic advice: every item below
> was verified in the repo. No DB/schema changes anywhere in this doc.

---

## A — UX-level bugs → moved to `bugs.md`

The four critical bugs (UTC "today" B1, web delete/replan B2, stale refetch B3,
silent mobile errors B4) now live in `current/bugs.md` — the canonical bug list.
Bug-flavored bullets from sections C–F below were moved there too.

---

## B — Feedback & loading states

- [~] **Skeleton loaders** — WEB DONE (`Skeleton`/`TaskListSkeleton`/`StatsSkeleton`, wired into today/TaskList/stats). Mobile still pending (bare `CircularProgressIndicator` on notes + tasks + stats)
- [ ] **Pull-to-refresh on mobile notes** — tasks/view have `RefreshIndicator`, notes page doesn't
- [~] **Double-submit guards** — DONE for task forms: CreateTaskForm now has a `submitting` flag; EditTaskForm closes synchronously before its background save (no window). Note inputs still unaudited.
- [ ] **Optimistic-failure rollback consistency** — web notes rollback on create failure ✓; verify task toggle/create rollback on web + mobile and that the user sees a toast when it happens (ties to A4)

## C — Input & interaction (web)

- [x] **Global keyboard shortcuts** — DONE: `c`/`n` quick-add on the active view (via `shared/lib/commands.svelte.ts` bus), `g`+`t/w/m/y/b/a/s/n` navigation, `?` help overlay (`ShortcutsHelp`); wired in `(app)/+layout.svelte`
- [~] **Undo toasts** — task DELETE done (toast with Undo → client-side re-create in `EditTaskForm`). Replan-undo and note-delete-undo still pending.
- [~] **Drag-and-drop**: DONE for kanban day columns — week tasks drag between days (`PATCH /tasks/:id { targetDate }`, optimistic + revert). Day tasks don't drag: no `periodStart` update path in the API (only `status` on `/task-periods`). Notes DnD (notes-v2 N5) still separate.
- [ ] **Web-on-phone pass**: burger sidebar exists ✓, kanban drag-scroll ✓ — verify TaskModal usability at 360 px (sticky footer buttons, no horizontal overflow), tap targets ≥40 px in note rows

## D — Interaction polish (mobile)

- [ ] **List animations** — task complete/delete snaps in/out; use `AnimatedList`/`AnimatedSwitcher` for card removal + strike-through transition (Dismissible already animates swipes)
- [ ] **Haptics consistency** — cards have them (`HapticFeedback.lightImpact`); add to FAB create-success, delete confirm, sheet snap
- [ ] **TaskFormSheet ergonomics** — drag handle, keyboard-avoidance check on small screens, dirty-dismiss confirm (same rule as the web modal dirty guard, see `bugs.md`)

## E — Consistency & content

- [ ] **E1. i18n unification** — single biggest consistency win; mobile plan already in `mobile-tasks-parity.md` Gap 5. Hardcoded-string leaks (web RU-in-EN, chip language mismatch, mobile AppBar title, date locale) are itemized in `bugs.md` — this item is the systematic sweep that closes them all
- [ ] **Empty states** — good ones exist (notes, backlog); audit: archive, stats-no-data, filtered-to-empty (tag filter active → say "no tasks match the filter" + clear-filter action, web + mobile)
- [x] **Page titles (web)** — DONE: localized `<title>` in `(app)/+layout.svelte` per route; auth pages + root fallback; `NotePage` sets the note content as title

## F — Auth & session QoL

- [x] **Return-to URL after login** — DONE: `client.ts` stores `returnTo` before the 401 redirect; login sends the user back (validated path), register clears it
- [ ] **Login/register form polish** — show/hide password toggle, autofocus first field, min-length hint on register, localized error messages (currently hardcoded Russian fallback 'Неверный email или пароль')
- [ ] **Graceful 401 during background refetch** (after `bugs.md` B3 lands) — don't yank the user to login from a background tab refresh failure without a toast

## G — Dev QoL (supports everything above)

- [ ] **Dev date/time control widget** — already in backlog memory (`project_ideas.md`): floating dev-only widget to mock "now" for scheduler/rollover testing; becomes much more valuable once B1/B3 (`bugs.md`) land (verifying midnight behavior without waiting for midnight)
- [ ] **Seed data refresh script** — verify `seed` covers all statuses/levels/recurring/tags/notes so every QoL state (overdue, backlog age, archive outcomes) is reproducible locally

---

## Suggested order

1. **`bugs.md` B1–B4 first** (see that file for branches) — correctness of the core loop
2. **B** (`feat/feedback-polish`) — skeletons, pull-to-refresh, submit guards
3. **C + D** (`feat/interaction-polish`) — shortcuts, undo, drag-and-drop, animations
4. **E + F** (`feat/consistency-i18n`) — string/date/title sweep, auth polish
5. **G** — alongside, when first needed for testing B1/B3

## Verification (Prove It, per branch)

- [ ] Critical-bug verification steps live in `bugs.md`
- [ ] `pnpm typecheck` + `flutter analyze` clean on every branch
