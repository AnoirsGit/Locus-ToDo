import { api } from './client'

export type PeriodStat = { periodStart: string; done: number; total: number }

export type StatsData = {
  snapshot: {
    today:  { done: number; total: number; overdue: number }
    week:   { done: number; total: number; overdue: number }
    month:  { done: number; total: number }
    year:   { done: number; total: number }
  }
  weekTrend:   PeriodStat[]
  monthTrend:  PeriodStat[]
  yearHistory: PeriodStat[]
  consistency: { done: number; total: number }
}

export const statsApi = {
  get: (today?: string) => {
    const qs = today ? `?today=${today}` : ''
    return api.get<StatsData>(`/stats${qs}`)
  },
}
