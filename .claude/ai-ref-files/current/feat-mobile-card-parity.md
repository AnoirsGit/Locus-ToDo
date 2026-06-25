# feat/mobile-card-parity — Gap 6: small card/detail mismatches

> Closes Gap 6 of `mobile-tasks-parity.md`. Mirrors web `TaskCard.svelte` +
> `TaskList.svelte` empty states on mobile. Pure UI/format work — no API, no schema.

## Reference (web)

- `apps/web/src/entities/task/ui/TaskCard.svelte` — `periodLabel`, `doneAtLabel`,
  `backlogAge`, Mon-first day sort, archived/backlog meta blocks.
- `apps/web/src/widgets/task-list/TaskList.svelte` (L105-106) — empty-state copy.

## Plan

### 1. Shared Mon-first day-order rule (item 3)
- [x] New `apps/mobile/lib/shared/core/recurring.dart` →
      `sortDaysMonFirst(Iterable<int>)` = `[...days]..sort((a,b) => (a==0?7:a)-(b==0?7:b))`
      (identical algorithm to web's comparator).
- [x] Replace the Sun-last hack in `task_card.dart:37-38` and
      `view_tab_page.dart:1037-1038` with the shared helper.

### 2. Archived card: period label + done-at date (item 1)
- [x] Add `_periodLabel()` to `task_card.dart` — day "5 янв" / week "5 янв – 11 янв"
      / month "<short-month> 2024" / year "2024", using existing `_monthNames`.
- [x] Add `_doneAtLabel()` — "7 янв 2024".
- [x] In the `isArchived` meta block: prepend the period-label chip, append a dimmed
      done-at chip after the outcome chip. Keep existing outcome wording unchanged.

### 3. Backlog card: period label + age (item 2)
- [x] Add `_backlogAge()` mirroring web (сегодня / день назад / N дней назад /
      мес. назад / N мес. назад) from `period.backlogAt`.
- [x] In the non-archived meta branch add `if (isBacklog)` → period-label + age chips.

### 4. Empty-state copy (item 4) — `tasks_page.dart` (backlog/archive screens)
- [x] Thread `view` into `_Empty` + `_emptyPrimary`.
- [x] Title: backlog/archive → 'Чисто', otherwise 'Нет задач'.
- [x] Body: backlog → 'Продолжай в том же духе.' (otherwise none).
- [x] Note: hardcoded ru copy (matches web ru locale); folds into the i18n table at
      Gap 5. `view_tab` active-view empty ("Нет задач") already matches web — leave it.

## Verify
- [x] `flutter analyze` clean — no new issues.
- [x] Archived card shows period + outcome + done-at date.
- [x] Backlog card shows period + age.
- [x] Recurring week chip day order is Mon-first on both the card and the view-tab meta.
- [x] Backlog empty state shows "Чисто" + "Продолжай в том же духе.".

## Lessons
(add after user corrections)
