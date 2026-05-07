<script lang="ts">
  import { onMount } from 'svelte'

  let theme = $state('light')

  onMount(() => {
    theme = document.documentElement.dataset.theme ?? 'light'
  })
</script>

<svelte:head>
  <title>Locus — How it works</title>
</svelte:head>

<div class="docs-page">

  <!-- Nav -->
  <nav class="docs-nav">
    <a href="/" class="docs-brand">
      <span class="docs-brand-name">Locus</span>
      <span class="docs-brand-dot"></span>
    </a>
    <div class="docs-nav-links">
      <a href="#overview">Overview</a>
      <a href="#horizons">Time horizons</a>
      <a href="#lifecycle">Task lifecycle</a>
      <a href="#recurring">Recurring</a>
      <a href="#views">Views</a>
      <a href="#planned">Planned</a>
    </div>
    <a href="/today" class="docs-cta">Open app →</a>
  </nav>

  <main class="docs-main">

    <!-- Hero -->
    <section class="docs-hero">
      <div class="docs-hero-eyebrow">Documentation</div>
      <h1 class="docs-hero-title">How <em>Locus</em> works</h1>
      <p class="docs-hero-sub">
        Locus is a structured self-discipline tool. Tasks live inside time horizons —
        year → month → week → day — and move through a defined lifecycle. Nothing gets quietly forgotten.
      </p>
    </section>

    <!-- Overview -->
    <section class="docs-section" id="overview">
      <h2 class="docs-h2">Overview</h2>
      <p>
        Locus organises your work around <strong>four time horizons</strong>: year, month, week, and day.
        Each task belongs to exactly one horizon (its <em>level</em>). A task's level determines how long
        its active period lasts and when the scheduler processes it.
      </p>
      <p>
        The central idea: ambitious goals at the top (year), broken into monthly milestones, weekly
        deliverables, and daily actions at the bottom. The Today view shows all four horizons at once
        so you always see the full context.
      </p>

      <div class="docs-callout docs-callout-info">
        <strong>Key principle:</strong> tasks are not deleted when they fail — they are archived with
        an outcome record. This gives you honest long-term stats instead of a clean slate.
      </div>
    </section>

    <!-- Time horizons -->
    <section class="docs-section" id="horizons">
      <h2 class="docs-h2">Time horizons</h2>

      <div class="docs-horizon-grid">

        <div class="docs-horizon-card docs-horizon-day">
          <div class="docs-horizon-badge">Day</div>
          <div class="docs-horizon-period">Period: 1 day</div>
          <p class="docs-horizon-desc">
            Single-day tasks. Appear in the Today view and the Day column of the Week view.
            Can have a scheduled time (shown as a chip on the card). Missed day tasks enter
            a 1-day <em>overdue</em> period, then move to Backlog.
          </p>
          <ul class="docs-horizon-features">
            <li>Optional scheduled time</li>
            <li>Visible in Today + Week views</li>
            <li>Can recur daily</li>
          </ul>
        </div>

        <div class="docs-horizon-card docs-horizon-week">
          <div class="docs-horizon-badge">Week</div>
          <div class="docs-horizon-period">Period: Mon → Sun</div>
          <p class="docs-horizon-desc">
            Weekly tasks. A week always starts on Monday. You can pin a task to a specific
            day of the week (<em>target day</em>) — it shows up in that day's column.
            Missed week tasks get a 7-day overdue window.
          </p>
          <ul class="docs-horizon-features">
            <li>Optional target day (Mon–Sun)</li>
            <li>Optional scheduled time</li>
            <li>Can recur weekly (specific day of week)</li>
          </ul>
        </div>

        <div class="docs-horizon-card docs-horizon-month">
          <div class="docs-horizon-badge">Month</div>
          <div class="docs-horizon-period">Period: 1st → last day</div>
          <p class="docs-horizon-desc">
            Monthly goals. Shown in the Month view and as context in Today.
            Missed month tasks get a 30-day overdue window.
          </p>
          <ul class="docs-horizon-features">
            <li>No time or target date</li>
            <li>Can recur monthly (specific day of month)</li>
          </ul>
        </div>

        <div class="docs-horizon-card docs-horizon-year">
          <div class="docs-horizon-badge">Year</div>
          <div class="docs-horizon-period">Period: Jan 1 → Dec 31</div>
          <p class="docs-horizon-desc">
            Annual objectives. You can set a <em>deadline month</em> — a soft target within
            the year. Shown in the Year view and as top-level context in Today.
          </p>
          <ul class="docs-horizon-features">
            <li>Optional deadline month</li>
            <li>Can recur yearly</li>
          </ul>
        </div>

      </div>
    </section>

    <!-- Lifecycle -->
    <section class="docs-section" id="lifecycle">
      <h2 class="docs-h2">Task lifecycle</h2>
      <p>
        Every task has a <strong>period</strong> — a DB record that tracks the task's status
        within a specific time window. The scheduler runs nightly and advances statuses automatically.
      </p>

      <div class="docs-flow">
        <div class="docs-flow-step docs-flow-todo">
          <div class="docs-flow-icon">●</div>
          <div>
            <strong>Todo</strong>
            <p>Active, not yet done. The checkbox is unchecked. You can toggle it done and back freely.</p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓</div>
        <div class="docs-flow-step docs-flow-done">
          <div class="docs-flow-icon">✓</div>
          <div>
            <strong>Done</strong>
            <p>Checkbox checked within the period. At period end, the scheduler archives it as <em>on-time</em>. Unchecking reverts to todo.</p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓ (if period ends undone)</div>
        <div class="docs-flow-step docs-flow-overdue">
          <div class="docs-flow-icon">!</div>
          <div>
            <strong>Overdue</strong>
            <p>
              The period expired with the task incomplete. A penalty period is created with the same
              duration. You still have a chance to complete it — archiving it as <em>late</em>.
            </p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓ (if overdue period ends undone)</div>
        <div class="docs-flow-step docs-flow-backlog">
          <div class="docs-flow-icon">⋯</div>
          <div>
            <strong>Backlog</strong>
            <p>
              Task was not completed during overdue. It sits in the Backlog view with no active period.
              From here you can <strong>Replan</strong> it — pick a new period and it gets a fresh start.
              The failed overdue period is archived as a failure.
            </p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓ (at period end)</div>
        <div class="docs-flow-step docs-flow-archived">
          <div class="docs-flow-icon">▣</div>
          <div>
            <strong>Archived</strong>
            <p>Terminal state. The outcome is derived from <code>done_at</code>:</p>
            <ul>
              <li><em>On time</em> — done within the original period</li>
              <li><em>Late</em> — done during the overdue window</li>
              <li><em>Failed</em> — <code>done_at</code> is null (never completed)</li>
            </ul>
            <p>Archived tasks cannot be deleted — they are historical records.</p>
          </div>
        </div>
      </div>

      <div class="docs-callout docs-callout-warn">
        <strong>Hard delete rule:</strong> a task can only be deleted if it has <em>no archived periods</em>.
        Tasks with history must be archived instead.
      </div>
    </section>

    <!-- Recurring -->
    <section class="docs-section" id="recurring">
      <h2 class="docs-h2">Recurring tasks</h2>
      <p>
        Enable <strong>Recurring</strong> when creating or editing a task. Recurring tasks behave
        differently from regular ones — the scheduler handles them automatically without moving
        them through overdue/backlog.
      </p>

      <div class="docs-table-wrap">
        <table class="docs-table">
          <thead>
            <tr>
              <th>Level</th>
              <th>Config</th>
              <th>What happens at period end</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><span class="docs-level-badge docs-level-day">Day</span></td>
              <td>No extra config</td>
              <td>Current period archived; new todo period created for tomorrow</td>
            </tr>
            <tr>
              <td><span class="docs-level-badge docs-level-week">Week</span></td>
              <td>Day of week (default: Monday)</td>
              <td>Current period archived; new todo created for next week</td>
            </tr>
            <tr>
              <td><span class="docs-level-badge docs-level-month">Month</span></td>
              <td>Day of month (e.g. 1st)</td>
              <td>Current period archived; new todo created for next month</td>
            </tr>
            <tr>
              <td><span class="docs-level-badge docs-level-year">Year</span></td>
              <td>—</td>
              <td>Current period archived; new todo created for next year</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p>
        Recurring tasks are tracked separately in stats as <strong>Consistency %</strong>
        (how often you completed them), whereas one-off tasks show <strong>Completion %</strong>.
      </p>
    </section>

    <!-- Views -->
    <section class="docs-section" id="views">
      <h2 class="docs-h2">Views</h2>

      <div class="docs-views-grid">
        <div class="docs-view-card">
          <div class="docs-view-title">Today</div>
          <p>Your command centre. Shows day tasks for today plus week / month / year tasks as context. Progress bar tracks today's day tasks.</p>
        </div>
        <div class="docs-view-card">
          <div class="docs-view-title">Week</div>
          <p>7-column layout (Mon–Sun). Day tasks appear in their column, or in the target-day column if set. Week tasks shown in a panel below.</p>
        </div>
        <div class="docs-view-card">
          <div class="docs-view-title">Month</div>
          <p>All active month-level tasks. Shows deadline month if set.</p>
        </div>
        <div class="docs-view-card">
          <div class="docs-view-title">Year</div>
          <p>All active year-level tasks. Shows deadline month chip.</p>
        </div>
        <div class="docs-view-card">
          <div class="docs-view-title">Backlog</div>
          <p>Tasks that missed their overdue window. Use Replan to assign a new period.</p>
        </div>
        <div class="docs-view-card">
          <div class="docs-view-title">Archive</div>
          <p>Read-only history of all completed/failed periods. Paginated, newest first.</p>
        </div>
      </div>
    </section>

    <!-- Planned -->
    <section class="docs-section" id="planned">
      <h2 class="docs-h2">Planned features</h2>
      <p>These are confirmed roadmap items — not yet shipped.</p>

      <div class="docs-planned-list">

        <div class="docs-planned-item">
          <div class="docs-planned-header">
            <span class="docs-planned-tag">Mobile</span>
            <span class="docs-planned-title">Offline mode + smart sync</span>
          </div>
          <p>
            The mobile app will store all tasks locally (SQLite via Drift) so it works without internet.
            Writes — including toggling a task done — go to the local database immediately, then queue for
            background sync. The outbox retries automatically with exponential backoff. On conflict, the
            server wins.
          </p>
          <ul>
            <li>Instant UI response — no spinner on toggle</li>
            <li>Persistent outbox survives app restarts</li>
            <li>Background merge on reconnect</li>
          </ul>
        </div>

        <div class="docs-planned-item">
          <div class="docs-planned-header">
            <span class="docs-planned-tag">Mobile</span>
            <span class="docs-planned-title">Pre-deadline notifications</span>
          </div>
          <p>
            For tasks with a scheduled time, a local notification fires X minutes before (default 30 min,
            user-configurable). The notification is cancelled automatically if you mark the task done first.
            Scheduled locally — no server-side push infrastructure needed for MVP.
          </p>
          <ul>
            <li>Only for tasks with <code>scheduled_time</code> set</li>
            <li>Cancelled on toggle-done</li>
            <li>Configurable lead time per user</li>
          </ul>
        </div>

        <div class="docs-planned-item">
          <div class="docs-planned-header">
            <span class="docs-planned-tag">Mobile</span>
            <span class="docs-planned-title">Evening summary notification</span>
          </div>
          <p>
            A daily notification at a user-chosen time (default 20:00) shows the count of pending tasks
            for today — e.g. <em>"3 tasks still pending today"</em>. Skipped automatically if all tasks
            are already done. Recalculated each morning when the app opens.
          </p>
          <ul>
            <li>Configurable time (default 20:00)</li>
            <li>Counts <code>todo</code> + <code>overdue</code> day tasks</li>
            <li>Silent if nothing is pending</li>
          </ul>
        </div>

        <div class="docs-planned-item">
          <div class="docs-planned-header">
            <span class="docs-planned-tag">All platforms</span>
            <span class="docs-planned-title">Subtasks</span>
          </div>
          <p>
            Tasks can contain subtasks. A subtask's level is always ≤ the parent's level
            (day task → day subtasks only; month task → month, week, or day subtasks).
            Subtasks are not recurring and do not get their own scheduler lifecycle — they inherit
            the parent period.
          </p>
        </div>

        <div class="docs-planned-item">
          <div class="docs-planned-header">
            <span class="docs-planned-tag">All platforms</span>
            <span class="docs-planned-title">Recurring: multiple days per week</span>
          </div>
          <p>
            Recurring week tasks will support selecting multiple days (e.g. Mon + Wed + Fri), up to 6.
            Currently limited to one day per week.
          </p>
        </div>

      </div>
    </section>

    <!-- Footer -->
    <footer class="docs-footer">
      <span>Locus — built for focus</span>
      <a href="/today">Open app →</a>
    </footer>

  </main>
</div>

<style>
  /* ── Layout ── */
  .docs-page {
    font-family: var(--font-sans);
    color: var(--color-text);
    min-height: 100vh;
  }

  /* ── Nav ── */
  .docs-nav {
    display: flex; align-items: center; gap: 24px;
    padding: 0 40px; height: 56px;
    border-bottom: 1px solid var(--color-border);
    background: var(--color-card);
    position: sticky; top: 0; z-index: 10;
  }
  .docs-brand { display: flex; align-items: baseline; gap: 5px; text-decoration: none; }
  .docs-brand-name {
    font-family: var(--font-display); font-style: italic; font-size: 20px;
    font-weight: 500; color: var(--color-text-strong); letter-spacing: -0.02em;
  }
  .docs-brand-dot {
    width: 5px; height: 5px; border-radius: 50%;
    background: var(--color-year); flex-shrink: 0; margin-bottom: 2px;
  }
  .docs-nav-links {
    display: flex; gap: 4px; flex: 1;
  }
  .docs-nav-links a {
    padding: 4px 10px; border-radius: var(--r-sm);
    font-size: 13px; color: var(--color-text-2); text-decoration: none;
    transition: color 80ms, background 80ms;
  }
  .docs-nav-links a:hover { color: var(--color-text); background: var(--color-surface); }
  .docs-cta {
    font-size: 13px; font-weight: 500; color: var(--color-brand);
    text-decoration: none; white-space: nowrap;
    padding: 5px 12px; border: 1px solid var(--color-brand);
    border-radius: var(--r-sm); transition: background 80ms;
  }
  .docs-cta:hover { background: var(--color-brand-soft); }

  @media (max-width: 640px) {
    .docs-nav { padding: 0 16px; gap: 12px; }
    .docs-nav-links { display: none; }
  }

  /* ── Main ── */
  .docs-main { max-width: 820px; margin: 0 auto; padding: 0 40px 80px; }
  @media (max-width: 640px) { .docs-main { padding: 0 16px 60px; } }

  /* ── Hero ── */
  .docs-hero {
    padding: 64px 0 48px;
    border-bottom: 1px solid var(--color-border);
    margin-bottom: 56px;
  }
  .docs-hero-eyebrow {
    font-family: var(--font-mono); font-size: 11px; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.14em; color: var(--color-muted);
    margin-bottom: 12px;
  }
  .docs-hero-title {
    font-family: var(--font-display); font-size: 48px; font-weight: 400;
    letter-spacing: -0.025em; line-height: 1.05; color: var(--color-text-strong);
    margin: 0 0 16px;
  }
  .docs-hero-title em { font-style: italic; }
  .docs-hero-sub {
    font-size: 16px; line-height: 1.65; color: var(--color-text-2);
    max-width: 560px; margin: 0;
  }

  /* ── Sections ── */
  .docs-section { margin-bottom: 72px; }
  .docs-h2 {
    font-family: var(--font-display); font-size: 28px; font-weight: 400;
    letter-spacing: -0.015em; color: var(--color-text-strong);
    margin: 0 0 20px; padding-bottom: 12px;
    border-bottom: 1px solid var(--color-border);
  }
  .docs-section p {
    font-size: 14px; line-height: 1.7; color: var(--color-text-2); margin: 0 0 14px;
  }
  .docs-section strong { color: var(--color-text-strong); }
  .docs-section em { color: var(--color-text); }
  .docs-section ul {
    padding-left: 20px; margin: 8px 0 14px;
    font-size: 13.5px; line-height: 1.65; color: var(--color-text-2);
  }
  .docs-section li { margin-bottom: 4px; }
  .docs-section code {
    font-family: var(--font-mono); font-size: 12px;
    background: var(--color-surface-2); padding: 1px 5px; border-radius: 3px;
    color: var(--color-text);
  }

  /* ── Callout ── */
  .docs-callout {
    border-left: 3px solid; border-radius: 0 var(--r-md) var(--r-md) 0;
    padding: 12px 16px; margin: 20px 0;
    font-size: 13.5px; line-height: 1.6;
  }
  .docs-callout-info {
    border-color: var(--color-brand); background: var(--color-brand-soft);
    color: var(--color-text-2);
  }
  .docs-callout-warn {
    border-color: var(--color-warning); background: var(--color-warning-tint);
    color: var(--color-warning-ink);
  }
  .docs-callout strong { color: inherit; }

  /* ── Horizon cards ── */
  .docs-horizon-grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 24px;
  }
  @media (max-width: 640px) { .docs-horizon-grid { grid-template-columns: 1fr; } }

  .docs-horizon-card {
    border: 1px solid var(--color-border); border-radius: var(--r-lg);
    padding: 20px; background: var(--color-card);
    border-top: 3px solid;
  }
  .docs-horizon-day   { border-top-color: var(--color-day); }
  .docs-horizon-week  { border-top-color: var(--color-week); }
  .docs-horizon-month { border-top-color: var(--color-month); }
  .docs-horizon-year  { border-top-color: var(--color-year); }

  .docs-horizon-badge {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.1em;
    margin-bottom: 2px;
  }
  .docs-horizon-day   .docs-horizon-badge { color: var(--color-day); }
  .docs-horizon-week  .docs-horizon-badge { color: var(--color-week); }
  .docs-horizon-month .docs-horizon-badge { color: var(--color-month); }
  .docs-horizon-year  .docs-horizon-badge { color: var(--color-year); }

  .docs-horizon-period {
    font-family: var(--font-mono); font-size: 11px; color: var(--color-muted);
    margin-bottom: 10px;
  }
  .docs-horizon-desc { font-size: 13px; line-height: 1.6; color: var(--color-text-2); margin: 0 0 10px; }
  .docs-horizon-features {
    padding-left: 16px; margin: 0;
    font-size: 12.5px; line-height: 1.55; color: var(--color-muted);
  }
  .docs-horizon-features li { margin-bottom: 3px; }

  /* ── Flow ── */
  .docs-flow { display: flex; flex-direction: column; gap: 0; margin-top: 24px; }
  .docs-flow-step {
    display: flex; gap: 16px; align-items: flex-start;
    padding: 16px 20px; border: 1px solid var(--color-border);
    border-radius: var(--r-md); background: var(--color-card);
  }
  .docs-flow-step + .docs-flow-step { margin-top: 0; }
  .docs-flow-step p { font-size: 13px; line-height: 1.6; color: var(--color-text-2); margin: 4px 0 0; }
  .docs-flow-step ul { font-size: 13px; color: var(--color-text-2); margin: 6px 0 0; }
  .docs-flow-step strong { font-size: 14px; color: var(--color-text-strong); font-weight: 600; }

  .docs-flow-icon {
    width: 28px; height: 28px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; font-weight: 700; flex-shrink: 0; margin-top: 1px;
  }
  .docs-flow-todo    { border-left: 3px solid var(--color-border-2); }
  .docs-flow-done    { border-left: 3px solid var(--color-success); }
  .docs-flow-overdue { border-left: 3px solid var(--color-warning); }
  .docs-flow-backlog { border-left: 3px solid var(--color-muted-2); }
  .docs-flow-archived { border-left: 3px solid var(--color-muted); }

  .docs-flow-todo    .docs-flow-icon { background: var(--color-surface); color: var(--color-muted); }
  .docs-flow-done    .docs-flow-icon { background: var(--color-week-tint); color: var(--color-success); }
  .docs-flow-overdue .docs-flow-icon { background: var(--color-warning-tint); color: var(--color-warning); }
  .docs-flow-backlog .docs-flow-icon { background: var(--color-surface-2); color: var(--color-muted); }
  .docs-flow-archived .docs-flow-icon { background: var(--color-surface); color: var(--color-muted-2); }

  .docs-flow-arrow {
    font-family: var(--font-mono); font-size: 11px; color: var(--color-muted-2);
    padding: 4px 20px; letter-spacing: 0.04em;
  }

  /* ── Table ── */
  .docs-table-wrap { overflow-x: auto; margin: 20px 0; }
  .docs-table {
    width: 100%; border-collapse: collapse;
    font-size: 13px; color: var(--color-text-2);
  }
  .docs-table th {
    text-align: left; padding: 8px 14px;
    font-family: var(--font-mono); font-size: 10.5px; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.08em; color: var(--color-muted);
    border-bottom: 2px solid var(--color-border);
  }
  .docs-table td {
    padding: 10px 14px; border-bottom: 1px solid var(--color-border);
    vertical-align: top; line-height: 1.5;
  }
  .docs-table tr:last-child td { border-bottom: none; }
  .docs-table tr:hover td { background: var(--color-surface); }

  .docs-level-badge {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.06em;
    padding: 2px 7px; border-radius: 3px; white-space: nowrap;
  }
  .docs-level-day   { background: var(--color-day-tint);   color: var(--color-day); }
  .docs-level-week  { background: var(--color-week-tint);  color: var(--color-week); }
  .docs-level-month { background: var(--color-month-tint); color: var(--color-month); }
  .docs-level-year  { background: var(--color-year-tint);  color: var(--color-year); }

  /* ── Views grid ── */
  .docs-views-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; margin-top: 20px; }
  @media (max-width: 640px) { .docs-views-grid { grid-template-columns: 1fr; } }

  .docs-view-card {
    padding: 16px; border: 1px solid var(--color-border);
    border-radius: var(--r-md); background: var(--color-card);
  }
  .docs-view-title {
    font-weight: 600; font-size: 13.5px; color: var(--color-text-strong);
    margin-bottom: 6px;
  }
  .docs-view-card p { font-size: 12.5px; line-height: 1.6; color: var(--color-text-2); margin: 0; }

  /* ── Planned features ── */
  .docs-planned-list { display: flex; flex-direction: column; gap: 12px; margin-top: 20px; }

  .docs-planned-item {
    border: 1px solid var(--color-border); border-radius: var(--r-md);
    padding: 18px 20px; background: var(--color-card);
  }
  .docs-planned-header {
    display: flex; align-items: center; gap: 10px; margin-bottom: 10px;
  }
  .docs-planned-tag {
    font-family: var(--font-mono); font-size: 9.5px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.1em;
    padding: 2px 7px; border-radius: 3px;
    background: var(--color-surface-2); color: var(--color-muted);
  }
  .docs-planned-title {
    font-size: 14px; font-weight: 600; color: var(--color-text-strong);
  }
  .docs-planned-item p {
    font-size: 13px; line-height: 1.65; color: var(--color-text-2); margin: 0 0 8px;
  }
  .docs-planned-item ul {
    padding-left: 18px; margin: 0;
    font-size: 12.5px; line-height: 1.6; color: var(--color-muted);
  }
  .docs-planned-item li { margin-bottom: 3px; }

  /* ── Footer ── */
  .docs-footer {
    display: flex; align-items: center; justify-content: space-between;
    padding: 24px 0; border-top: 1px solid var(--color-border);
    font-size: 12.5px; color: var(--color-muted); margin-top: 24px;
  }
  .docs-footer a { color: var(--color-brand); text-decoration: none; }
  .docs-footer a:hover { text-decoration: underline; }
</style>
