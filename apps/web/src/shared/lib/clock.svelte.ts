import { localToday } from './date'

/**
 * Reactive "today". Views derive from `clock.today`/`clock.now` instead of
 * freezing `new Date()` at component init, so the app rolls over to the new
 * day when data is refetched (visibility refetch calls `refresh()`).
 */
const state = $state({ today: localToday() })

export const clock = {
  get today(): string {
    return state.today
  },
  /** Local midnight of the current day — for formatting (day name, week number). */
  get now(): Date {
    return new Date(`${state.today}T00:00:00`)
  },
  /** Returns true when the calendar day changed since the last refresh. */
  refresh(): boolean {
    const next = localToday()
    const changed = next !== state.today
    state.today = next
    return changed
  },
}
