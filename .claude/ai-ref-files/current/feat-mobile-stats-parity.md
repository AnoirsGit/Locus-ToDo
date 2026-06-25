# Mobile stats parity (parity Gap 3)

> Branch: `feat/mobile-stats-parity` (off main). Closes `mobile-tasks-parity.md` Gap 3.
> No DB/schema/API changes — `yearHistory` was already parsed in `StatsResult`.

## What changed (stats_page.dart only)
- `_TrendRow` model (label/done/total/current) + label helpers (`_weekLabel` range,
  `_monthLabel`, `_yearLabel`) + `_trendColor` threshold helper (mirrors web `pctColor`:
  ≥80 success / ≥50 warning / >0 danger / else muted).
- `_StatsBody` now builds `_weekRows`/`_monthRows` with the **current snapshot prepended**
  as the first row (filtered to `total > 0 || current`, like web) and a new `_yearRows`
  from `data.yearHistory`. Three sections render: week trend, month trend, **year history**.
- `_TrendChart` rewritten to take `List<_TrendRow>`: per-row label (+ "сейчас" pill and
  bold for the current row), threshold-coloured bar, `pct%`, and `done/total` count —
  matching web's trend rows.
- `_ConsistencyRow` bar/pct switched to the threshold colour for consistency. The
  recurring-vs-completion split is preserved (consistency is its own section).

## Verification (Prove It)
- [x] `flutter analyze` clean (no new issues; total lints down 4 after const cleanup).
- [ ] Run app vs web for the same `?today=`: snapshot cards, current "сейчас" row,
      week/month/year rows and %/counts match. (needs emulator + API)
