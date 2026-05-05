// modals.jsx — Replan modal + Command palette + Auth screens

const ReplanModal = ({ task, onClose, onConfirm }) => {
  const [level, setLevel] = React.useState(task ? task.level : 'week');
  const [period, setPeriod] = React.useState('current');
  if (!task) return null;
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-eyebrow">Reschedule from backlog</div>
          <h2 className="modal-title">Where does <em>"{task.title}"</em> belong now?</h2>
        </div>
        <div className="modal-body">
          <div style={{ marginBottom: 18 }}>
            <div className="label">New level</div>
            <div style={{ display: 'flex', gap: 6 }}>
              {['day','week','month','year'].map(l => (
                <button
                  key={l}
                  className={`chip ${level === l ? 'active' : ''} level-${l}`}
                  onClick={() => setLevel(l)}
                >{l}</button>
              ))}
            </div>
          </div>
          <div style={{ marginBottom: 18 }}>
            <div className="label">Period</div>
            <div style={{ display: 'flex', gap: 6 }}>
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
            background: 'var(--paper)',
            border: '1px solid var(--rule)',
            borderRadius: 'var(--r-md)',
            padding: '12px 14px',
            fontSize: 12.5,
            color: 'var(--ink-3)',
            fontStyle: 'italic',
            fontFamily: 'var(--font-display)',
            lineHeight: 1.5,
          }}>
            The previous period will be archived as a failure. This is recorded in your stats, on purpose.
          </div>
        </div>
        <div className="modal-footer">
          <button className="btn ghost" onClick={onClose}>Cancel</button>
          <button className="btn" onClick={() => { onConfirm && onConfirm(task, 'archive'); onClose(); }}>Discard instead</button>
          <button className="btn primary" onClick={() => { onConfirm && onConfirm(task, 'replan', { level, period }); onClose(); }}>
            Replan to new {level}
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
            <div className="cmdk-row-label">Level</div>
            {['day','week','month','year'].map(l => (
              <button key={l} className={`chip ${level === l ? 'active' : ''} level-${l}`} onClick={() => setLevel(l)}>{l}</button>
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
            <button className={`chip ${!recurring ? 'active' : ''}`} onClick={() => setRecurring(false)}>once</button>
            <button className={`chip ${recurring ? 'active' : ''}`} onClick={() => setRecurring(true)}>recurring</button>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 6, borderTop: '1px solid var(--rule)', marginTop: 4 }}>
            <div className="mono" style={{ fontSize: 11, color: 'var(--ink-4)', letterSpacing: '0.04em' }}>
              <span className="kbd">↵</span> save · <span className="kbd">esc</span> cancel
            </div>
            <button className="btn primary sm" onClick={submit} disabled={!title.trim()}>Add task</button>
          </div>
        </div>
      </div>
    </div>
  );
};

const LoginScreen = ({ onSwitch, onSubmit }) => (
  <div className="auth-wrap">
    <div className="auth-left">
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span style={{
          fontFamily: 'var(--font-display)',
          fontStyle: 'italic',
          fontSize: 26,
          fontWeight: 500,
          color: 'var(--paper)',
          letterSpacing: '-0.02em',
        }}>Locus</span>
        <span style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--year)' }} />
      </div>
      <div className="auth-pull-quote">
        Discipline is not <em>punishment.</em><br/>
        It is the quiet <span className="accent">privilege</span><br/>
        of choosing what you keep.
      </div>
      <div className="mono" style={{ fontSize: 11, color: 'rgba(244, 241, 234, 0.5)', letterSpacing: '0.12em', textTransform: 'uppercase' }}>
        © 2026 — a tool for self-honesty
      </div>
    </div>
    <div className="auth-right">
      <div className="auth-form">
        <h1 className="auth-title">Welcome <em>back.</em></h1>
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
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span style={{
          fontFamily: 'var(--font-display)',
          fontStyle: 'italic',
          fontSize: 26,
          fontWeight: 500,
          color: 'var(--paper)',
          letterSpacing: '-0.02em',
        }}>Locus</span>
        <span style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--year)' }} />
      </div>
      <div className="auth-pull-quote">
        Begin <em>where you stand.</em><br/>
        Locus will hold you to <span className="accent">what you</span><br/>
        <span className="accent">said</span> you wanted.
      </div>
      <div className="mono" style={{ fontSize: 11, color: 'rgba(244, 241, 234, 0.5)', letterSpacing: '0.12em', textTransform: 'uppercase' }}>
        Three rules · honesty · consistency · review
      </div>
    </div>
    <div className="auth-right">
      <div className="auth-form">
        <h1 className="auth-title">A <em>new</em> account.</h1>
        <p className="auth-sub">Free, for as long as you'll use it.</p>
        <div className="auth-field">
          <label className="label">Name</label>
          <input className="input" defaultValue="" placeholder="What should we call you?" />
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
