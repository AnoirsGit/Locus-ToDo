// app.jsx — Main shell, view router

const NAV = [
  { id: 'today', label: 'Today', icon: 'Today' },
  { id: 'week', label: 'Week', icon: 'Week' },
  { id: 'month', label: 'Month', icon: 'Month' },
  { id: 'year', label: 'Year', icon: 'Year' },
];

const NAV_2 = [
  { id: 'backlog', label: 'Backlog', icon: 'Backlog' },
  { id: 'archive', label: 'Archive', icon: 'Archive' },
  { id: 'settings', label: 'Settings', icon: 'Settings' },
];

const Sidebar = ({ view, setView, counts }) => (
  <aside className="sidebar">
    <div className="brand">
      <span className="brand-mark">Locus</span>
      <span className="brand-dot" />
    </div>
    <div className="nav-section">
      <div className="nav-label">Horizons</div>
      {NAV.map(n => {
        const Glyph = Icon[n.icon];
        return (
          <button
            key={n.id}
            className={`nav-item ${view === n.id ? 'active' : ''}`}
            onClick={() => setView(n.id)}
          >
            <span className="nav-item-glyph"><Glyph /></span>
            {n.label}
            {counts[n.id] != null && <span className="nav-count">{counts[n.id]}</span>}
          </button>
        );
      })}
    </div>
    <div className="nav-section">
      <div className="nav-label">Records</div>
      {NAV_2.map(n => {
        const Glyph = Icon[n.icon];
        const hasDot = n.id === 'backlog' && counts.backlog > 0;
        return (
          <button
            key={n.id}
            className={`nav-item ${view === n.id ? 'active' : ''} ${hasDot ? 'has-dot' : ''}`}
            onClick={() => setView(n.id)}
          >
            <span className="nav-item-glyph"><Glyph /></span>
            {n.label}
            {counts[n.id] != null && <span className="nav-count">{counts[n.id]}</span>}
          </button>
        );
      })}
    </div>
    <div className="user-card">
      <div className="user-avatar">L</div>
      <div style={{ minWidth: 0 }}>
        <div className="user-name">Lev Ostrovsky</div>
        <div className="user-email">lev@ostrovsky.studio</div>
      </div>
    </div>
  </aside>
);

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [view, setView] = React.useState('today');
  const [tasks, setTasks] = React.useState(SEED_TASKS);
  const [replanTask, setReplanTask] = React.useState(null);
  const [cmdkOpen, setCmdkOpen] = React.useState(false);
  const [authView, setAuthView] = React.useState(null); // 'login' | 'register' | null

  const toggle = (id) => {
    setTasks(prev => prev.map(t => {
      if (t.id !== id) return t;
      if (t.status === 'overdue') return { ...t, status: 'done', doneAt: 'now', wasOverdue: true };
      if (t.status === 'done') return { ...t, status: 'todo', doneAt: null };
      if (t.status === 'todo') return { ...t, status: 'done', doneAt: 'now' };
      return t;
    }));
  };

  const openReplan = (task) => setReplanTask(task);
  const confirmReplan = (task, action, opts) => {
    setTasks(prev => prev.map(t => {
      if (t.id !== task.id) return t;
      if (action === 'archive') return { ...t, status: 'archived', outcome: 'failure', archivedDate: 'now' };
      // replan: move to todo at requested level
      return { ...t, status: 'todo', level: opts.level, carryover: 'backlog', backlogSince: null, failedAt: null };
    }));
  };

  const openCmdK = () => setCmdkOpen(true);
  React.useEffect(() => {
    window.openCmdK = openCmdK;
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') { e.preventDefault(); openCmdK(); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const createTask = ({ title, level, time, recurring }) => {
    const id = 'n' + Date.now();
    setTasks(prev => [...prev, {
      id, level, title,
      status: 'todo',
      time: time && time !== 'anytime' ? time : null,
      recurring: recurring ? (level === 'day' ? { dayOfWeek: null } : level === 'week' ? { dayOfWeek: 1 } : level === 'month' ? { dayOfMonth: 1 } : {}) : null,
    }]);
  };

  const counts = {
    today: tasks.filter(x => x.level === 'day' && (x.status === 'todo' || x.status === 'overdue')).length,
    week: tasks.filter(x => x.level === 'week' && (x.status === 'todo' || x.status === 'overdue')).length,
    month: tasks.filter(x => x.level === 'month' && (x.status === 'todo' || x.status === 'overdue')).length,
    year: tasks.filter(x => x.level === 'year' && (x.status === 'todo' || x.status === 'overdue')).length,
    backlog: tasks.filter(x => x.status === 'backlog').length,
    archive: tasks.filter(x => x.status === 'archived').length,
  };

  // Auth screens take over the whole viewport
  if (authView === 'login') return <LoginScreen onSwitch={setAuthView} onSubmit={() => setAuthView(null)} />;
  if (authView === 'register') return <RegisterScreen onSwitch={setAuthView} onSubmit={() => setAuthView(null)} />;

  const screenLabel = {
    today: '01 Today',
    week: '02 Week',
    month: '03 Month',
    year: '04 Year',
    backlog: '05 Backlog',
    archive: '06 Archive',
    settings: '07 Settings',
  }[view];

  return (
    <div className="app" data-screen-label={screenLabel}>
      <Sidebar view={view} setView={setView} counts={counts} />
      <main className="main">
        <div className="main-inner">
          {view === 'today' && <TodayView tasks={tasks} toggle={toggle} openCmdK={openCmdK} />}
          {view === 'week' && <WeekView tasks={tasks} toggle={toggle} />}
          {view === 'month' && <MonthView tasks={tasks} toggle={toggle} />}
          {view === 'year' && <YearView tasks={tasks} toggle={toggle} />}
          {view === 'backlog' && <BacklogView tasks={tasks} openReplan={openReplan} />}
          {view === 'archive' && <ArchiveView tasks={tasks} />}
          {view === 'settings' && <SettingsView />}
        </div>
        {/* Floating peek at auth screens — purely for review */}
        <div style={{
          position: 'fixed', right: 24, top: 24, display: 'flex', gap: 6, zIndex: 5,
        }}>
          <button className="btn ghost sm" onClick={() => setAuthView('login')} title="Preview login screen">
            Login screen
          </button>
          <button className="btn ghost sm" onClick={() => setAuthView('register')} title="Preview register screen">
            Register screen
          </button>
        </div>
      </main>

      {replanTask && <ReplanModal task={replanTask} onClose={() => setReplanTask(null)} onConfirm={confirmReplan} />}
      {cmdkOpen && <CmdK onClose={() => setCmdkOpen(false)} onCreate={createTask} />}

      <TweaksPanel>
        <TweakSection label="Overdue intensity" />
        <TweakRadio
          label="Treatment"
          value={t.overdueIntensity}
          options={['subtle', 'firm', 'strict']}
          onChange={(v) => setTweak('overdueIntensity', v)}
        />
        <TweakSection label="Layout" />
        <TweakRadio
          label="Density"
          value={t.density}
          options={['spacious', 'regular', 'dense']}
          onChange={(v) => setTweak('density', v)}
        />
        <TweakToggle
          label="Show level badges"
          value={t.showLevelBadges}
          onChange={(v) => setTweak('showLevelBadges', v)}
        />
        <TweakToggle
          label="Color level checkboxes"
          value={t.colorCheckboxes}
          onChange={(v) => setTweak('colorCheckboxes', v)}
        />
        <TweakSection label="Backlog tone" />
        <TweakRadio
          label="Voice"
          value={t.backlogTone}
          options={['neutral', 'reflective', 'firm']}
          onChange={(v) => setTweak('backlogTone', v)}
        />
      </TweaksPanel>

      <TweakStyle t={t} />
    </div>
  );
}

// Tweak-driven CSS overrides
function TweakStyle({ t }) {
  let css = '';

  if (t.overdueIntensity === 'subtle') {
    css += `.task.overdue{background:var(--overdue-tint);} .task.overdue::before{width:2px;opacity:0.6;} .task.overdue .task-title{color:var(--ink);font-weight:450;}`;
  } else if (t.overdueIntensity === 'strict') {
    css += `.task.overdue{background:#f4d4a0;border-bottom-color:var(--overdue);} .task.overdue::before{width:4px;background:var(--backlog);} .task.overdue .task-title{color:var(--backlog);font-weight:600;}`;
  }

  if (t.density === 'spacious') {
    css += `.task{padding:18px 4px;} .section{margin-bottom:48px;}`;
  } else if (t.density === 'dense') {
    css += `.task{padding:7px 4px;} .task-desc{display:none;} .section{margin-bottom:24px;}`;
  }

  if (!t.showLevelBadges) {
    css += `.level-badge{display:none;}`;
  }

  if (!t.colorCheckboxes) {
    css += `.task .checkbox.checked{background:var(--ink)!important;border-color:var(--ink)!important;}`;
  }

  return <style>{css}</style>;
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
