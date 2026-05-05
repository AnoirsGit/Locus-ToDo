// views-jira.jsx — All screens, Jira table style

const TodayView = ({ tasks, toggle, openCmdK }) => {
  const dayTasks = tasks.filter(t => t.level === 'day' && (t.status === 'todo' || t.status === 'done' || t.status === 'overdue'));
  const weekCtx = tasks.filter(t => t.level === 'week' && (t.status === 'todo' || t.status === 'overdue'));
  const monthCtx = tasks.filter(t => t.level === 'month' && t.status === 'todo');
  const yearCtx = tasks.filter(t => t.level === 'year' && t.status === 'todo');
  const overdue = tasks.filter(t => t.status === 'overdue');

  const totalToday = dayTasks.length;
  const doneToday = dayTasks.filter(t => t.status === 'done').length;
  const pct = Math.round((doneToday / Math.max(totalToday, 1)) * 100);

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <a href="#">Horizons</a><span className="crumb-sep">/</span>
        <span>Today</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Today</h1>
          <div className="page-subtitle">Monday · 04 May 2026 · Week 19</div>
        </div>
        <div className="page-actions">
          <button className="btn subtle"><Icon.More /></button>
          <button className="btn primary" onClick={openCmdK}><Icon.Plus /> Create</button>
        </div>
      </div>

      <div className="day-meter">
        <div className="day-meter-stat">
          <div className="day-meter-num">{doneToday}<em>/{totalToday}</em></div>
          <div className="day-meter-label">Done today</div>
        </div>
        <div className="day-meter-stat">
          <div className="day-meter-num" style={{ color: overdue.length ? 'var(--overdue)' : 'var(--text-bright)' }}>
            {overdue.length}
          </div>
          <div className="day-meter-label">In penalty</div>
        </div>
        <div className="day-meter-stat">
          <div className="day-meter-num">{weekCtx.length + monthCtx.length + yearCtx.length}</div>
          <div className="day-meter-label">Larger horizons</div>
        </div>
        <div className="day-meter-bar-wrap">
          <div className="day-meter-bar-meta">
            <span>Progress</span><span>{pct}%</span>
          </div>
          <div className="day-meter-bar">
            <div className={`day-meter-bar-fill ${overdue.length ? 'overdue' : ''}`} style={{ width: `${pct}%` }} />
          </div>
        </div>
      </div>

      <div className="toolbar">
        <div className="search-input">
          <Icon.Search />
          <input placeholder="Search tasks…" />
        </div>
        <button className="filter-chip">Type: All</button>
        <button className="filter-chip">Status: Active</button>
        <button className="filter-chip">+ Add filter</button>
        <div className="toolbar-spacer" />
        <span className="muted" style={{ fontSize: 12 }}>{dayTasks.length + weekCtx.length} issues</span>
      </div>

      {overdue.length > 0 && (
        <div className="section">
          <SectionHeader title="Carried over" meta={`${overdue.length} in penalty period`} />
          <div className="task-list">
            <TaskTableHead />
            {overdue.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          </div>
        </div>
      )}

      <div className="section">
        <SectionHeader title="Today" meta={`${dayTasks.length} tasks`} />
        <div className="task-list">
          <TaskTableHead />
          {dayTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          <div className="quick-add" onClick={openCmdK}>
            <span className="quick-add-plus"><Icon.Plus /></span>
            <span>Create task</span>
            <span style={{ marginLeft: 'auto', display: 'flex', gap: 4 }}>
              <span className="kbd">⌘</span><span className="kbd">K</span>
            </span>
          </div>
        </div>
      </div>

      {(weekCtx.length + monthCtx.length + yearCtx.length) > 0 && (
        <div className="section">
          <SectionHeader title="Larger horizons" meta="week, month, year context" />
          <div className="task-list">
            <TaskTableHead />
            {weekCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
            {monthCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
            {yearCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          </div>
        </div>
      )}
    </>
  );
};

const WeekView = ({ tasks, toggle }) => {
  const weekTasks = tasks.filter(t => t.level === 'week' && t.status !== 'archived' && t.status !== 'backlog');
  const monthCtx = tasks.filter(t => t.level === 'month' && t.status === 'todo');
  const yearCtx = tasks.filter(t => t.level === 'year' && t.status === 'todo');

  const days = [
    { dow: 'Mon', n: 4, today: true },
    { dow: 'Tue', n: 5 },
    { dow: 'Wed', n: 6 },
    { dow: 'Thu', n: 7 },
    { dow: 'Fri', n: 8 },
    { dow: 'Sat', n: 9 },
    { dow: 'Sun', n: 10 },
  ];
  const tasksByDay = (dow) => weekTasks.filter(t => t.targetDate === dow);

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <a href="#">Horizons</a><span className="crumb-sep">/</span>
        <span>Week</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Week 19</h1>
          <div className="page-subtitle">04 – 10 May 2026</div>
        </div>
        <div className="page-actions">
          <button className="btn subtle">Previous week</button>
          <button className="btn subtle">Next week</button>
        </div>
      </div>

      <div className="week-strip">
        {days.map(d => {
          const dt = tasksByDay(d.dow);
          return (
            <div key={d.dow} className={`week-strip-day ${d.today ? 'today' : ''}`}>
              <div className="week-strip-dow">{d.dow}</div>
              <div className="week-strip-num">{String(d.n).padStart(2, '0')}</div>
              <div className="week-strip-dots">
                {dt.map(t => <span key={t.id} className={`level-dot level-${t.level}`} />)}
              </div>
            </div>
          );
        })}
      </div>

      <div className="toolbar">
        <div className="search-input">
          <Icon.Search />
          <input placeholder="Search this week…" />
        </div>
        <button className="filter-chip">Type: Story</button>
        <button className="filter-chip">+ Add filter</button>
        <div className="toolbar-spacer" />
        <span className="muted" style={{ fontSize: 12 }}>{weekTasks.length} issues</span>
      </div>

      <div className="section">
        <SectionHeader title="Week tasks" meta={`${weekTasks.length} active`} />
        <div className="task-list">
          <TaskTableHead />
          {weekTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          <QuickAdd label="Create story for this week" />
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Larger horizons" meta="month + year" />
        <div className="task-list">
          <TaskTableHead />
          {monthCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          {yearCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
        </div>
      </div>
    </>
  );
};

const MonthView = ({ tasks, toggle }) => {
  const monthTasks = tasks.filter(t => t.level === 'month' && t.status !== 'archived' && t.status !== 'backlog');
  const yearCtx = tasks.filter(t => t.level === 'year' && t.status === 'todo');

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <a href="#">Horizons</a><span className="crumb-sep">/</span>
        <span>Month</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">May 2026</h1>
          <div className="page-subtitle">{monthTasks.length} epics in flight</div>
        </div>
      </div>

      <div className="section">
        <SectionHeader title="May epics" meta={`${monthTasks.length} active`} />
        <div className="task-list">
          <TaskTableHead />
          {monthTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          <QuickAdd label="Create epic for May" />
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Weekly breakdown" meta="four weeks ahead" />
        <div className="month-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
          {[
            { name: 'Week 19', range: '04 – 10', tasks: 4, current: true },
            { name: 'Week 20', range: '11 – 17', tasks: 3 },
            { name: 'Week 21', range: '18 – 24', tasks: 2 },
            { name: 'Week 22', range: '25 – 31', tasks: 1 },
          ].map((w, i) => (
            <div key={i} className={`month-cell ${w.current ? 'current' : ''}`}>
              <div className="month-cell-name">{w.name}</div>
              <div className="month-cell-stat">{w.tasks}<em> issues</em></div>
              <div className="month-cell-tasks">{w.range} May</div>
            </div>
          ))}
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Year initiatives" meta="strategic context" />
        <div className="task-list">
          <TaskTableHead />
          {yearCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
        </div>
      </div>
    </>
  );
};

const YearView = ({ tasks, toggle }) => {
  const yearTasks = tasks.filter(t => t.level === 'year' && t.status !== 'archived' && t.status !== 'backlog');

  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const monthData = months.map((m, i) => ({
    name: m, n: i + 1,
    completed: i < 4 ? [3, 5, 4, 6][i] : i === 4 ? 1 : 0,
    total: i < 4 ? [4, 5, 5, 6][i] : i === 4 ? 5 : 0,
    failed: i < 4 ? [1, 0, 1, 0][i] : 0,
    current: i === 4, past: i < 4,
  }));

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <a href="#">Horizons</a><span className="crumb-sep">/</span>
        <span>Year</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">2026</h1>
          <div className="page-subtitle">Strategic initiatives · {yearTasks.length} active</div>
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Initiatives" meta={`${yearTasks.length} active`} />
        <div className="task-list">
          <TaskTableHead />
          {yearTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          <QuickAdd label="Create initiative for 2026" />
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Monthly breakdown" meta="January through December" />
        <div className="month-grid">
          {monthData.map((m) => (
            <div key={m.name} className={`month-cell ${m.current ? 'current' : ''} ${m.past ? 'past' : ''}`}>
              <div className="month-cell-name">{m.name}</div>
              {m.total > 0 ? (
                <>
                  <div className="month-cell-stat">{m.completed}<em>/{m.total}</em></div>
                  <div className="month-cell-tasks">
                    {m.current ? 'in progress' : m.failed > 0 ? <span style={{ color: 'var(--failure)' }}>{m.failed} missed</span> : 'all clear'}
                  </div>
                </>
              ) : (
                <>
                  <div className="month-cell-stat" style={{ color: 'var(--text-4)' }}>—</div>
                  <div className="month-cell-tasks" style={{ color: 'var(--text-4)' }}>future</div>
                </>
              )}
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

const BacklogView = ({ tasks, openReplan }) => {
  const backlog = tasks.filter(t => t.status === 'backlog');
  const byLevel = {
    week: backlog.filter(t => t.level === 'week'),
    month: backlog.filter(t => t.level === 'month'),
    day: backlog.filter(t => t.level === 'day'),
    year: backlog.filter(t => t.level === 'year'),
  };

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <a href="#">Records</a><span className="crumb-sep">/</span>
        <span>Backlog</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Backlog</h1>
          <div className="page-subtitle">{backlog.length} issues awaiting your decision</div>
        </div>
      </div>

      <div className="principle">
        <div className="principle-mark">!</div>
        <div className="principle-text">
          Nothing disappears silently. <strong>Reschedule</strong> what still matters,
          or <strong>archive</strong> what doesn't. The point of Locus is that you decide,
          honestly, in either direction.
        </div>
      </div>

      <div className="toolbar">
        <div className="search-input">
          <Icon.Search />
          <input placeholder="Search backlog…" />
        </div>
        <button className="filter-chip">Type: All</button>
        <button className="filter-chip">+ Add filter</button>
        <div className="toolbar-spacer" />
        <span className="muted" style={{ fontSize: 12 }}>{backlog.length} issues</span>
      </div>

      {backlog.length === 0 ? (
        <div className="empty">
          <div className="empty-mark">∅</div>
          <div className="empty-title">Backlog is empty.</div>
          <div className="empty-body">Nothing has slipped past you. Keep going.</div>
        </div>
      ) : (
        <>
          {Object.entries(byLevel).map(([level, items]) => items.length > 0 && (
            <div className="section" key={level}>
              <SectionHeader title={`From your ${level}s`} meta={`${items.length} pending`} />
              <div className="task-list">
                <TaskTableHead />
                {items.map(t => <TaskRow key={t.id} task={t} onReplan={openReplan} />)}
              </div>
            </div>
          ))}
        </>
      )}
    </>
  );
};

const ArchiveView = ({ tasks }) => {
  const archived = tasks.filter(t => t.status === 'archived');
  const byOutcome = {
    success: archived.filter(t => t.outcome === 'success').length,
    late: archived.filter(t => t.outcome === 'late').length,
    failure: archived.filter(t => t.outcome === 'failure').length,
  };
  const total = archived.length;
  const completionPct = Math.round(((byOutcome.success + byOutcome.late) / Math.max(total, 1)) * 100);

  const OutcomeGlyph = ({ outcome }) => {
    if (outcome === 'success') return <span style={{ color: 'var(--success)' }}><Icon.Success /></span>;
    if (outcome === 'late') return <span style={{ color: 'var(--backlog)' }}><Icon.Late /></span>;
    return <span style={{ color: 'var(--failure)' }}><Icon.Failure /></span>;
  };
  const outcomeLabel = (o) => o === 'success' ? 'on time' : o === 'late' ? 'late' : 'failed';

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <a href="#">Records</a><span className="crumb-sep">/</span>
        <span>Archive</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Archive</h1>
          <div className="page-subtitle">A record of what was kept, and what was let go · YTD 2026</div>
        </div>
      </div>

      <div className="month-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', marginBottom: 24 }}>
        <div className="month-cell">
          <div className="month-cell-name">Completion</div>
          <div className="month-cell-stat">{completionPct}<em>%</em></div>
          <div className="month-cell-tasks">across all goals</div>
        </div>
        <div className="month-cell" style={{ borderColor: 'var(--success)' }}>
          <div className="month-cell-name" style={{ color: 'var(--success)' }}>On time</div>
          <div className="month-cell-stat">{byOutcome.success}</div>
          <div className="month-cell-tasks">kept the deadline</div>
        </div>
        <div className="month-cell" style={{ borderColor: 'var(--backlog)' }}>
          <div className="month-cell-name" style={{ color: 'var(--backlog)' }}>Late</div>
          <div className="month-cell-stat">{byOutcome.late}</div>
          <div className="month-cell-tasks">done in penalty</div>
        </div>
        <div className="month-cell" style={{ borderColor: 'var(--failure)' }}>
          <div className="month-cell-name" style={{ color: 'var(--failure)' }}>Failed</div>
          <div className="month-cell-stat">{byOutcome.failure}</div>
          <div className="month-cell-tasks">discarded</div>
        </div>
      </div>

      <div className="section">
        <SectionHeader title="History" meta="newest first" />
        <div className="task-list">
          <div className="task-list-head" style={{ gridTemplateColumns: '100px 24px 1fr 90px 110px 110px' }}>
            <div>Closed</div>
            <div></div>
            <div>Summary</div>
            <div>Type</div>
            <div>Key</div>
            <div>Outcome</div>
          </div>
          {archived.map(t => (
            <div key={t.id} className={`archive-row ${t.outcome}`}>
              <div className="archive-date">{t.archivedDate}</div>
              <div className="outcome-glyph"><OutcomeGlyph outcome={t.outcome} /></div>
              <div className="archive-title">{t.title}</div>
              <LevelPill level={t.level} />
              <span className="task-key">{taskKey(t)}</span>
              <span className={`outcome ${t.outcome}`}>{outcomeLabel(t.outcome)}</span>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

const SettingsView = () => {
  const [push, setPush] = React.useState(true);
  const [quiet, setQuiet] = React.useState(true);
  const [strict, setStrict] = React.useState(true);
  const [weekly, setWeekly] = React.useState(true);

  return (
    <>
      <div className="breadcrumb">
        <a href="#">Locus</a><span className="crumb-sep">/</span>
        <span>Settings</span>
      </div>
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Settings</h1>
          <div className="page-subtitle">Profile and preferences</div>
        </div>
      </div>

      <div className="settings-block">
        <SectionHeader title="Profile" meta="who you are" />
        <div className="panel">
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Name</div>
              <div className="settings-row-hint">As shown in your profile</div>
            </div>
            <input className="input" defaultValue="Lev Ostrovsky" />
            <div />
          </div>
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Email</div>
              <div className="settings-row-hint">For login and digests</div>
            </div>
            <input className="input" defaultValue="lev@ostrovsky.studio" />
            <div />
          </div>
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Timezone</div>
              <div className="settings-row-hint">Used for daily reset</div>
            </div>
            <input className="input" defaultValue="Europe/Moscow (UTC+3)" />
            <div />
          </div>
        </div>
      </div>

      <div className="settings-block">
        <SectionHeader title="Notifications" meta="how Locus reaches you" />
        <div className="panel">
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Push notifications</div>
              <div className="settings-row-hint">For scheduled day-tasks with a time</div>
            </div>
            <div />
            <button className={`switch ${push ? 'on' : ''}`} onClick={() => setPush(!push)} />
          </div>
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Quiet hours</div>
              <div className="settings-row-hint">22:00 – 07:00 · no pings</div>
            </div>
            <div />
            <button className={`switch ${quiet ? 'on' : ''}`} onClick={() => setQuiet(!quiet)} />
          </div>
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Weekly digest</div>
              <div className="settings-row-hint">Sundays · what you kept, what slipped</div>
            </div>
            <div />
            <button className={`switch ${weekly ? 'on' : ''}`} onClick={() => setWeekly(!weekly)} />
          </div>
        </div>
      </div>

      <div className="settings-block">
        <SectionHeader title="Discipline" meta="behavioural settings" />
        <div className="panel">
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Strict overdue</div>
              <div className="settings-row-hint">Show carried-over tasks with red emphasis</div>
            </div>
            <div />
            <button className={`switch ${strict ? 'on' : ''}`} onClick={() => setStrict(!strict)} />
          </div>
        </div>
      </div>
    </>
  );
};

Object.assign(window, { TodayView, WeekView, MonthView, YearView, BacklogView, ArchiveView, SettingsView });
