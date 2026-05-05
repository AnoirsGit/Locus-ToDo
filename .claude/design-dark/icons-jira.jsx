// icons-jira.jsx — Jira-style line + filled icons

const Icon = {
  Today: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <rect x="2.5" y="3.5" width="11" height="10" rx="1.5"/>
      <path d="M5 2v3M11 2v3M2.5 6.5h11"/>
    </svg>
  ),
  Week: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
      <rect x="2" y="4" width="12" height="9" rx="1"/>
      <path d="M5.5 4v9M9.5 4v9M2 7h12"/>
    </svg>
  ),
  Month: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
      <rect x="2" y="3.5" width="12" height="10" rx="1"/>
      <path d="M2 7h12M5 7v6.5M9 7v6.5M13 7v6.5M2 10h12"/>
    </svg>
  ),
  Year: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
      <circle cx="8" cy="8" r="5.5"/>
      <path d="M8 4v4l2.5 1.5"/>
    </svg>
  ),
  Backlog: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <path d="M2.5 4.5h11M3.5 8h9M5 11.5h6"/>
    </svg>
  ),
  Archive: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
      <rect x="2" y="3.5" width="12" height="3" rx="0.5"/>
      <path d="M3 6.5V13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V6.5M6.5 9h3"/>
    </svg>
  ),
  Settings: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
      <circle cx="8" cy="8" r="2"/>
      <path d="M8 1.5v2M8 12.5v2M14.5 8h-2M3.5 8h-2M12.6 3.4l-1.4 1.4M4.8 11.2l-1.4 1.4M12.6 12.6l-1.4-1.4M4.8 4.8L3.4 3.4"/>
    </svg>
  ),
  Tick: ({ s = 10 }) => (
    <svg width={s} height={s} viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 5l2 2 4-4.5"/>
    </svg>
  ),
  Plus: ({ s = 12 }) => (
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
      <path d="M6 2v8M2 6h8"/>
    </svg>
  ),
  Repeat: ({ s = 11 }) => (
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 5V4a1 1 0 0 1 1-1h6.5L8 1.5M10 7v1a1 1 0 0 1-1 1H2.5L4 10.5"/>
    </svg>
  ),
  Carryover: ({ s = 11 }) => (
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 6h6M6 3l3 3-3 3"/>
    </svg>
  ),
  Search: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <circle cx="6" cy="6" r="4"/>
      <path d="M9 9l3 3"/>
    </svg>
  ),
  Chevron: ({ s = 12 }) => (
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 4.5l3 3 3-3"/>
    </svg>
  ),
  ChevronRight: ({ s = 10 }) => (
    <svg width={s} height={s} viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3.5 2l3 3-3 3"/>
    </svg>
  ),
  ChevronDown: ({ s = 12 }) => (
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 4.5l3 3 3-3"/>
    </svg>
  ),
  Clock: ({ s = 12 }) => (
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round">
      <circle cx="6" cy="6" r="4.5"/>
      <path d="M6 3.5V6l1.5 1"/>
    </svg>
  ),
  // Issue-type glyphs (the white shapes inside the colored squares)
  ITypeTask: ({ s = 10 }) => (
    <svg width={s} height={s} viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 5l2 2 4-4.5"/>
    </svg>
  ),
  ITypeStory: ({ s = 10 }) => (
    <svg width={s} height={s} viewBox="0 0 10 10" fill="currentColor">
      <path d="M2.5 1.2a.4.4 0 0 0-.4.4v6.8a.4.4 0 0 0 .65.32L5 6.8l2.25 1.92a.4.4 0 0 0 .65-.32V1.6a.4.4 0 0 0-.4-.4H2.5z"/>
    </svg>
  ),
  ITypeEpic: ({ s = 10 }) => (
    <svg width={s} height={s} viewBox="0 0 10 10" fill="currentColor">
      <path d="M5.5 1.2c-.2 0-.4.13-.46.33l-.4 1.5-1.55.13a.5.5 0 0 0-.28.87l1.18 1-.4 1.5a.5.5 0 0 0 .75.55L5.5 6.3l1.16.78a.5.5 0 0 0 .75-.55l-.4-1.5 1.18-1a.5.5 0 0 0-.28-.87l-1.55-.13-.4-1.5A.5.5 0 0 0 5.5 1.2z"/>
    </svg>
  ),
  ITypeInitiative: ({ s = 10 }) => (
    <svg width={s} height={s} viewBox="0 0 10 10" fill="currentColor">
      <path d="M2 1.5h6c.28 0 .5.22.5.5v4.2a.5.5 0 0 1-.18.39L5.32 8.95a.5.5 0 0 1-.64 0L1.68 6.59A.5.5 0 0 1 1.5 6.2V2c0-.28.22-.5.5-.5z"/>
    </svg>
  ),
  Success: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="currentColor">
      <circle cx="7" cy="7" r="6"/>
      <path d="M4.5 7l1.8 1.8L9.5 5.5" stroke="#1d2125" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  Late: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="currentColor">
      <circle cx="7" cy="7" r="6"/>
      <path d="M7 4v3.2L9 8.6" stroke="#1d2125" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  Failure: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="currentColor">
      <circle cx="7" cy="7" r="6"/>
      <path d="M5 5l4 4M9 5l-4 4" stroke="#1d2125" strokeWidth="1.6" fill="none" strokeLinecap="round"/>
    </svg>
  ),
  Priority: ({ s = 12, level = 'medium' }) => {
    const colors = { low: '#7ee2b8', medium: '#e2b203', high: '#f87168' };
    return (
      <svg width={s} height={s} viewBox="0 0 12 12" fill={colors[level]}>
        <rect x="2" y="7" width="2" height="3" rx="0.4" opacity={level === 'low' ? 1 : level === 'medium' ? 1 : 1}/>
        <rect x="5" y="4" width="2" height="6" rx="0.4" opacity={level === 'low' ? 0.3 : 1}/>
        <rect x="8" y="1" width="2" height="9" rx="0.4" opacity={level === 'high' ? 1 : 0.3}/>
      </svg>
    );
  },
  More: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="currentColor">
      <circle cx="3" cy="7" r="1"/>
      <circle cx="7" cy="7" r="1"/>
      <circle cx="11" cy="7" r="1"/>
    </svg>
  ),
};

window.Icon = Icon;
