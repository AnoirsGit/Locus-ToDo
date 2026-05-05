import type { TaskLevel } from '@locus/shared'

/** Given a period level and its start date (ISO YYYY-MM-DD), returns the period end date */
export const computePeriodEnd = (level: TaskLevel, periodStart: string): string => {
  const d = new Date(periodStart + 'T00:00:00Z')

  if (level === 'day') return periodStart

  if (level === 'week') {
    // periodStart should be Monday; end = Sunday (+6 days)
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
 * Compute the end of the penalty (overdue) period:
 * week → +1 week, month → +1 month, year → +1 year
 */
export const computePenaltyPeriodEnd = (level: TaskLevel, periodStart: string): string => {
  const d = new Date(periodStart + 'T00:00:00Z')

  if (level === 'week') {
    const start = new Date(d)
    start.setUTCDate(d.getUTCDate() + 7)
    return computePeriodEnd('week', start.toISOString().slice(0, 10))
  }

  if (level === 'month') {
    const start = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1))
    return computePeriodEnd('month', start.toISOString().slice(0, 10))
  }

  // year
  return `${d.getUTCFullYear() + 1}-12-31`
}
