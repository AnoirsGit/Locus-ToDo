# Mobile tasks parity — close the gap with web

> Created 2026-06-10 from a side-by-side audit of tasks UI: web (`apps/web`) vs mobile (`apps/mobile`).
> Companion to `notes-v2/04-mobile-parity.md` (notes-specific gaps live there).
> Updated 2026-07-28: re-audited against current code — Gaps 1-4 were already implemented
> (this doc had gone stale, not reflecting completed work); Gap 6's card/detail items were
> also already done. Gap 5 (i18n) is the one gap still substantially open.

## Audit verdict

Mobile tasks are in much better shape than mobile notes. Form sheet has full parity
(rich text, subtasks, tags, recurring incl. multi-day, replan, delete). Views exist
(Today / Week kanban / Month / Year + backlog/archive), progress card, collapsible
context sections with `storageKey`, drawer with per-level todo counts, theme modes,
notification prefs, tag management in settings. Mobile even has extras web lacks:
offline + outbox sync, push notifications, swipe-to-toggle with haptics, system theme.

Remaining gaps are below, priority order.

---

## Gap 1 — Tag filter bar missing on the main `/view` screen  ⭐ top gap

- Web: `TagFilterBar` sits in `(app)/+layout.svelte` → filtering applies to **every**
  view (today, week kanban day columns, month, year, context sections) via
  `tagStore.filterTasks(...)` in each derived list.
- Mobile: `_TagFilterBar` exists only in `tasks_page.dart` (backlog/archive).
  `view_tab_page.dart` (the primary screen) has **zero tag filtering** — neither the
  bar nor `filterTasks` calls.

**Todo**
- [x] Extract `_TagFilterBar` out of `tasks_page.dart` into a shared widget
      (e.g. `entities/tag/ui/tag_filter_bar.dart` per FSD; tag state already lives in
      `shared/providers/tag_store.dart`). — done: `entities/task/ui/tag_filter_bar.dart`.
- [x] Render it in `view_tab_page.dart` below the view dropdown (all views). — present in
      `_TodayBody`, `_WeekKanban`, `_GenericBody` (verified via grep, 3 call sites).
- [x] Apply `tagState.filterTasks(...)` in `_TodayBody` (day list + week/month/year
      context sections), `_WeekKanban` (day columns + week strip + context), `_GenericBody`.
      — verified: `filterTasks` called on primary/week/month/year lists in all three bodies.
- [x] Filter state is global (`tagStoreProvider`) — verified consistent across
      view ⇄ backlog/archive (single global provider, no per-page duplication).

## Gap 2 — Subtasks not reachable from task cards

- Web `TaskCard.svelte`: "Subtasks" expander on every non-archived/backlog card →
  lazy-loads `SubtaskChecklist` (`GET /api/tasks/:id/subtasks`), toggle + inline add
  without opening the editor.
- Mobile `task_card.dart`: nothing; subtasks only visible after opening
  `TaskFormSheet` (edit mode), and there is no subtask count hint on the card.

**Todo**
- [x] New `entities/task/ui/subtask_checklist.dart` — port of web `SubtaskChecklist`
      (lazy fetch on expand, optimistic toggle via period id, inline add field, delete). — done.
- [x] Add an expander row to `task_card.dart` (chevron + "Subtasks"), hidden for
      `archived`/`backlog` statuses — same rule as web. — done, `_SubtaskSection`.
- [x] Keep it lazy: fetch only on first expand (mirror web to avoid N+1 on lists). — done,
      `subtasksProvider` is `FutureProvider.autoDispose.family`.
- [x] API already exists (`getSubtasks` is in `tasks_api.dart`) — no backend work.

## Gap 3 — Stats screen missing the year section + "current" trend rows

- Web `stats/+page.svelte`: snapshot cards, week trend, month trend **with the
  current period prepended as the first row** (`current: true`), and a **year history**
  section from `data.yearHistory`.
- Mobile `stats_page.dart`: snapshot cards (incl. a year card) + week/month
  `_TrendChart` — **no year history list, no prepended current row**.

**Todo**
- [x] Add year history section (`data.yearHistory` is already in the API payload —
      check `StatsDto` parsing in mobile; add the field if dropped). — done, rendered when
      `data.yearHistory.isNotEmpty`.
- [x] Prepend the current week/month snapshot as the first trend row, visually marked
      (web uses a `current` flag — replicate the emphasis). — done, `_TrendRow(current: true)`
      with distinct text color/weight for `isCurrent`.
- [x] Verify Consistency % vs Completion % split renders identically to web
      (recurring vs non-recurring must never be mixed — product rule). — spot-checked
      `stats_page.dart`, matches web's split; no further action.

## Gap 4 — Kanban day columns: create is not date-bound, no quick add

- Web `DayColumn.svelte`: inline quick-create (type a title → creates a `day` task
  for **that column's date**) + "open full modal" with `defaultPeriodStart = column date`.
- Mobile `_DayColumn`: the "+ Add task" button calls the **global** `_openCreate(view)`
  → `periodStart` is today/this week, not the tapped column's date.

**Todo**
- [x] Thread the column date through: `_WeekKanban` → `_DayColumn(onCreate)` becomes
      `onCreate(String dateStr)` → `TaskFormSheet` with `defaultLevel: day`,
      `defaultPeriodStart: dateStr`. — done, `_openCreateForDate`/`onCreateDay` wired through.
- [ ] Optional (full parity): inline quick-add text field at the bottom of each column
      (submit → `createTask({title, level: 'day', periodStart: date})`, no sheet). — not done,
      still opens the sheet (correct date now); true inline quick-add is a nice-to-have, low
      priority, left open.

## Gap 5 — i18n: no language switch, hardcoded mixed-language strings

- Web: `i18n` store, ru/en toggle in `Sidebar`, all task views localized.
- Mobile: Russian hardcoded in nav/cards/views ('Просмотр', 'Задачи недели',
  'просрочено'…), English hardcoded in settings ('Notifications', 'Edit profile') —
  no switch at all.

**Todo**
- [x] Minimal `shared/lib/strings.dart` (ru/en keyed table mirroring web `i18n` keys)
      + locale provider persisted in SharedPreferences. — table exists
      (`shared/core/strings.dart`, `S.*`), but it follows the OS locale
      (`PlatformDispatcher.instance.locale`) rather than a user-facing in-app switch — see
      next item, still open.
- [ ] Language row in Settings (matches web's sidebar toggle). — not started; `S._ru` has
      no override hook yet, needs a persisted preference + a settings row to flip it.
- [ ] Sweep tasks-related strings first (view_tab, tasks_page, task_card, form sheet,
      stats, drawer, bottom nav); notes strings are covered by `notes-v2/04`.
      — partial: `task_card.dart` and `subtask_checklist.dart` fully swept onto `S.*`
      (2026-07-28). Confirmed still hardcoded (not yet swept): `tasks_page.dart`
      (`_titles`, `_contextTitles`, `_emptyPrimary`/`_emptyFiltered` copy), `view_tab_page.dart`,
      `task_form_sheet.dart`, `stats_page.dart`, `app_drawer.dart`, `app_shell.dart` nav
      labels (see bugs.md's "Mobile notes AppBar title" item — 3 of 4 nav labels still
      plain strings), `settings_page.dart`.

## Gap 6 — Small card/detail mismatches (batch, low effort)

- [x] Archived card: web shows period label + done-at date next to the outcome chip;
      mobile shows only the outcome chip — add period + date. — done, `TaskCard` shows
      `_periodLabel()` + `_doneAtLabel()` chips next to the outcome chip when archived.
- [x] Backlog card: web shows period label + backlog age ("3 days ago"); mobile —
      verify and add if missing. — done, `_periodLabel()` + `_backlogAge()` chips present.
- [x] Recurring chip day-order: mobile sorts plainly with a Sun-last hack; web sorts
      Mon-first explicitly — unify (extract one shared rule, Mon-first). — done,
      `_recurringLabel()` already sorts Mon-first (`monFirst` filter on the sorted list).
- [ ] Empty states: web has copy ("keep going" on backlog); align mobile copy via i18n keys.
      — still open: `tasks_page.dart`'s `_emptyPrimary` shows plain "Нет задач" for every
      view, no backlog-specific "keep going" subtitle (web: `common.empty` + `common.keep_going`
      only for `view === 'backlog'`), and the string itself is hardcoded Russian, not yet
      routed through `S.*` — folds into the Gap 5 sweep of this same file, not split out.

---

## Explicit non-gaps (do not "fix")

- Card tap = edit on mobile (web uses a hover pencil — hover doesn't exist on touch).
- Swipe-to-toggle, haptics, offline outbox, push notifications, system theme — mobile-only strengths; web parity for those is a different conversation.
- Web settings "recurring management" section is a stub ("в разработке") — nothing to port.

## Suggested order / branches

1. `feat/mobile-tag-filter` — Gap 1 (biggest daily-use win, small code)
2. `feat/mobile-subtasks-card` — Gap 2
3. `feat/mobile-stats-parity` — Gap 3
4. `feat/mobile-kanban-quickadd` — Gap 4
5. `feat/mobile-i18n` — Gap 5 (+ Gap 6 batched in)

## Verification (Prove It, each branch)

- [ ] `flutter analyze` clean.
- [ ] Same account web + mobile side by side: identical task lists under an active tag filter on every view.
- [ ] Subtask toggle on mobile card reflects on web after reload (and vice versa).
- [ ] Stats numbers match web exactly for the same `?today=` date.
- [ ] Kanban column add creates the task on the tapped date (check `period_start` via API).
