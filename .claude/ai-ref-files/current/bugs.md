# Known bugs — consolidated (2026-06-11)

> Canonical bug list. Extracted from `qol-polish.md` §A (now a pointer here) plus
> minor bugs from its §C/§E and the outstanding notes-v2 manual QA.
> Every item verified in the repo; no DB/schema changes required for any fix.

---

## Critical UX-level bugs (feel like a broken product — fix first)

### B1. "Today" is computed in UTC on web ⭐
`toISOString().split('T')[0]` is used for "today"/date keys across web:
`(app)/+layout.svelte`, `today/+page.svelte`, `Sidebar.svelte` (nav counts),
`WeekView.svelte`, `DayColumn.svelte`, `TaskList.svelte`, `CreateTaskForm.svelte`,
`stats/+page.svelte`. For a UTC+ user (e.g. UTC+5), between local midnight and UTC
midnight the whole app shows **yesterday**: wrong today list, wrong kanban highlight,
wrong stats `?today=`. Mobile uses local `DateTime.now()` components → web and mobile
disagree at night.
- [x] Add `shared/lib/date.ts`: `localToday()`, `toLocalISO(d)` + `weekStartISO`/`monthStartISO`/`yearStartISO` (dedups Monday/month-start math from 4 components); reactive `clock.svelte.ts` (`clock.today`/`clock.now`/`refresh()`)
- [x] Replace every `toISOString().split('T')[0]` call used as a *calendar date* (layout, today, stats, Sidebar, WeekView, DayColumn, TaskList, CreateTaskForm; stats string-math helpers kept — they parse ISO as UTC and format with `timeZone: 'UTC'`, correct)
- [ ] Same helper on mobile for consistency (`shared/lib/date_utils.dart`) — deferred until B4 branch merges (same files)

### B2. Web cannot delete or replan tasks
`tasksApi.remove` and `tasksApi.replan` exist in `entities/task/api/tasks.api.ts` but
are referenced by **zero UI components**. Mobile has both (confirm dialog + replan in
`TaskFormSheet`). Web users literally cannot delete a task.
- [ ] Delete button (danger) in `EditTaskForm` footer + confirm dialog; handle the 409 ("task has archived periods") with a clear message — API contract: hard delete blocked then
- [ ] Replan action in `EditTaskForm` for backlog tasks (web parity with mobile `_replan`): pick new period, POST `/tasks/:id/replan`, store update

### B3. Stale data: nothing ever refetches
Scheduler transitions run hourly server-side (`node-cron`, `0 * * * *`); clients load
once on mount. A tab/app left open across midnight or an hourly tick shows stale
statuses; "today" never rolls over. No `visibilitychange` / `AppLifecycleState`
handling anywhere.
- [x] Web: on `document.visibilitychange` → visible (throttled ≥60 s since last load): `loadAll()` refetch in `(app)/+layout.svelte`
- [ ] Mobile: on `AppLifecycleState.resumed`: same (notifiers already have `refresh()`) — deferred until B4 branch merges (same files)
- [x] Recompute "today"/week window on refetch — `clock.refresh()` in `loadAll()`; today page, Sidebar, WeekView now `$derived` from `clock`

### B4. Mobile errors are swallowed silently
No `SnackBar`/`ScaffoldMessenger` usage in the entire app. `tasks_notifier.dart`,
`sync_worker.dart`, notes notifier — all `catch (_) {}`. A failed create/toggle just
silently reverts (or worse, doesn't).
- [ ] Minimal toast service (`shared/ui/app_toast.dart`, ScaffoldMessenger-based) — mirror web `toastStore` semantics
- [ ] Wire into task/notes/tags mutation error paths (non-auth failures), like web's API client does
- [ ] Sync outbox: surface "N changes pending sync" + a failed-sync indicator (badge in app bar or settings row) — outbox exists, user has zero visibility

---

## Minor bugs

- [ ] **TaskModal discards edits silently** — Escape and backdrop click call `onClose` with no dirty check; unsaved edits vanish instantly
- [ ] **Focus escapes the modal** — `aria-modal` is set on `TaskModal` but there is no focus trap; Tab walks out of the dialog, and focus is not returned to the opener on close
- [ ] **Date format hardcoded `'en'` locale (web)** — `TaskCard` formats dates with `'en'` while the app may be in ru; should use `i18n.locale` everywhere a date is rendered
- [ ] **Hardcoded Russian inside English-localized web components** — `TaskCard.svelte` (`'${r.dayOfMonth}-го'`, `'до <month>'`), `TaskList.svelte` ("Бэклог/Архив" buttons), `settings/+page.svelte` headers — must route through `i18n.t()`
- [ ] **Archive outcome chip language mismatch** — web shows English ('Done on time'), mobile Russian ('выполнено') for the same state
- [ ] **Mobile notes AppBar title hardcodes 'Заметки'** — web is ru/en localized; mobile strings table exists (`shared/core/strings.dart`) but this title bypasses it
- [ ] **Login error fallback hardcoded Russian** — 'Неверный email или пароль' regardless of locale
- [ ] **Double-submit guards unverified** — auth pages disable while in flight; Create/Edit task forms and note inputs need the same audit

---

## Pending manual QA (notes-v2 — implemented, never verified live)

Static checks pass (web `tsc` clean, `flutter analyze` clean); these need a running app
(DB + API were down when N1–N6 landed). Any failure here is a new bug for this file.

- [ ] Web: select-all text → Delete removes node; type-then-delete shows no "Note not found"; Enter→Backspace leaves no ghost
- [ ] Web: reload on a zoomed `/notes/[id]` restores it; back walks up; stale id redirects
- [ ] Mobile: same delete-in-edit + routing checks on device
- [ ] Web ↔ mobile round trip: a `heading1` with children created on one renders/edits correctly on the other; board shows the same columns/cards

---

## Verification (Prove It)

- [ ] B1: set system TZ to UTC+5, local time 00:30 — web today page, sidebar counts, kanban highlight and stats all show the new local day; mobile agrees
- [ ] B3: leave tab open through an hour boundary with a due transition → UI updates on refocus
- [ ] B2: delete a task with archived periods → friendly 409 message; without → gone after reload
- [ ] B4: kill API, toggle a task on mobile → toast appears, outbox badge increments; restart API → badge clears
- [ ] `pnpm typecheck` + `flutter analyze` clean on every branch
