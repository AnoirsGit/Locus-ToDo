// Dev-only time override — lets you mock "now" for scheduler/view testing.
// Only active when import.meta.env.DEV is true.
// Persisted to localStorage so it survives page reloads.

const STORAGE_KEY = 'dev_time_override'

function loadFromStorage(): Date | null {
  if (typeof localStorage === 'undefined') return null
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  const d = new Date(raw)
  return isNaN(d.getTime()) ? null : d
}

function createDevTimeStore() {
  let override = $state<Date | null>(loadFromStorage())

  return {
    get override() { return override },

    set(date: Date | null) {
      override = date
      if (typeof localStorage !== 'undefined') {
        if (date) {
          localStorage.setItem(STORAGE_KEY, date.toISOString())
        } else {
          localStorage.removeItem(STORAGE_KEY)
        }
      }
    },

    /** Returns the mocked date if set, otherwise real now */
    now(): Date {
      return override ?? new Date()
    },

    reset() {
      this.set(null)
    },
  }
}

export const devTime = createDevTimeStore()
