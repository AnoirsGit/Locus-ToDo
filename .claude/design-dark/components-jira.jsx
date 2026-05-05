// components-jira.jsx — Jira-style task row + helpers

const ITypeIcon = ({ level }) => {
  const Glyph = level === 'day' ? Icon.ITypeTask
              : level === 'week' ? Icon.ITypeStory
              : level === 'month' ? Icon.ITypeEpic
              : Icon.ITypeInitiative;
  return <span className={`itype level-${level}`}><Glyph /></span>;
};

const LevelPill = ({ level }) => {
  const label = level === 'day' ? 'TASK' : level === 'week' ? 'STORY' : level === 'month' ? 'EPIC' : 'INITIATIVE';
  return <span className={`level-pill level-${level}`}><ITypeIcon level={level} /> {label}</span>;
};

const StatusLozenge = ({ status }) => {
  const cls = status === 'done' ? 'done'
            : status === 'overdue' ? 'overdue'
            : status === 'backlog' ? 'backlog'
            : 'todo';
  const label = status === 'done' ? 'DONE'
              : status === 'overdue' ? 'OVERDUE'
              : status === 'backlog' ? 'BACKLOG'
              : 'TO DO';
  return <span className={`lozenge ${cls}`}>{label}</span>;
};

const Checkbox = ({ checked, onClick }) => (
  <button
    className={`checkbox ${checked ? 'checked' : ''}`}
    onClick={onClick}
    aria-label={checked ? 'Mark incomplete' : 'Mark complete'}
  >
    <span className="checkbox-tick"><Icon.Tick /></span>
  </button>
);

// Generate a Jira-style key
const taskKey = (t) => {
  const prefix = t.level === 'day' ? 'DAY' : t.level === 'week' ? 'WK' : t.level === 'month' ? 'MO' : 'YR';
  const num = (parseInt(t.id.replace(/\D/g, ''), 10) || 1) * 7 + 100;
  return `${prefix}-${num}`;
};

const taskPriority = (t) => {
  if (t.status === 'overdue') return 'high';
  if (t.level === 'day') return 'medium';
  if (t.level === 'week') return 'medium';
  if (t.level === 'month') return 'low';
  return 'low';
};

const TaskRow = ({ task, onToggle, onReplan, showKey = true }) => {
  const status = task.status;
  const checked = status === 'done';
  const priority = taskPriority(task);
  const due = task.time
    ? task.time
    : task.targetDate
      ? task.targetDate
      : task.deadlineMonth
        ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][task.deadlineMonth-1]
        : '—';

  return (
    <div className={`task level-${task.level} ${status}`}>
      <Checkbox checked={checked} onClick={() => onToggle && onToggle(task.id)} />
      {showKey && <span className="task-key">{taskKey(task)}</span>}
      <div className="task-title-cell">
        <ITypeIcon level={task.level} />
        <span className="task-title">{task.title}</span>
        <span className="task-tags">
          {task.recurring && (
            <span className="tag recurring" title="Recurring"><Icon.Repeat /></span>
          )}
          {task.carryover && (
            <span className="tag carryover">
              <Icon.Carryover /> carried
            </span>
          )}
        </span>
      </div>
      <div className="task-cell">
        <StatusLozenge status={status} />
      </div>
      <div className="task-cell">
        <Icon.Priority level={priority} />
        <span style={{ textTransform: 'capitalize' }}>{priority}</span>
      </div>
      <div className="task-cell">
        {status === 'backlog' ? (
          <button className="btn warn sm" onClick={() => onReplan && onReplan(task)}>Reschedule</button>
        ) : (
          <span className="muted">{due}</span>
        )}
      </div>
    </div>
  );
};

const SectionHeader = ({ title, meta, children }) => (
  <div className="section-header">
    <button className="section-disclosure"><Icon.ChevronDown /></button>
    <h2 className="section-title">{title}</h2>
    {meta && <span className="section-meta">{meta}</span>}
    <div style={{ marginLeft: 'auto', display: 'flex', gap: 6 }}>{children}</div>
  </div>
);

const TaskTableHead = ({ showKey = true }) => (
  <div className="task-list-head">
    <div></div>
    {showKey && <div className="col-key">Key</div>}
    <div>Summary</div>
    <div>Status</div>
    <div>Priority</div>
    <div>Due</div>
  </div>
);

const QuickAdd = ({ label = 'Create task' }) => (
  <div className="quick-add" onClick={() => window.openCmdK && window.openCmdK()}>
    <span className="quick-add-plus"><Icon.Plus /></span>
    <span>{label}</span>
    <span style={{ marginLeft: 'auto', display: 'flex', gap: 4 }}>
      <span className="kbd">⌘</span><span className="kbd">K</span>
    </span>
  </div>
);

Object.assign(window, { ITypeIcon, LevelPill, StatusLozenge, Checkbox, TaskRow, SectionHeader, TaskTableHead, QuickAdd, taskKey });
