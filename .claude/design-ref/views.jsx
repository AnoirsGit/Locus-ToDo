// views.jsx — All screen content

const TodayView = ({ tasks, toggle, openCmdK }) => {
  const dayTasks = tasks.filter(t => t.level === 'day' && (t.status === 'todo' || t.status === 'done' || t.status === 'overdue'));
  const weekToday = tasks.filter(t => t.level === 'week' && t.targetDate === 'Mon' && t.status !== 'archived' && t.status !== 'backlog');
  const weekRest = tasks.filter(t => t.level === 'week' && t.targetDate !== 'Mon' && (t.status === 'todo' || t.status === 'overdue'));
  const monthCtx = tasks.filter(t => t.level === 'month' && t.status === 'todo');
  const yearCtx = tasks.filter(t => t.level === 'year' && t.status === 'todo');
  const overdue = tasks.filter(t => t.status === 'overdue');

  // Group day tasks by approximate time-of-day
  const morning = dayTasks.filter(t => t.time && t.time < '12:00');
  const afternoon = dayTasks.filter(t => t.time && t.time >= '12:00' && t.time < '18:00');
  const evening = dayTasks.filter(t => t.time && t.time >= '18:00');
  const anytime = dayTasks.filter(t => !t.time);

  const totalToday = dayTasks.length;
  const doneToday = dayTasks.filter(t => t.status === 'done').length;
  const pct = Math.round((doneToday / Math.max(totalToday, 1)) * 100);

  return (
    <>
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">
            <span>Monday · 04 May 2026</span>
            <span style={{ color: 'var(--rule-2)' }}>·</span>
            <span>week 19</span>
          </div>
          <h1 className="page-title">Today, <em>quietly.</em></h1>
        </div>
        <div className="page-actions">
          <button className="btn ghost sm" onClick={openCmdK}>
            <Icon.Plus /> Quick add <span className="kbd" style={{ marginLeft: 4 }}>⌘K</span>
          </button>
        </div>
      </div>

      <div className="day-meter">
        <div className="day-meter-stat">
          <div className="day-meter-num">{doneToday}<em>/{totalToday}</em></div>
          <div className="day-meter-label">Done today</div>
        </div>
        <div className="day-meter-divider" />
        <div className="day-meter-stat">
          <div className="day-meter-num" style={{ color: overdue.length ? 'var(--overdue)' : 'var(--ink)' }}>
            {overdue.length}
          </div>
          <div className="day-meter-label">In penalty</div>
        </div>
        <div className="day-meter-divider" />
        <div className="day-meter-bar">
          <div className="day-meter-bar-fill" style={{ width: `${pct}%` }} />
        </div>
        <div className="mono" style={{ fontSize: 11, color: 'var(--ink-3)', letterSpacing: '0.05em' }}>{pct}%</div>
      </div>

      {overdue.length > 0 && (
        <div className="section">
          <SectionHeader title="Carried over" meta={`${overdue.length} in penalty period`} />
          <div className="task-list">
            {overdue.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
          </div>
        </div>
      )}

      <div className="section">
        <SectionHeader title="Morning" meta="07:00 – 12:00" />
        <div className="task-list">
          {morning.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Afternoon" meta="12:00 – 18:00" />
        <div className="task-list">
          {afternoon.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
          {weekToday.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={true} />)}
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Evening" meta="18:00 onwards" />
        <div className="task-list">
          {evening.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} />)}
        </div>
      </div>

      <QuickAdd label="Add a task to today" />

      {(weekRest.length + monthCtx.length + yearCtx.length) > 0 && (
        <div className="section" style={{ marginTop: 56 }}>
          <SectionHeader title="In the background" meta="larger horizons" />
          <div className="task-list">
            {weekRest.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
            {monthCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
            {yearCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
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
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">Week 19 · 04 – 10 May 2026</div>
          <h1 className="page-title">The <em>week</em> ahead.</h1>
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

      <div className="section">
        <SectionHeader title="Week tasks" meta={`${weekTasks.length} active`} />
        <div className="task-list">
          {weekTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
        </div>
        <QuickAdd label="Add a task to this week" />
      </div>

      <div className="section">
        <SectionHeader title="Larger horizons" meta="month + year" />
        <div className="task-list">
          {monthCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
          {yearCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
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
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">May 2026</div>
          <h1 className="page-title"><em>May.</em> Five intentions.</h1>
        </div>
      </div>

      <div className="section">
        <SectionHeader title="May tasks" meta={`${monthTasks.length} active`} />
        <div className="task-list">
          {monthTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
        </div>
        <QuickAdd label="Add an intention for May" />
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
            <div key={i} className={`month-cell ${w.current ? 'current' : ''}`}
                 style={w.current ? { borderColor: 'var(--week)', background: 'var(--week-tint)' } : {}}>
              <div className="month-cell-name" style={w.current ? { color: 'var(--week)' } : {}}>{w.name}</div>
              <div className="month-cell-stat">{w.tasks}<em> tasks</em></div>
              <div className="month-cell-tasks">{w.range} May</div>
            </div>
          ))}
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Year ahead" meta="strategic" />
        <div className="task-list">
          {yearCtx.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
        </div>
      </div>
    </>
  );
};

const YearView = ({ tasks, toggle }) => {
  const yearTasks = tasks.filter(t => t.level === 'year' && t.status !== 'archived' && t.status !== 'backlog');

  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const monthData = months.map((m, i) => ({
    name: m,
    n: i + 1,
    completed: i < 4 ? [3, 5, 4, 6][i] : i === 4 ? 1 : 0,
    total: i < 4 ? [4, 5, 5, 6][i] : i === 4 ? 5 : 0,
    failed: i < 4 ? [1, 0, 1, 0][i] : 0,
    current: i === 4,
    past: i < 4,
  }));

  return (
    <>
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">2026 · the long view</div>
          <h1 className="page-title">A year of <em>deliberate</em> living.</h1>
        </div>
      </div>

      <div className="section">
        <SectionHeader title="Year intentions" meta={`${yearTasks.length} active`} />
        <div className="task-list">
          {yearTasks.map(t => <TaskRow key={t.id} task={t} onToggle={toggle} showTime={false} />)}
        </div>
        <QuickAdd label="Add an intention for 2026" />
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
                  <div className="month-cell-stat" style={{ color: 'var(--ink-4)' }}>—</div>
                  <div className="month-cell-tasks" style={{ color: 'var(--ink-4)' }}>future</div>
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
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">{backlog.length} tasks awaiting your decision</div>
          <h1 className="page-title">The <em>backlog.</em></h1>
        </div>
      </div>

      <div className="principle">
        <div className="principle-mark">¶</div>
        <div className="principle-text">
          Nothing disappears silently. <strong>Reschedule</strong> what still matters,
          or <strong>archive</strong> what doesn't. The point of Locus is that you decide,
          honestly, in either direction.
        </div>
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
                {items.map(t => <TaskRow key={t.id} task={t} showTime={false} onReplan={openReplan} />)}
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
    if (outcome === 'late') return <span style={{ color: 'var(--overdue)' }}><Icon.Late /></span>;
    return <span style={{ color: 'var(--failure)' }}><Icon.Failure /></span>;
  };
  const outcomeLabel = (o) => o === 'success' ? 'on time' : o === 'late' ? 'late' : 'failed';

  return (
    <>
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">Year to date · 2026</div>
          <h1 className="page-title">A record of <em>what was kept,</em><br/>and what was let go.</h1>
        </div>
      </div>

      <div className="month-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', marginBottom: 36 }}>
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
        <div className="month-cell" style={{ borderColor: 'var(--overdue)' }}>
          <div className="month-cell-name" style={{ color: 'var(--overdue)' }}>Late</div>
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
        <div>
          {archived.map(t => (
            <div key={t.id} className={`archive-row ${t.outcome}`}>
              <div className="archive-date">{t.archivedDate}</div>
              <div className="outcome-glyph"><OutcomeGlyph outcome={t.outcome} /></div>
              <div className="archive-title">{t.title}</div>
              <LevelBadge level={t.level} />
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
      <div className="page-header">
        <div className="page-header-left">
          <div className="page-eyebrow">Profile + preferences</div>
          <h1 className="page-title"><em>Settings.</em></h1>
        </div>
      </div>

      <div className="settings-block">
        <SectionHeader title="Profile" meta="who you are" />
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

      <div className="settings-block">
        <SectionHeader title="Notifications" meta="how Locus reaches you" />
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

      <div className="settings-block">
        <SectionHeader title="Discipline" meta="behavioural settings" />
        <div className="settings-row">
          <div>
            <div className="settings-row-label">Strict overdue</div>
            <div className="settings-row-hint">Show carried-over tasks with amber emphasis</div>
          </div>
          <div />
          <button className={`switch ${strict ? 'on' : ''}`} onClick={() => setStrict(!strict)} />
        </div>
      </div>
    </>
  );
};

Object.assign(window, { TodayView, WeekView, MonthView, YearView, BacklogView, ArchiveView, SettingsView });
