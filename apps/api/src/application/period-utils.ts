import type { TaskLevel } from '@locus/shared'

/** Given a period level and its start date (ISO YYYY-MM-DD), returns the period end date */
export const computePeriodEnd = (level: TaskLevel, periodStart: string): string => {
  const d = new Date(periodStart + 'T00:00:00Z')

  if (level === 'day') return periodStart

  if (level === 'week') {
    // periodStart must be Monday; end = Sunday (+6 days)
    const end = new Date(d)
    end.setUTCDate(d.getUTCDate() + 6)
    return end.toISOString().slice(0, 10)
  }

  if (level === 'month') {
    // last day of the month
    const end = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0))
    return end.toISOString().slice(0, 10)
  }

  // year: Dec 31 of the same year
  return `${d.getUTCFullYear()}-12-31`
}

/**
 * Snap an arbitrary date to the Monday of its ISO week.
 * Used to normalise periodStart for week-level tasks.
 */
export const toMonday = (isoDate: string): string => {
  const d = new Date(isoDate + 'T00:00:00Z')
  const dow = d.getUTCDay() // 0=Sun … 6=Sat
  const daysFromMon = dow === 0 ? 6 : dow - 1
  const monday = new Date(d)
  monday.setUTCDate(d.getUTCDate() - daysFromMon)
  return monday.toISOString().slice(0, 10)
}

/**
 * Returns the start of the CURRENT period for a given level relative to today.
 * week  → this week's Monday
 * month → first of this month
 * year  → Jan 1 of this year
 * day   → today
 */
export const currentPeriodStart = (level: TaskLevel, today: string): string => {
  const d = new Date(today + 'T00:00:00Z')
  if (level === 'week')  return toMonday(today)
  if (level === 'month') return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1)).toISOString().slice(0, 10)
  if (level === 'year')  return `${d.getUTCFullYear()}-01-01`
  return today
}
