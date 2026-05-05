// icons.jsx — minimal line icons

const Icon = {
  Today: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
      <rect x="2.5" y="3.5" width="11" height="10" rx="1.5"/>
      <path d="M5 2v3M11 2v3M2.5 6.5h11"/>
      <circle cx="8" cy="10" r="0.7" fill="currentColor" stroke="none"/>
    </svg>
  ),
  Week: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
      <rect x="2" y="4" width="12" height="9" rx="1"/>
      <path d="M5.5 4v9M9.5 4v9M2 7h12"/>
    </svg>
  ),
  Month: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
      <rect x="2" y="3.5" width="12" height="10" rx="1"/>
      <path d="M2 7h12M5 7v6.5M9 7v6.5M13 7v6.5M2 10h12"/>
    </svg>
  ),
  Year: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
      <circle cx="8" cy="8" r="5.5"/>
      <path d="M8 4v4l2.5 1.5"/>
    </svg>
  ),
  Backlog: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
      <path d="M2.5 4.5h11M3.5 8h9M5 11.5h6"/>
    </svg>
  ),
  Archive: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
      <rect x="2" y="3.5" width="12" height="3" rx="0.5"/>
      <path d="M3 6.5V13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V6.5M6.5 9h3"/>
    </svg>
  ),
  Settings: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
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
    <svg width={s} height={s} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
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
  Success: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="7" cy="7" r="5.5"/>
      <path d="M4.5 7l1.8 1.8L9.5 5.5"/>
    </svg>
  ),
  Late: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="7" cy="7" r="5.5"/>
      <path d="M7 4v3.2L9 8.6"/>
    </svg>
  ),
  Failure: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round">
      <circle cx="7" cy="7" r="5.5"/>
      <path d="M5 5l4 4M9 5l-4 4"/>
    </svg>
  ),
  More: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 14 14" fill="none">
      <circle cx="3" cy="7" r="1" fill="currentColor"/>
      <circle cx="7" cy="7" r="1" fill="currentColor"/>
      <circle cx="11" cy="7" r="1" fill="currentColor"/>
    </svg>
  ),
};

window.Icon = Icon;
