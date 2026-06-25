# Mobile tag filter on the main view (parity Gap 1)

> Branch: `feat/mobile-tag-filter` (off main). Closes `mobile-tasks-parity.md` Gap 1.
> No DB/schema changes. The web `TagFilterBar` sits in `(app)/+layout.svelte` and
> filters every view; mobile only had it on backlog/archive (`tasks_page.dart`).

## What changed
- New `entities/tag/ui/tag_filter_bar.dart` — `TagFilterBar` `ConsumerWidget` reading
  `tagStoreProvider` directly (no prop drilling; matches the `TaskCard` arch decision).
  Renders `SizedBox.shrink()` when no tags. Clear button → `S.clearFilter` (i18n).
- `view_tab_page.dart` — in the `data:` builder, build a filtered `GroupedTasks`
  (`tagState.filterTasks` on primary + week/month/year) + filtered kanban `dayTasks`,
  then render `Column[ TagFilterBar, Expanded(RefreshIndicator(switch(view))) ]`. Every
  body renders from the filtered data, so day list / kanban columns+strip+context /
  month+year body / progress card all reflect the filter — same as web (web derives
  progress from the filtered `todayTasks`, verified in `today/+page.svelte`).
- `tasks_page.dart` — swapped to the shared `TagFilterBar`, deleted the local
  `_TagFilterBar`.
- Filter state is global (`tagStoreProvider`) → consistent across view ⇄ backlog/archive
  for free.

## Verification (Prove It)
- [x] `flutter analyze` clean (no new issues; 4 pre-existing warnings in untouched files).
- [ ] Run app: select a tag on `/view` → today/week-kanban/month/year all filter; progress
      card reflects the filtered set; clear restores; filter persists into backlog/archive.
      (needs emulator + API)
