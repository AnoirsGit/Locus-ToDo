# Mobile kanban date-bound create + quick-add (parity Gap 4)

> Branch: `feat/mobile-kanban-quickadd` (off main). Closes `mobile-tasks-parity.md` Gap 4.
> No DB/schema/API changes.

## The bug
A kanban day column's "+ Add task" called the global create → made a **week** task on
Monday, not a **day** task on the tapped column's date.

## What changed (view_tab_page.dart only)
- Page: `_openCreateDay(dateStr)` (full sheet, `defaultLevel: day`, `defaultPeriodStart:
  dateStr`) and `_quickCreateDay(title, dateStr)` (`createTask({title, level:'day',
  periodStart})`). Both route through the `'day'` provider, which the week kanban watches
  (`dayTasks`), so the new card lands in the right column after the provider refreshes.
- `_WeekKanban` threads `onOpenCreateDay` / `onQuickCreateDay` to each column; the
  "Задачи недели" goals section still uses the unchanged week-level `onCreate`.
- `_DayColumn` is now stateful: "+ Add task" reveals an autofocus inline field (Enter →
  quick create for the column date; an `open_in_full` icon expands to the full sheet,
  bound to the same date). Mirrors web `DayColumn` (`onQuickCreate` / `onOpenModal`).
  Dropped `onTapOutside` (it would double-fire with the expand button).

## Verification (Prove It)
- [x] `flutter analyze` clean (no new issues; pre-existing baseline only).
- [ ] Run app: quick-add in a column → `period_start` == that column's date (check API);
      the card appears in that column; expand icon opens the sheet pre-set to the date.
      (needs emulator + API)
