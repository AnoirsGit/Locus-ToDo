// components.jsx — Shared UI primitives

const LevelBadge = ({ level }) => (
  <span className={`level-badge level-${level}`}>
    <span className={`level-dot level-${level}`} /> {level}
  </span>
);

const Checkbox = ({ checked, onClick }) => (
  <button
    className={`checkbox ${checked ? 'checked' : ''}`}
    onClick={onClick}
    aria-label={checked ? 'Mark incomplete' : 'Mark complete'}
  >
    <span className="checkbox-tick"><Icon.Tick /></span>
  </button>
);

const TaskRow = ({ task, onToggle, showLevel = true, showTime = true, onReplan }) => {
  const time = task.time;
  const status = task.status;
  const checked = status === 'done';

  return (
    <div className={`task level-${task.level} ${status}`}>
      {showTime && (
        <div className={`task-time ${time ? '' : 'empty'}`}>{time || '—'}</div>
      )}
      <Checkbox checked={checked} onClick={() => onToggle && onToggle(task.id)} />
      <div className="task-body">
        <div className="task-title">{task.title}</div>
        {task.desc && <div className="task-desc">{task.desc}</div>}
        <div className="task-meta">
          {showLevel && <LevelBadge level={task.level} />}
          {task.recurring && (
            <span className="tag recurring">
              <Icon.Repeat /> {task.recurring.dayOfWeek != null ? 'weekly' : task.recurring.dayOfMonth != null ? `monthly · ${task.recurring.dayOfMonth}` : 'daily'}
            </span>
          )}
          {task.targetDate && status !== 'overdue' && (
            <span className="tag">due {task.targetDate}</span>
          )}
          {task.deadlineMonth && (
            <span className="tag">by {['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][task.deadlineMonth-1]}</span>
          )}
          {task.carryover && (
            <span className="tag carryover">
              <Icon.Carryover /> carried over from {task.carryover}
            </span>
          )}
          {status === 'backlog' && task.failedAt && (
            <span className="tag" style={{ color: 'var(--backlog)' }}>missed {task.failedAt}</span>
          )}
        </div>
      </div>
      <div className="task-aside">
        {status === 'backlog' && (
          <button className="btn warn sm" onClick={() => onReplan && onReplan(task)}>Reschedule</button>
        )}
      </div>
    </div>
  );
};

const SectionHeader = ({ title, meta }) => (
  <div className="section-header">
    <h2 className="section-title">{title}</h2>
    {meta && <span className="section-meta">{meta}</span>}
  </div>
);

const QuickAdd = ({ label = 'New task' }) => (
  <div className="quick-add" onClick={() => window.openCmdK && window.openCmdK()}>
    <span className="quick-add-plus">+</span>
    <span>{label}</span>
    <span style={{ marginLeft: 'auto', display: 'flex', gap: 4 }}>
      <span className="kbd">⌘</span><span className="kbd">K</span>
    </span>
  </div>
);

Object.assign(window, { LevelBadge, Checkbox, TaskRow, SectionHeader, QuickAdd });
