// modals-jira.jsx — Replan modal + CmdK + auth (dark / Atlassian)

const ReplanModal = ({ task, onClose, onConfirm }) => {
  const [level, setLevel] = React.useState(task ? task.level : 'week');
  const [period, setPeriod] = React.useState('current');
  if (!task) return null;
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-eyebrow">Reschedule from backlog</div>
          <h2 className="modal-title">{task.title}</h2>
        </div>
        <div className="modal-body">
          <div style={{ marginBottom: 18 }}>
            <div className="label">New issue type</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {[['day','Task'],['week','Story'],['month','Epic'],['year','Initiative']].map(([l, label]) => (
                <button
                  key={l}
                  className={`chip ${level === l ? 'active' : ''} level-${l}`}
                  onClick={() => setLevel(l)}
                >{label}</button>
              ))}
            </div>
          </div>
          <div style={{ marginBottom: 18 }}>
            <div className="label">Period</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {[
                { id: 'current', label: level === 'day' ? 'Today' : level === 'week' ? 'This week' : level === 'month' ? 'This month' : 'This year' },
                { id: 'next', label: level === 'day' ? 'Tomorrow' : level === 'week' ? 'Next week' : level === 'month' ? 'Next month' : 'Next year' },
                { id: 'pick', label: 'Pick a date…' },
              ].map(p => (
                <button key={p.id} className={`chip ${period === p.id ? 'active' : ''}`} onClick={() => setPeriod(p.id)}>{p.label}</button>
              ))}
            </div>
          </div>
          <div style={{
            background: 'var(--bg-2)',
            border: '1px solid var(--line-2)',
            borderRadius: 'var(--r-md)',
            padding: '10px 14px',
            fontSize: 12.5,
            color: 'var(--text-3)',
            lineHeight: 1.5,
          }}>
            The previous period will be archived as a failure. This is recorded in your stats, on purpose.
          </div>
        </div>
        <div className="modal-footer">
          <button className="btn subtle" onClick={onClose}>Cancel</button>
          <button className="btn" onClick={() => { onConfirm && onConfirm(task, 'archive'); onClose(); }}>Discard instead</button>
          <button className="btn primary" onClick={() => { onConfirm && onConfirm(task, 'replan', { level, period }); onClose(); }}>
            Replan
          </button>
        </div>
      </div>
    </div>
  );
};

const CmdK = ({ onClose, onCreate }) => {
  const [title, setTitle] = React.useState('');
  const [level, setLevel] = React.useState('day');
  const [time, setTime] = React.useState('');
  const [recurring, setRecurring] = React.useState(false);
  const inputRef = React.useRef(null);
  React.useEffect(() => { inputRef.current && inputRef.current.focus(); }, []);

  const submit = () => {
    if (!title.trim()) return;
    onCreate && onCreate({ title, level, time, recurring });
    onClose();
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="cmdk" onClick={(e) => e.stopPropagation()}>
        <input
          ref={inputRef}
          className="cmdk-input"
          placeholder="What needs doing?"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') submit(); if (e.key === 'Escape') onClose(); }}
        />
        <div className="cmdk-options">
          <div className="cmdk-row">
            <div className="cmdk-row-label">Type</div>
            {[['day','Task'],['week','Story'],['month','Epic'],['year','Initiative']].map(([l, label]) => (
              <button key={l} className={`chip ${level === l ? 'active' : ''} level-${l}`} onClick={() => setLevel(l)}>{label}</button>
            ))}
          </div>
          {level === 'day' && (
            <div className="cmdk-row">
              <div className="cmdk-row-label">Time</div>
              {['07:00','09:00','13:00','19:00','22:00'].map(t => (
                <button key={t} className={`chip ${time === t ? 'active' : ''}`} onClick={() => setTime(time === t ? '' : t)}>{t}</button>
              ))}
              <button className={`chip ${time === 'anytime' ? 'active' : ''}`} onClick={() => setTime(time === 'anytime' ? '' : 'anytime')}>anytime</button>
            </div>
          )}
          <div className="cmdk-row">
            <div className="cmdk-row-label">Repeat</div>
            <button className={`chip ${!recurring ? 'active' : ''}`} onClick={() => setRecurring(false)}>Once</button>
            <button className={`chip ${recurring ? 'active' : ''}`} onClick={() => setRecurring(true)}>Recurring</button>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 8, borderTop: '1px solid var(--line)', marginTop: 4 }}>
            <div style={{ fontSize: 11, color: 'var(--text-4)' }}>
              <span className="kbd">↵</span> save · <span className="kbd">esc</span> cancel
            </div>
            <button className="btn primary sm" onClick={submit} disabled={!title.trim()}>Create</button>
          </div>
        </div>
      </div>
    </div>
  );
};

const AuthBrand = () => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 10, position: 'relative', zIndex: 1 }}>
    <div className="brand-logo">L</div>
    <div style={{ fontSize: 18, fontWeight: 600, color: 'var(--text-bright)', letterSpacing: '-0.01em' }}>Locus</div>
  </div>
);

const LoginScreen = ({ onSwitch, onSubmit }) => (
  <div className="auth-wrap">
    <div className="auth-left">
      <AuthBrand />
      <div className="auth-pull-quote">
        Discipline is not punishment.<br/>
        It is the quiet <span className="accent">privilege</span> of choosing what you keep.
      </div>
      <div style={{ fontSize: 11, color: 'rgba(182, 194, 207, 0.5)', letterSpacing: '0.06em', textTransform: 'uppercase', position: 'relative', zIndex: 1 }}>
        © 2026 — a tool for self-honesty
      </div>
    </div>
    <div className="auth-right">
      <div className="auth-form">
        <h1 className="auth-title">Welcome back</h1>
        <p className="auth-sub">Sign in to keep going.</p>
        <div className="auth-field">
          <label className="label">Email</label>
          <input className="input" type="email" defaultValue="lev@ostrovsky.studio" />
        </div>
        <div className="auth-field">
          <label className="label">Password</label>
          <input className="input" type="password" defaultValue="••••••••••" />
        </div>
        <button className="btn primary lg" style={{ width: '100%', justifyContent: 'center', marginTop: 8 }} onClick={onSubmit}>
          Sign in
        </button>
        <div className="auth-foot">
          New here? <a href="#" onClick={(e) => { e.preventDefault(); onSwitch('register'); }}>Create an account</a>
        </div>
      </div>
    </div>
  </div>
);

const RegisterScreen = ({ onSwitch, onSubmit }) => (
  <div className="auth-wrap">
    <div className="auth-left">
      <AuthBrand />
      <div className="auth-pull-quote">
        Begin where you stand. Locus will hold you to <span className="accent">what you said</span> you wanted.
      </div>
      <div style={{ fontSize: 11, color: 'rgba(182, 194, 207, 0.5)', letterSpacing: '0.06em', textTransform: 'uppercase', position: 'relative', zIndex: 1 }}>
        Three rules · honesty · consistency · review
      </div>
    </div>
    <div className="auth-right">
      <div className="auth-form">
        <h1 className="auth-title">Create account</h1>
        <p className="auth-sub">Free, for as long as you'll use it.</p>
        <div className="auth-field">
          <label className="label">Name</label>
          <input className="input" placeholder="What should we call you?" />
        </div>
        <div className="auth-field">
          <label className="label">Email</label>
          <input className="input" type="email" placeholder="you@somewhere.com" />
        </div>
        <div className="auth-field">
          <label className="label">Password</label>
          <input className="input" type="password" placeholder="At least 10 characters" />
        </div>
        <button className="btn primary lg" style={{ width: '100%', justifyContent: 'center', marginTop: 8 }} onClick={onSubmit}>
          Create account
        </button>
        <div className="auth-foot">
          Already enrolled? <a href="#" onClick={(e) => { e.preventDefault(); onSwitch('login'); }}>Sign in</a>
        </div>
      </div>
    </div>
  </div>
);

Object.assign(window, { ReplanModal, CmdK, LoginScreen, RegisterScreen });
