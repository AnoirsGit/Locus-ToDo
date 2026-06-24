# Web i18n — task surface consistency (batch 1)

> Closes the web-side i18n leaks from `bugs.md` "Minor bugs" on the highest-traffic
> task UI. Every listed string currently renders in ONE language regardless of the
> active locale (or dates always render in English). No DB/schema changes.

## Scope (this batch)

Task cards, task list header, create form — the screens users see constantly.

## Plan

- [x] `shared/lib/i18n/dictionaries.ts` — add keys (ru + en):
  - `level_short` { day, week, month, year } — compact badge labels
  - `action.create` — create-task submit button
  - `task.until` — year deadline prefix ("до" / "until")
  - `task.subtasks` — card subtasks expander label
- [x] `entities/task/ui/TaskLevelBadge.svelte` — use `i18n.t('level_short.*')` instead of hardcoded Russian
- [x] `features/create-task/ui/CreateTaskForm.svelte` — Cancel → `action.cancel`, Create → `action.create`
- [x] `widgets/task-list/TaskList.svelte` — Backlog/Archive/Add buttons → `nav.backlog` / `nav.archive` / `action.add`
- [x] `entities/task/ui/TaskCard.svelte`:
  - [x] `fmt` / `fmtMonth` / `doneAtLabel` date locale `'en'`/`undefined` → `i18n.locale`
  - [x] `outcomeLabel` → `i18n.t('outcome.*')` (keep ✓/✗ symbols)
  - [x] recurring weekday abbreviations → localized via `Intl` (drop Russian-only `DAY_NAMES_SHORT`)
  - [x] recurring day-of-month label → locale-aware ("15-го" / "day 15")
  - [x] `deadlineLabel` → `i18n.t('task.until')` + localized short month
  - [x] `targetDayLabel` → localized weekday via `Intl`
  - [x] `backlogAge` → `i18n.t('backlog.*')` (dict was designed for exactly this)
  - [x] checkbox/edit `aria-label`s + "Subtasks" label → i18n

## Verification (Prove It)

- [x] `pnpm typecheck` clean; `svelte-check` 0 errors (27 pre-existing warnings, none from this change)
- [ ] Switch locale ru⇄en in the running app: every touched label and date flips language (manual)

## Batch 2 — week kanban header (DONE, shipped)

- [x] `widgets/week-view/ui/DayColumn.svelte` weekday header → locale-aware `Intl`
- [x] `widgets/week-view/WeekView.svelte` — drop unused `MONTH_NAMES_SHORT` import

## Batch 3 — settings / profile / auth errors (DONE, shipped)

- [x] `settings/+page.svelte` — all headers via new `settings.*` dict keys (was mixed ru/en)
- [x] `features/update-profile/ui/ProfileForm.svelte` — labels/placeholder/buttons/states/error via i18n
- [x] `login/+page.svelte` + `register/+page.svelte` — error fallbacks via `auth.error_*`
- Added dict keys: `action.saving/saved/save_error`, `auth.name_placeholder/error_invalid/error_register`, `settings.*`

## Still deferred (needs product/copy decision, not a clear bug)

- Full **auth-page** localization (login/register brand copy: pull-quote, titles, field
  labels, button text). Pages are Russian-first with no language toggle; localizing the
  brand voice needs the user's English wording. Only the error fallbacks were fixed.
- `DAY_NAMES_SHORT` / `MONTH_NAMES_SHORT` constants are now dead (Russian-only, no live
  refs) — left in place; deleting is a separate cleanup outside the i18n scope.
