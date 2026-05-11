// Per-section collapse state — saved to localStorage, persists across refreshes.
// Cleared on logout (401) via client.ts.
// Key format: "view:section", e.g. "week:month", "today:year"
// Default: true (expanded). User toggles to collapse.

export const SECTION_PREFS_KEY = 'section_prefs'

function load(): Record<string, boolean> {
  if (typeof localStorage === 'undefined') return {}
  try { return JSON.parse(localStorage.getItem(SECTION_PREFS_KEY) ?? '{}') } catch { return {} }
}

function save(prefs: Record<string, boolean>) {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(SECTION_PREFS_KEY, JSON.stringify(prefs))
}

function createSectionPrefs() {
  let _prefs = $state<Record<string, boolean>>(load())

  return {
    isOpen(key: string): boolean {
      return _prefs[key] ?? true
    },
    toggle(key: string) {
      _prefs = { ..._prefs, [key]: !(_prefs[key] ?? true) }
      save(_prefs)
    },
  }
}

export const sectionPrefs = createSectionPrefs()
