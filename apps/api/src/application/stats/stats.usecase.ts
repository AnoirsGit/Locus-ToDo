import { db } from '../../infrastructure/db/client.js'
import { currentPeriodStart } from '../period-utils.js'

export type PeriodStat = { periodStart: string; done: number; total: number }

export type StatsResult = {
  snapshot: {
    today:  { done: number; total: number; overdue: number }
    week:   { done: number; total: number; overdue: number }
    month:  { done: number; total: number }
    year:   { done: number; total: number }
  }
  weekTrend:   PeriodStat[]  // last 10 archived weeks + current
  monthTrend:  PeriodStat[]  // last 6 archived months + current
  yearHistory: PeriodStat[]  // all archived years
}

export const statsUseCase = async (userId: string, today: string): Promise<StatsResult> => {
  const weekStart  = currentPeriodStart('week', today)
  const monthStart = currentPeriodStart('month', today)
  const yearStart  = currentPeriodStart('year', today)

  // ── Snapshot: active periods ──────────────────────────────────────────────

  const [snapDay] = await db<{ done: number; total: number; overdue: number }[]>`
    SELECT
      COUNT(*) FILTER (WHERE status IN ('todo','done','overdue'))::int       AS total,
      COUNT(*) FILTER (WHERE status = 'done')::int                           AS done,
      COUNT(*) FILTER (WHERE status = 'overdue')::int                        AS overdue
    FROM task_periods
    WHERE user_id    = ${userId}
      AND period_type = 'day'
      AND status     IN ('todo','done','overdue')
      AND (target_date = ${today}::date OR period_start = ${today}::date)
  `

  const [snapWeek] = await db<{ done: number; total: number; overdue: number }[]>`
    SELECT
      COUNT(*) FILTER (WHERE status IN ('todo','done','overdue'))::int       AS total,
      COUNT(*) FILTER (WHERE status = 'done')::int                           AS done,
      COUNT(*) FILTER (WHERE status = 'overdue')::int                        AS overdue
    FROM task_periods
    WHERE user_id     = ${userId}
      AND period_type  = 'week'
      AND period_start = ${weekStart}::date
      AND status       IN ('todo','done','overdue')
  `

  const [snapMonth] = await db<{ done: number; total: number }[]>`
    SELECT
      COUNT(*) FILTER (WHERE status IN ('todo','done','overdue'))::int AS total,
      COUNT(*) FILTER (WHERE status = 'done')::int                     AS done
    FROM task_periods
    WHERE user_id     = ${userId}
      AND period_type  = 'month'
      AND period_start = ${monthStart}::date
      AND status       IN ('todo','done','overdue')
  `

  const [snapYear] = await db<{ done: number; total: number }[]>`
    SELECT
      COUNT(*) FILTER (WHERE status IN ('todo','done','overdue'))::int AS total,
      COUNT(*) FILTER (WHERE status = 'done')::int                     AS done
    FROM task_periods
    WHERE user_id     = ${userId}
      AND period_type  = 'year'
      AND period_start = ${yearStart}::date
      AND status       IN ('todo','done','overdue')
  `

  // ── Historical trends (archived only) ────────────────────────────────────

  const weekTrendRaw = await db<{ period_start: string; done: number; total: number }[]>`
    SELECT
      period_start::text,
      COUNT(*) FILTER (WHERE done_at IS NOT NULL)::int AS done,
      COUNT(*)::int                                     AS total
    FROM task_periods
    WHERE user_id    = ${userId}
      AND period_type = 'week'
      AND status      = 'archived'
    GROUP BY period_start
    ORDER BY period_start DESC
    LIMIT 10
  `

  const monthTrendRaw = await db<{ period_start: string; done: number; total: number }[]>`
    SELECT
      period_start::text,
      COUNT(*) FILTER (WHERE done_at IS NOT NULL)::int AS done,
      COUNT(*)::int                                     AS total
    FROM task_periods
    WHERE user_id    = ${userId}
      AND period_type = 'month'
      AND status      = 'archived'
    GROUP BY period_start
    ORDER BY period_start DESC
    LIMIT 6
  `

  const yearHistoryRaw = await db<{ period_start: string; done: number; total: number }[]>`
    SELECT
      period_start::text,
      COUNT(*) FILTER (WHERE done_at IS NOT NULL)::int AS done,
      COUNT(*)::int                                     AS total
    FROM task_periods
    WHERE user_id    = ${userId}
      AND period_type = 'year'
      AND status      = 'archived'
    GROUP BY period_start
    ORDER BY period_start DESC
  `

  return {
    snapshot: {
      today:  { done: snapDay.done,   total: snapDay.total,   overdue: snapDay.overdue },
      week:   { done: snapWeek.done,  total: snapWeek.total,  overdue: snapWeek.overdue },
      month:  { done: snapMonth.done, total: snapMonth.total },
      year:   { done: snapYear.done,  total: snapYear.total },
    },
    weekTrend:   weekTrendRaw.map(r => ({ periodStart: r.period_start, done: r.done, total: r.total })),
    monthTrend:  monthTrendRaw.map(r => ({ periodStart: r.period_start, done: r.done, total: r.total })),
    yearHistory: yearHistoryRaw.map(r => ({ periodStart: r.period_start, done: r.done, total: r.total })),
  }
}
