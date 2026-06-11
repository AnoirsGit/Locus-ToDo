# Mobile tasks parity — close the gap with web

> Created 2026-06-10 from a side-by-side audit of tasks UI: web (`apps/web`) vs mobile (`apps/mobile`).
> Companion to `notes-v2/04-mobile-parity.md` (notes-specific gaps live there).
> Plan only — implementation not started.

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
- [ ] Extract `_TagFilterBar` out of `tasks_page.dart` into a shared widget
      (e.g. `entities/tag/ui/tag_filter_bar.dart` per FSD; tag state already lives in
      `shared/providers/tag_store.dart`).
- [ ] Render it in `view_tab_page.dart` below the view dropdown (all views).
- [ ] Apply `tagState.filterTasks(...)` in `_TodayBody` (day list + week/month/year
      context sections), `_WeekKanban` (day columns + week strip + context), `_GenericBody`.
- [ ] Filter state is global (`tagStoreProvider`) — verify it stays consistent when
      switching view ⇄ backlog/archive (web behaves globally; match that).

## Gap 2 — Subtasks not reachable from task cards

- Web `TaskCard.svelte`: "Subtasks" expander on every non-archived/backlog card →
  lazy-loads `SubtaskChecklist` (`GET /api/tasks/:id/subtasks`), toggle + inline add
  without opening the editor.
- Mobile `task_card.dart`: nothing; subtasks only visible after opening
  `TaskFormSheet` (edit mode), and there is no subtask count hint on the card.

**Todo**
- [ ] New `entities/task/ui/subtask_checklist.dart` — port of web `SubtaskChecklist`
      (lazy fetch on expand, optimistic toggle via period id, inline add field, delete).
- [ ] Add an expander row to `task_card.dart` (chevron + "Subtasks"), hidden for
      `archived`/`backlog` statuses — same rule as web.
- [ ] Keep it lazy: fetch only on first expand (mirror web to avoid N+1 on lists).
- [ ] API already exists (`getSubtasks` is in `tasks_api.dart`) — no backend work.

## Gap 3 — Stats screen missing the year section + "current" trend rows

- Web `stats/+page.svelte`: snapshot cards, week trend, month trend **with the
  current period prepended as the first row** (`current: true`), and a **year history**
  section from `data.yearHistory`.
- Mobile `stats_page.dart`: snapshot cards (incl. a year card) + week/month
  `_TrendChart` — **no year history list, no prepended current row**.

**Todo**
- [ ] Add year history section (`data.yearHistory` is already in the API payload —
      check `StatsDto` parsing in mobile; add the field if dropped).
- [ ] Prepend the current week/month snapshot as the first trend row, visually marked
      (web uses a `current` flag — replicate the emphasis).
- [ ] Verify Consistency % vs Completion % split renders identically to web
      (recurring vs non-recurring must never be mixed — product rule).

## Gap 4 — Kanban day columns: create is not date-bound, no quick add

- Web `DayColumn.svelte`: inline quick-create (type a title → creates a `day` task
  for **that column's date**) + "open full modal" with `defaultPeriodStart = column date`.
- Mobile `_DayColumn`: the "+ Add task" button calls the **global** `_openCreate(view)`
  → `periodStart` is today/this week, not the tapped column's date.

**Todo**
- [ ] Thread the column date through: `_WeekKanban` → `_DayColumn(onCreate)` becomes
      `onCreate(String dateStr)` → `TaskFormSheet` with `defaultLevel: day`,
      `defaultPeriodStart: dateStr`.
- [ ] Optional (full parity): inline quick-add text field at the bottom of each column
      (submit → `createTask({title, level: 'day', periodStart: date})`, no sheet).

## Gap 5 — i18n: no language switch, hardcoded mixed-language strings

- Web: `i18n` store, ru/en toggle in `Sidebar`, all task views localized.
- Mobile: Russian hardcoded in nav/cards/views ('Просмотр', 'Задачи недели',
  'просрочено'…), English hardcoded in settings ('Notifications', 'Edit profile') —
  no switch at all.

**Todo**
- [ ] Minimal `shared/lib/strings.dart` (ru/en keyed table mirroring web `i18n` keys)
      + locale provider persisted in SharedPreferences.
- [ ] Language row in Settings (matches web's sidebar toggle).
- [ ] Sweep tasks-related strings first (view_tab, tasks_page, task_card, form sheet,
      stats, drawer, bottom nav); notes strings are covered by `notes-v2/04`.

## Gap 6 — Small card/detail mismatches (batch, low effort)

- [ ] Archived card: web shows period label + done-at date next to the outcome chip;
      mobile shows only the outcome chip — add period + date.
- [ ] Backlog card: web shows period label + backlog age ("3 days ago"); mobile —
      verify and add if missing.
- [ ] Recurring chip day-order: mobile sorts plainly with a Sun-last hack; web sorts
      Mon-first explicitly — unify (extract one shared rule, Mon-first).
- [ ] Empty states: web has copy ("keep going" on backlog); align mobile copy via i18n keys.

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
