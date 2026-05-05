// data.jsx — seed data covering all lifecycle states

const TODAY = new Date(2026, 4, 4); // Mon May 4, 2026
const fmtTime = (h, m) => `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;

const SEED_TASKS = [
  // ===== DAY-LEVEL TASKS — TODAY =====
  { id: 't1', level: 'day', title: 'Morning pages — three pages, longhand',
    time: '07:00', status: 'done', recurring: { dayOfWeek: null }, doneAt: '07:24' },
  { id: 't2', level: 'day', title: 'Run — eight kilometres, Sokolniki loop',
    time: '07:30', status: 'done', recurring: { dayOfWeek: null }, doneAt: '08:42' },
  { id: 't3', level: 'day', title: 'Inbox to zero',
    time: '09:00', status: 'todo', recurring: { dayOfWeek: null } },
  { id: 't4', level: 'day', title: 'Deep work block — Locus billing module',
    desc: 'No Slack, no email. Phone in the drawer.',
    time: '10:00', status: 'todo' },
  { id: 't5', level: 'day', title: 'Stand-up + review PRs from Marek and Yuna',
    time: '13:30', status: 'todo' },
  { id: 't6', level: 'day', title: 'Call Mum',
    time: '19:00', status: 'todo', recurring: { dayOfWeek: 1 } },
  { id: 't7', level: 'day', title: 'Read 30 min — finish "Discipline is Destiny"',
    time: '22:00', status: 'todo', recurring: { dayOfWeek: null } },

  // ===== WEEK-LEVEL TASKS — current week =====
  { id: 'w1', level: 'week', title: 'Ship onboarding redesign to staging',
    targetDate: 'Wed', status: 'todo' },
  { id: 'w2', level: 'week', title: 'Draft Q3 OKRs for the design org',
    targetDate: 'Thu', status: 'todo' },
  { id: 'w3', level: 'week', title: 'Reply to Mira about apartment lease',
    targetDate: 'Tue', status: 'todo' },
  { id: 'w4', level: 'week', title: 'File the May expense report',
    status: 'overdue', carryover: 'last week' },

  // ===== MONTH-LEVEL TASKS — May =====
  { id: 'm1', level: 'month', title: 'Finalise Locus pricing model',
    status: 'todo' },
  { id: 'm2', level: 'month', title: 'Visit grandfather in Tver',
    desc: 'Two-night minimum. Take the Friday train.',
    status: 'todo' },
  { id: 'm3', level: 'month', title: 'Pay quarterly tax estimate',
    status: 'todo', recurring: { dayOfMonth: 28 } },

  // ===== YEAR-LEVEL TASKS — 2026 =====
  { id: 'y1', level: 'year', title: 'Translate grandmother\'s letters into English',
    deadlineMonth: 9, status: 'todo' },
  { id: 'y2', level: 'year', title: 'Run a half-marathon under 1:45',
    deadlineMonth: 10, status: 'todo' },
  { id: 'y3', level: 'year', title: 'Read fifty books',
    status: 'todo' },

  // ===== BACKLOG =====
  { id: 'b1', level: 'week', title: 'Write the manifesto for Locus',
    status: 'backlog', backlogSince: 'Apr 27', failedAt: 'wk 17' },
  { id: 'b2', level: 'month', title: 'Apply for the Berlin residency',
    status: 'backlog', backlogSince: 'Mar 31', failedAt: 'March' },
  { id: 'b3', level: 'day', title: 'Take Tati to the planetarium',
    status: 'backlog', backlogSince: 'Apr 19', failedAt: 'Sun, Apr 19' },
  { id: 'b4', level: 'week', title: 'Catch up on reading list — three articles minimum',
    status: 'backlog', backlogSince: 'Apr 20', failedAt: 'wk 16' },

  // ===== ARCHIVE =====
  { id: 'a1', level: 'day', title: 'Hydrate — 2L water',
    status: 'archived', outcome: 'success', archivedDate: 'May 3' },
  { id: 'a2', level: 'week', title: 'Submit visa renewal documents',
    status: 'archived', outcome: 'success', archivedDate: 'May 2' },
  { id: 'a3', level: 'day', title: 'Deep work — billing schema',
    status: 'archived', outcome: 'success', archivedDate: 'May 2' },
  { id: 'a4', level: 'week', title: 'Lift four times this week',
    status: 'archived', outcome: 'late', archivedDate: 'Apr 28' },
  { id: 'a5', level: 'month', title: 'Finish April book — "Meditations"',
    status: 'archived', outcome: 'success', archivedDate: 'Apr 30' },
  { id: 'a6', level: 'day', title: 'Cold shower',
    status: 'archived', outcome: 'failure', archivedDate: 'Apr 29' },
  { id: 'a7', level: 'week', title: 'Sketch six logo directions for Locus',
    status: 'archived', outcome: 'success', archivedDate: 'Apr 26' },
  { id: 'a8', level: 'day', title: 'Meditate — 20 min',
    status: 'archived', outcome: 'success', archivedDate: 'Apr 25' },
  { id: 'a9', level: 'month', title: 'Quarterly tax estimate',
    status: 'archived', outcome: 'late', archivedDate: 'Apr 30' },
  { id: 'a10', level: 'year', title: 'Pick a single discipline to deepen',
    status: 'archived', outcome: 'success', archivedDate: 'Jan 14' },
];

window.SEED_TASKS = SEED_TASKS;
window.TODAY = TODAY;
