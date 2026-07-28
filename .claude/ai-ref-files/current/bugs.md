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
- [x] Same helper on mobile for consistency (`shared/core/date_utils.dart` — mobile's `shared/` has no `lib/` subdir, used the existing `core/` convention instead) — `localIso`/`localToday`/`weekStartISO`/`monthStartISO`/`yearStartISO`, dedups the `iso(DateTime d) => d.toIso8601String().split('T')[0]` closures repeated across `tasks_page.dart`, `view_tab_page.dart`, `task_form_sheet.dart` (×2), `subtask_checklist.dart`. Note: mobile's `toIso8601String()` on local `DateTime`s was already correct (no UTC conversion happens for non-UTC `DateTime` instances, unlike JS's `Date.toISOString()`) — this was a dedup/consistency pass, not a bug fix on mobile.

### B2. Web cannot delete or replan tasks
`tasksApi.remove` and `tasksApi.replan` exist in `entities/task/api/tasks.api.ts` but
are referenced by **zero UI components**. Mobile has both (confirm dialog + replan in
`TaskFormSheet`). Web users literally cannot delete a task.
- [x] Delete button (danger) in `EditTaskForm` footer + inline confirm; 409 → localized "task has archived periods" message; `taskStore.removeByTaskId` drops all period entries
- [x] Replan action in `EditTaskForm` for backlog tasks (parity with mobile `_replan`): current period of the task's level, POST `/tasks/:id/replan`, old period → archived locally + new period upserted

### B3. Stale data: nothing ever refetches
Scheduler transitions run hourly server-side (`node-cron`, `0 * * * *`); clients load
once on mount. A tab/app left open across midnight or an hourly tick shows stale
statuses; "today" never rolls over. No `visibilitychange` / `AppLifecycleState`
handling anywhere.
- [x] Web: on `document.visibilitychange` → visible (throttled ≥60 s since last load): `loadAll()` refetch in `(app)/+layout.svelte`
- [x] Mobile: on `AppLifecycleState.resumed`: same (notifiers already have `refresh()`) — `AppShell.didChangeAppLifecycleState` (throttled ≥60 s since last load) invalidates `groupedTasksProvider` for day/week/month/year/backlog
- [x] Recompute "today"/week window on refetch — `clock.refresh()` in `loadAll()`; today page, Sidebar, WeekView now `$derived` from `clock`

### B4. Mobile errors are swallowed silently
No `SnackBar`/`ScaffoldMessenger` usage in the entire app. `tasks_notifier.dart`,
`sync_worker.dart`, notes notifier — all `catch (_) {}`. A failed create/toggle just
silently reverts (or worse, doesn't).
- [x] Minimal toast service (`shared/ui/app_toast.dart`, ScaffoldMessenger-based) — mirrors web `toastStore` semantics; wired into `AppShell` (`ref.listen(appToastProvider, ...)`)
- [x] Wire into task/notes/tags mutation error paths (non-auth failures) — `tasks_notifier.dart` create/update/delete already covered; `subtask_checklist.dart` (`_toggle`/`_add`) and `task_form_sheet.dart` (`_replan`, tag-save-on-submit) and `tag_store.dart` (`setNoteTags`) now show toasts too (were silently swallowing). Note: `notes_notifier.dart`'s own create/update/delete `.catchError` only fires for local (Drift) write failures — `OfflineNotesApi` deliberately never rethrows network failures (offline-first: queues to outbox instead), documented in `offline_notes_api.dart`.
- [x] Sync outbox: surface "N changes pending sync" + a failed-sync indicator — `AppShell`'s `_SyncBanner` now combines task + note outbox counts (`noteOutboxCountProvider` added, previously notes had zero visibility) and switches to a red "not synced, retrying..." style once any entry has failed at least once (`failedOutboxCountProvider`/`failedNoteOutboxCountProvider`, `attempts > 0`)

---

## Minor bugs

- [x] **TaskModal discards edits silently** — Create/Edit forms now expose a bindable `dirty`; `TaskModal.requestClose` confirms (`action.discard_confirm`) before closing on Escape / backdrop / Cancel / header-X when dirty
- [x] **Focus escapes the modal** — added `shared/lib/focusTrap.ts` (`use:trapFocus`): focuses first focusable on open (respects child autofocus), wraps Tab/Shift+Tab inside the dialog, restores focus to the opener on close
- [x] **Date format hardcoded `'en'` locale (web)** — `TaskCard` formats dates with `'en'` while the app may be in ru; should use `i18n.locale` everywhere a date is rendered. Verified already fixed: every `toLocaleDateString` call in `TaskCard.svelte` passes `i18n.locale` (weekday/month shorts, period label, done-at label) — no hardcoded `'en'` remains.
- [x] **Hardcoded Russian inside English-localized web components** — `TaskCard.svelte` (`'${r.dayOfMonth}-го'`, `'до <month>'`), `TaskList.svelte` ("Бэклог/Архив" buttons), `settings/+page.svelte` headers — must route through `i18n.t()`. Verified already fixed: `TaskCard.svelte`'s `-го` suffix is gated behind `i18n.locale === 'ru'` (correct per-locale branching, not a leak) and its deadline label uses `i18n.t('task.until')`; `TaskList.svelte`'s buttons use `i18n.t('nav.backlog')`/`i18n.t('nav.archive')`; `settings/+page.svelte` headers all use `i18n.t('settings.*')`. `grep -P "[а-яА-Я]"` across all three files finds nothing outside the intentional `-го` branch.
- [x] **Archive outcome chip language mismatch** — web shows English ('Done on time'), mobile Russian ('выполнено') for the same state. Added `S.outcomeOnTime`/`S.outcomeLate`/`S.outcomeFailed` to `strings.dart` (mirrors web's `outcome.*` dict keys/wording) and swapped the three hardcoded Russian literals in `task_card.dart`'s archive chips — both platforms now follow their own locale setting instead of one being locale-aware and the other hardcoded
- [x] **Mobile notes AppBar title hardcodes 'Заметки'** — web is ru/en localized; mobile strings table exists (`shared/core/strings.dart`) but this title bypassed it. `notes_page.dart` AppBar title already used `S.notes`; the real leak was the bottom-nav `NavigationDestination` label in `app_shell.dart` — now uses `S.notes` too. Other three nav labels (Статистика/Настройки/Просмотр) left as-is — no `S.*` keys exist yet, full sweep is mobile-tasks-parity Gap 5
- [x] **Login error fallback hardcoded Russian** — 'Неверный email или пароль' regardless of locale. Root cause was worse than the title: `shared/api/client.ts`'s generic 401 handler (session-expiry redirect) fires unconditionally, including for `/auth/login` itself, so a failed login always threw `ApiError(401, 'Unauthorized')` — the login page's `err.message ?? i18n.t('auth.error_invalid')` fallback was dead code, `err.message` was always truthy and always English. Fixed by dropping `err.message` entirely in `(auth)/login/+page.svelte`'s catch block; it now always shows the localized `auth.error_invalid` string. Left `client.ts`'s unconditional 401 handling itself alone (out of scope here — see new item below) since fixing it touches shared session-redirect logic used by every authenticated request, not just this string.
- [x] **New (found while fixing the item above): login attempts hit the generic 401→session-expired handler** — `client.ts`'s `request()` treats *any* 401 (even from `/auth/login` with a wrong password) as an expired session: it clears storage and does `window.location.href = '/login'` before the login page's own catch block finishes — a real login failure caused an extra reload/flash of the page it's already on. Fixed by excluding `/auth/login` and `/auth/register` from the session-expiry branch (mirrors the existing `/auth/` exclusion on the refresh-retry branch just above it); `/auth/me` and other authenticated `/auth/*` calls keep the real expiry-redirect behavior since they're not in the exclusion list. A 401 from `/auth/login` now falls through to the generic error branch (reads the backend's `error` field, fires `toastStore.error(...)`) — same toast-on-failure pattern the register form already had.
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

- [x] B1: verified live via Playwright `timezoneId: 'Etc/GMT+12'` (local date ≠ UTC date at run time) — today header "11 ИЮН", day fetches start `periodStart=2026-06-11`, kanban highlights `data-date="2026-06-11"`, stats `?today=2026-06-11`. Mobile-agrees check pending (B4 merge).
- [x] B3: dispatching `visibilitychange` inside the 60 s throttle → 0 requests; after 62 s → full 15-request refetch burst (10 day + week/month/year/backlog/archive)
- [x] B2: archived task delete → 409 + localized inline message (screenshot); fresh task delete → 204, gone after reload; backlog replan → 200, card left backlog (3→2). Found+fixed along the way: web client sent `Content-Type: application/json` on body-less DELETEs → Fastify 400 `FST_ERR_CTP_EMPTY_JSON_BODY` — **no web DELETE ever reached the API before** (subtask delete included)
- [ ] B4: kill API, toggle a task on mobile → toast appears, outbox badge increments; restart API → badge clears
- [ ] `pnpm typecheck` + `flutter analyze` clean on every branch (web branches: typecheck clean ✓)
