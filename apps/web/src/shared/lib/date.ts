/**
 * Calendar-date helpers based on LOCAL time.
 *
 * Never use `toISOString().split('T')[0]` for calendar dates: it converts to
 * UTC first, so between local midnight and UTC midnight the date is yesterday
 * for UTC+ users. Timestamps sent to the API as instants stay `toISOString()`.
 */

export const toLocalISO = (d: Date): string => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export const localToday = (): string => toLocalISO(new Date())

/** Monday of the week containing `d` (local). */
export const weekStartISO = (d: Date): string => {
  const r = new Date(d)
  const dow = r.getDay()
  r.setDate(r.getDate() - (dow === 0 ? 6 : dow - 1))
  return toLocalISO(r)
}

export const monthStartISO = (d: Date): string =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`

export const yearStartISO = (d: Date): string => `${d.getFullYear()}-01-01`
