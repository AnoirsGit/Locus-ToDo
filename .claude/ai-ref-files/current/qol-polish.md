# Project-wide Quality-of-Life / UX polish — todo

> Created 2026-06-10. Third doc in the queue — start **after** `notes-v2/` and
> `mobile-tasks-parity.md` are done.
> Grounded in code audit, not generic advice: every item below was verified in the repo.
> No DB/schema changes anywhere in this doc.

---

## A — UX-level bugs (these feel like a broken product; do first)

### A1. "Today" is computed in UTC on web ⭐
`toISOString().split('T')[0]` is used for "today"/date keys across web:
`(app)/+layout.svelte`, `today/+page.svelte`, `Sidebar.svelte` (nav counts),
`WeekView.svelte`, `DayColumn.svelte`, `TaskList.svelte`, `CreateTaskForm.svelte`,
`stats/+page.svelte`. For a UTC+ user (e.g. UTC+5), between local midnight and UTC
midnight the whole app shows **yesterday**: wrong today list, wrong kanban highlight,
wrong stats `?today=`. Mobile uses local `DateTime.now()` components → web and mobile
disagree at night.
- [ ] Add `shared/lib/date.ts`: `localToday()` and `toLocalISO(d)` (year/month/day from local time)
- [ ] Replace every `toISOString().split('T')[0]` call used as a *calendar date* (audit each — timestamps sent to API as instants stay UTC)
- [ ] Same helper on mobile for consistency (`shared/lib/date_utils.dart`) — mostly already local, unify anyway

### A2. Web cannot delete or replan tasks
`tasksApi.remove` and `tasksApi.replan` exist in `entities/task/api/tasks.api.ts` but
are referenced by **zero UI components**. Mobile has both (confirm dialog + replan in
`TaskFormSheet`). Web users literally cannot delete a task.
- [ ] Delete button (danger) in `EditTaskForm` footer + confirm dialog; handle the 409 ("task has archived periods") with a clear message — API contract: hard delete blocked then
- [ ] Replan action in `EditTaskForm` for backlog tasks (web parity with mobile `_replan`): pick new period, POST `/tasks/:id/replan`, store update

### A3. Stale data: nothing ever refetches
Scheduler transitions run hourly server-side (`node-cron`, `0 * * * *`); clients load
once on mount. A tab/app left open across midnight or an hourly tick shows stale
statuses; "today" never rolls over. No `visibilitychange` / `AppLifecycleState`
handling anywhere.
- [ ] Web: on `document.visibilitychange` → visible (throttled, e.g. ≥60 s since last load): refetch tasks + recompute today
- [ ] Mobile: on `AppLifecycleState.resumed`: same (notifiers already have `refresh()`)
- [ ] Recompute "today"/week window on refetch, not only at component init (web `today/+page.svelte` computes `now` once in module scope)

### A4. Mobile errors are swallowed silently
No `SnackBar`/`ScaffoldMessenger` usage in the entire app. `tasks_notifier.dart`,
`sync_worker.dart`, notes notifier — all `catch (_) {}`. A failed create/toggle just
silently reverts (or worse, doesn't).
- [ ] Minimal toast service (`shared/ui/app_toast.dart`, ScaffoldMessenger-based) — mirror web `toastStore` semantics
- [ ] Wire into task/notes/tags mutation error paths (non-auth failures), like web's API client does
- [ ] Sync outbox: surface "N changes pending sync" + a failed-sync indicator (badge in app bar or settings row) — outbox exists, user has zero visibility

---

## B — Feedback & loading states

- [ ] **Skeleton loaders** — zero exist (grep: no skeleton/shimmer anywhere). Web: skeleton task cards for today/week/stats instead of the "Loading…" text line; mobile: same instead of bare `CircularProgressIndicator` (notes + tasks + stats)
- [ ] **Pull-to-refresh on mobile notes** — tasks/view have `RefreshIndicator`, notes page doesn't
- [ ] **Double-submit guards** — audit all submit buttons; auth pages do it (`loading` flag), verify Create/Edit task forms and note inputs disable while a request is in flight
- [ ] **Optimistic-failure rollback consistency** — web notes rollback on create failure ✓; verify task toggle/create rollback on web + mobile and that the user sees a toast when it happens (ties to A4)

## C — Input & interaction (web)

- [ ] **Global keyboard shortcuts**: `c`/`n` quick-add task on current view, `g t / g w / g m / g y` view navigation, `?` shortcut-help overlay. Only notes + modal-Escape have keys today
- [ ] **Unsaved-changes guard in TaskModal** — Escape and backdrop click discard edits instantly (`onClose` with no check); confirm when form is dirty
- [ ] **Focus management in modals** — focus trap inside `TaskModal`, return focus to the opener on close; `aria-modal` is set but Tab walks out of the dialog
- [ ] **Undo toasts** — after task delete (A2), note delete (notes-v2), and replan: 5-s toast with Undo (client-side re-create; no schema change)
- [ ] **Drag-and-drop**: tasks between kanban day columns (`PATCH targetDate`/`periodStart` — API supports it); also covers notes via `notes-v2/05` N5
- [ ] **Web-on-phone pass**: burger sidebar exists ✓, kanban drag-scroll ✓ — verify TaskModal usability at 360 px (sticky footer buttons, no horizontal overflow), tap targets ≥40 px in note rows

## D — Interaction polish (mobile)

- [ ] **List animations** — task complete/delete snaps in/out; use `AnimatedList`/`AnimatedSwitcher` for card removal + strike-through transition (Dismissible already animates swipes)
- [ ] **Haptics consistency** — cards have them (`HapticFeedback.lightImpact`); add to FAB create-success, delete confirm, sheet snap
- [ ] **TaskFormSheet ergonomics** — drag handle, keyboard-avoidance check on small screens, dirty-dismiss confirm (same rule as web C-modal)
- [ ] **Notes page AppBar title hardcodes 'Заметки'** while web has ru/en — covered by i18n item E1, listed here so it's not missed

## E — Consistency & content

- [ ] **E1. i18n unification** — single biggest consistency win; mobile plan already in `mobile-tasks-parity.md` Gap 5 + `notes-v2/04`. Web also leaks hardcoded Russian inside English components: `TaskCard.svelte` `'${r.dayOfMonth}-го'`, `'до <month>'`; `TaskList.svelte` "Бэклог/Архив" buttons; `settings/+page.svelte` headers — route through `i18n.t()`
- [ ] **Date-format consistency (web)** — `TaskCard` formats with hardcoded `'en'` locale while the app may be in ru; use `i18n.locale` everywhere a date is rendered
- [ ] **Empty states** — good ones exist (notes, backlog); audit: archive, stats-no-data, filtered-to-empty (tag filter active → say "no tasks match the filter" + clear-filter action, web + mobile)
- [ ] **Page titles (web)** — no `<svelte:head><title>` per route; add ("Today — Locus", etc.); note pages get note content as title (notes-v2 N2 already specifies)
- [ ] **Status/outcome chip language** — web archive outcome labels are English ('Done on time'), mobile Russian ('выполнено') — same i18n sweep

## F — Auth & session QoL

- [ ] **Return-to URL after login** — 401 hard-redirects to `/login` (`client.ts`) losing location; store intended path, redirect back after login
- [ ] **Login/register form polish** — show/hide password toggle, autofocus first field, min-length hint on register, localized error messages (currently hardcoded Russian fallback 'Неверный email или пароль')
- [ ] **Graceful 401 during background refetch** (after A3 lands) — don't yank the user to login from a background tab refresh failure without a toast

## G — Dev QoL (supports everything above)

- [ ] **Dev date/time control widget** — already in backlog memory (`project_ideas.md`): floating dev-only widget to mock "now" for scheduler/rollover testing; becomes much more valuable once A1/A3 land (verifying midnight behavior without waiting for midnight)
- [ ] **Seed data refresh script** — verify `seed` covers all statuses/levels/recurring/tags/notes so every QoL state (overdue, backlog age, archive outcomes) is reproducible locally

---

## Suggested order

1. **A1 + A3** (`fix/local-today`) — correctness of the core loop, one branch
2. **A2** (`feat/web-task-delete-replan`) — closes the reversed parity gap
3. **A4 + B** (`feat/feedback-polish`) — mobile toasts, sync visibility, skeletons, pull-to-refresh
4. **C + D** (`feat/interaction-polish`) — shortcuts, undo, dirty guards, animations
5. **E + F** (`feat/consistency-i18n`) — string/date/title sweep, auth polish
6. **G** — alongside, when first needed for testing A1/A3

## Verification (Prove It, per branch)

- [ ] A1: set system TZ to UTC+5, local time 00:30 — web today page, sidebar counts, kanban highlight and stats all show the new local day; mobile agrees
- [ ] A3: leave tab open through an hour boundary with a due transition → UI updates on refocus
- [ ] A2: delete a task with archived periods → friendly 409 message; without → gone after reload
- [ ] A4: kill API, toggle a task on mobile → toast appears, outbox badge increments; restart API → badge clears
- [ ] `pnpm typecheck` + `flutter analyze` clean on every branch
