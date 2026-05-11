<script lang="ts">
  import { taskStore } from '$entities/task'
  import type { TaskWithPeriod } from '$entities/task'
  import { i18n } from '$shared/lib/i18n'

  // ── Date helpers ─────────────────────────────────────────────────────────────

  const toISO = (d: Date) => d.toISOString().split('T')[0]
  const addDays = (iso: string, n: number) => {
    const d = new Date(iso + 'T00:00:00Z')
    d.setUTCDate(d.getUTCDate() + n)
    return toISO(d)
  }

  const NOW = new Date()

  const currentWeekStart = (() => {
    const dow = NOW.getUTCDay()
    const d = new Date(NOW)
    d.setUTCDate(NOW.getUTCDate() + (dow === 0 ? -6 : 1 - dow))
    return toISO(d)
  })()

  const currentMonthStart = `${NOW.getUTCFullYear()}-${String(NOW.getUTCMonth() + 1).padStart(2, '0')}-01`
  const currentYearStart  = `${NOW.getUTCFullYear()}-01-01`
  const today = toISO(NOW)

  // ── Label helpers ─────────────────────────────────────────────────────────────

  const shortDate = (iso: string) => {
    const d = new Date(iso + 'T00:00:00Z')
    return d.toLocaleDateString(i18n.locale, { day: 'numeric', month: 'short', timeZone: 'UTC' })
  }
  const monthLabel = (iso: string) => {
    const d = new Date(iso + 'T00:00:00Z')
    const sameYear = d.getUTCFullYear() === NOW.getUTCFullYear()
    return d.toLocaleDateString(i18n.locale, {
      month: 'short',
      year: sameYear ? undefined : 'numeric',
      timeZone: 'UTC',
    })
  }

  const weekLabel = (start: string) => `${shortDate(start)} – ${shortDate(addDays(start, 6))}`

  // ── Stat computation helpers ──────────────────────────────────────────────────

  type Stat = { label: string; start: string; done: number; total: number; pct: number; current?: boolean }

  const isActive = (t: TaskWithPeriod) =>
    t.period.status === 'todo' || t.period.status === 'done' || t.period.status === 'overdue'

  const isArchivedDone = (t: TaskWithPeriod) =>
    t.period.status === 'archived' && t.period.doneAt != null

  const pct = (done: number, total: number) => (total > 0 ? Math.round((done / total) * 100) : 0)

  // ── Current-period snapshots ──────────────────────────────────────────────────

  const todayTasks = $derived(
    taskStore.items.filter(t =>
      t.level === 'day' &&
      isActive(t) &&
      (t.period.targetDate === today || t.period.periodStart === today),
    ),
  )
  const todayDone  = $derived(todayTasks.filter(t => t.period.status === 'done').length)

  const curWeekTasks = $derived(
    taskStore.items.filter(t =>
      t.level === 'week' && isActive(t) && t.period.periodStart === currentWeekStart,
    ),
  )
  const curWeekDone = $derived(curWeekTasks.filter(t => t.period.status === 'done').length)

  // Day tasks across the whole current week
  const curWeekDayTasks = $derived(
    taskStore.items.filter(t => {
      if (t.level !== 'day' || !isActive(t)) return false
      const ps = t.period.periodStart
      return ps >= currentWeekStart && ps <= addDays(currentWeekStart, 6)
    }),
  )
  const curWeekDayDone = $derived(curWeekDayTasks.filter(t => t.period.status === 'done').length)

  const curMonthTasks = $derived(
    taskStore.items.filter(t =>
      t.level === 'month' && isActive(t) && t.period.periodStart === currentMonthStart,
    ),
  )
  const curMonthDone = $derived(curMonthTasks.filter(t => t.period.status === 'done').length)

  const curYearTasks = $derived(
    taskStore.items.filter(t =>
      t.level === 'year' && isActive(t) && t.period.periodStart === currentYearStart,
    ),
  )
  const curYearDone = $derived(curYearTasks.filter(t => t.period.status === 'done').length)

  // Overdue counts
  const overdueToday = $derived(todayTasks.filter(t => t.period.status === 'overdue').length)
  const overdueWeek  = $derived(curWeekTasks.filter(t => t.period.status === 'overdue').length)

  // ── Historical week trend ─────────────────────────────────────────────────────

  const weekTrend = $derived.by((): Stat[] => {
    const archived = taskStore.items.filter(t => t.level === 'week' && t.period.status === 'archived')
    const groups = new Map<string, TaskWithPeriod[]>()
    for (const t of archived) {
      const k = t.period.periodStart
      if (!groups.has(k)) groups.set(k, [])
      groups.get(k)!.push(t)
    }
    const hist: Stat[] = [...groups.entries()].map(([start, tasks]) => {
      const total = tasks.length
      const done  = tasks.filter(t => t.period.doneAt != null).length
      return { start, label: weekLabel(start), done, total, pct: pct(done, total) }
    })
    hist.sort((a, b) => b.start.localeCompare(a.start))
    // Add current week at top
    const cur: Stat = {
      start: currentWeekStart,
      label: weekLabel(currentWeekStart),
      done: curWeekDone,
      total: curWeekTasks.length,
      pct: pct(curWeekDone, curWeekTasks.length),
      current: true,
    }
    return [cur, ...hist.slice(0, 9)]
  })

  // ── Historical month trend ────────────────────────────────────────────────────

  const monthTrend = $derived.by((): Stat[] => {
    const archived = taskStore.items.filter(t => t.level === 'month' && t.period.status === 'archived')
    const groups = new Map<string, TaskWithPeriod[]>()
    for (const t of archived) {
      const k = t.period.periodStart
      if (!groups.has(k)) groups.set(k, [])
      groups.get(k)!.push(t)
    }
    const hist: Stat[] = [...groups.entries()].map(([start, tasks]) => {
      const total = tasks.length
      const done  = tasks.filter(t => t.period.doneAt != null).length
      return { start, label: monthLabel(start), done, total, pct: pct(done, total) }
    })
    hist.sort((a, b) => b.start.localeCompare(a.start))
    const cur: Stat = {
      start: currentMonthStart,
      label: monthLabel(currentMonthStart),
      done: curMonthDone,
      total: curMonthTasks.length,
      pct: pct(curMonthDone, curMonthTasks.length),
      current: true,
    }
    return [cur, ...hist.slice(0, 5)]
  })

  // ── Year history ──────────────────────────────────────────────────────────────

  const yearHistory = $derived.by((): Stat[] => {
    const archived = taskStore.items.filter(t => t.level === 'year' && t.period.status === 'archived')
    const groups = new Map<string, TaskWithPeriod[]>()
    for (const t of archived) {
      const k = t.period.periodStart
      if (!groups.has(k)) groups.set(k, [])
      groups.get(k)!.push(t)
    }
    return [...groups.entries()]
      .map(([start, tasks]) => {
        const total = tasks.length
        const done  = tasks.filter(t => t.period.doneAt != null).length
        const yr    = new Date(start + 'T00:00:00Z').getUTCFullYear()
        return { start, label: String(yr), done, total, pct: pct(done, total) }
      })
      .sort((a, b) => b.start.localeCompare(a.start))
  })

  // ── UI helpers ────────────────────────────────────────────────────────────────

  const pctColor = (p: number) =>
    p >= 80 ? 'bar-success' : p >= 50 ? 'bar-warning' : p > 0 ? 'bar-danger' : 'bar-empty'

  const pctTextColor = (p: number) =>
    p >= 80 ? 'text-success' : p >= 50 ? 'text-warning' : p > 0 ? 'text-danger' : 'text-muted'
</script>

<div class="main-inner">

  <!-- ── Header ─────────────────────────────────────────────────────────── -->
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">{i18n.locale === 'ru' ? 'ОБЗОР' : 'OVERVIEW'}</div>
      <h1 class="page-title"><em>{i18n.locale === 'ru' ? 'Статистика' : 'Statistics'}</em></h1>
    </div>
  </div>

  {#if taskStore.loading}
    <div class="empty"><p class="text-muted">{i18n.t('action.loading')}</p></div>
  {:else}

    <!-- ── Snapshot cards ─────────────────────────────────────────────────── -->
    <section class="section">
      <div class="snap-grid">

        <!-- Today -->
        <div class="snap-card level-day">
          <div class="snap-label">{i18n.locale === 'ru' ? 'Сегодня' : 'Today'}</div>
          <div class="snap-nums">
            <span class="snap-done">{todayDone}</span>
            <span class="snap-total">/{todayTasks.length}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill day" style="width:{pct(todayDone, todayTasks.length)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(todayDone, todayTasks.length)}%</span>
            {#if overdueToday > 0}
              <span class="snap-penalty">{overdueToday} overdue</span>
            {/if}
          </div>
        </div>

        <!-- This week -->
        <div class="snap-card level-week">
          <div class="snap-label">{i18n.locale === 'ru' ? 'Эта неделя' : 'This week'}</div>
          <div class="snap-nums">
            <span class="snap-done">{curWeekDone}</span>
            <span class="snap-total">/{curWeekTasks.length}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill week" style="width:{pct(curWeekDone, curWeekTasks.length)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(curWeekDone, curWeekTasks.length)}%</span>
            {#if overdueWeek > 0}
              <span class="snap-penalty">{overdueWeek} overdue</span>
            {/if}
          </div>
          {#if curWeekDayTasks.length > 0}
            <div class="snap-sub">
              {curWeekDayDone}/{curWeekDayTasks.length} {i18n.locale === 'ru' ? 'дн. задач' : 'day tasks'}
            </div>
          {/if}
        </div>

        <!-- This month -->
        <div class="snap-card level-month">
          <div class="snap-label">{i18n.locale === 'ru' ? 'Этот месяц' : 'This month'}</div>
          <div class="snap-nums">
            <span class="snap-done">{curMonthDone}</span>
            <span class="snap-total">/{curMonthTasks.length}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill month" style="width:{pct(curMonthDone, curMonthTasks.length)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(curMonthDone, curMonthTasks.length)}%</span>
          </div>
        </div>

        <!-- This year -->
        <div class="snap-card level-year">
          <div class="snap-label">{NOW.getUTCFullYear()}</div>
          <div class="snap-nums">
            <span class="snap-done">{curYearDone}</span>
            <span class="snap-total">/{curYearTasks.length}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill year" style="width:{pct(curYearDone, curYearTasks.length)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(curYearDone, curYearTasks.length)}%</span>
          </div>
        </div>

      </div>
    </section>

    <!-- ── Weekly trend ───────────────────────────────────────────────────── -->
    {#if weekTrend.some(s => s.total > 0)}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.locale === 'ru' ? 'По неделям' : 'Weekly trend'}</h2>
        </div>
        <div class="trend-list">
          {#each weekTrend.filter(s => s.total > 0 || s.current) as stat}
            <div class="trend-row" class:trend-current={stat.current}>
              <div class="trend-label">
                {stat.label}
                {#if stat.current}
                  <span class="trend-now">{i18n.locale === 'ru' ? 'сейчас' : 'now'}</span>
                {/if}
              </div>
              <div class="trend-bar-wrap">
                <div class="trend-bar-track">
                  <div
                    class="trend-bar-fill {pctColor(stat.pct)}"
                    style="width:{stat.pct}%"
                  ></div>
                </div>
              </div>
              <div class="trend-right">
                <span class="trend-pct {pctTextColor(stat.pct)}">{stat.pct}%</span>
                <span class="trend-count">{stat.done}/{stat.total}</span>
              </div>
            </div>
          {/each}
        </div>
      </section>
    {/if}

    <!-- ── Monthly trend ──────────────────────────────────────────────────── -->
    {#if monthTrend.some(s => s.total > 0)}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.locale === 'ru' ? 'По месяцам' : 'Monthly trend'}</h2>
        </div>
        <div class="trend-list">
          {#each monthTrend.filter(s => s.total > 0 || s.current) as stat}
            <div class="trend-row" class:trend-current={stat.current}>
              <div class="trend-label">
                {stat.label}
                {#if stat.current}
                  <span class="trend-now">{i18n.locale === 'ru' ? 'сейчас' : 'now'}</span>
                {/if}
              </div>
              <div class="trend-bar-wrap">
                <div class="trend-bar-track">
                  <div
                    class="trend-bar-fill {pctColor(stat.pct)}"
                    style="width:{stat.pct}%"
                  ></div>
                </div>
              </div>
              <div class="trend-right">
                <span class="trend-pct {pctTextColor(stat.pct)}">{stat.pct}%</span>
                <span class="trend-count">{stat.done}/{stat.total}</span>
              </div>
            </div>
          {/each}
        </div>
      </section>
    {/if}

    <!-- ── Year history ───────────────────────────────────────────────────── -->
    {#if yearHistory.length > 0}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.locale === 'ru' ? 'По годам' : 'Year history'}</h2>
        </div>
        <div class="trend-list">
          {#each yearHistory as stat}
            <div class="trend-row">
              <div class="trend-label">{stat.label}</div>
              <div class="trend-bar-wrap">
                <div class="trend-bar-track">
                  <div
                    class="trend-bar-fill {pctColor(stat.pct)}"
                    style="width:{stat.pct}%"
                  ></div>
                </div>
              </div>
              <div class="trend-right">
                <span class="trend-pct {pctTextColor(stat.pct)}">{stat.pct}%</span>
                <span class="trend-count">{stat.done}/{stat.total}</span>
              </div>
            </div>
          {/each}
        </div>
      </section>
    {/if}

    {#if weekTrend.every(s => s.total === 0) && monthTrend.every(s => s.total === 0) && yearHistory.length === 0}
      <div class="empty">
        <p class="empty-title">{i18n.locale === 'ru' ? 'Нет данных' : 'No history yet'}</p>
        <p class="empty-body">{i18n.locale === 'ru' ? 'Статистика появится после первых архивных периодов' : 'Stats will appear after your first archived periods'}</p>
      </div>
    {/if}

  {/if}
</div>

<style>
  /* ── Snapshot grid ──────────────────────────────────────────────────────── */
  .snap-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
  }
  @media (min-width: 640px) {
    .snap-grid { grid-template-columns: repeat(4, 1fr); }
  }

  .snap-card {
    background: var(--color-card);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 14px 16px;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .snap-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.7px;
    text-transform: uppercase;
    color: var(--color-muted);
  }

  .snap-nums {
    display: flex;
    align-items: baseline;
    gap: 1px;
  }
  .snap-done  { font-size: 28px; font-weight: 600; color: var(--color-text-strong); line-height: 1; }
  .snap-total { font-size: 14px; color: var(--color-muted); }

  .snap-bar-track {
    height: 4px;
    background: var(--color-border);
    border-radius: 2px;
    overflow: hidden;
    margin: 2px 0;
  }
  .snap-bar-fill {
    height: 100%;
    border-radius: 2px;
    transition: width 0.4s ease;
  }
  .snap-bar-fill.day   { background: var(--color-day); }
  .snap-bar-fill.week  { background: var(--color-week); }
  .snap-bar-fill.month { background: var(--color-month); }
  .snap-bar-fill.year  { background: var(--color-year); }

  .snap-meta {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .snap-pct { font-size: 12px; font-weight: 500; color: var(--color-muted); }
  .snap-penalty { font-size: 10.5px; color: var(--color-danger); }
  .snap-sub { font-size: 10.5px; color: var(--color-muted-2); margin-top: 2px; }

  /* Level border accent */
  .level-day   { border-left: 3px solid var(--color-day); }
  .level-week  { border-left: 3px solid var(--color-week); }
  .level-month { border-left: 3px solid var(--color-month); }
  .level-year  { border-left: 3px solid var(--color-year); }

  /* ── Trend list ─────────────────────────────────────────────────────────── */
  .trend-list { display: flex; flex-direction: column; gap: 6px; }

  .trend-row {
    display: grid;
    grid-template-columns: 160px 1fr auto;
    align-items: center;
    gap: 12px;
    padding: 8px 0;
    border-bottom: 1px solid var(--color-border);
  }
  .trend-row:last-child { border-bottom: none; }

  @media (max-width: 480px) {
    .trend-row { grid-template-columns: 120px 1fr auto; gap: 8px; }
  }

  .trend-current .trend-label { color: var(--color-text-strong); font-weight: 500; }

  .trend-label {
    font-size: 12px;
    color: var(--color-muted);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .trend-now {
    font-size: 9px;
    font-weight: 600;
    letter-spacing: 0.6px;
    text-transform: uppercase;
    color: var(--color-brand);
    background: var(--color-brand-soft);
    padding: 1px 5px;
    border-radius: 2px;
  }

  .trend-bar-wrap { min-width: 0; }
  .trend-bar-track {
    height: 6px;
    background: var(--color-border);
    border-radius: 3px;
    overflow: hidden;
  }
  .trend-bar-fill {
    height: 100%;
    border-radius: 3px;
    transition: width 0.4s ease;
    min-width: 2px;
  }
  .bar-success { background: var(--color-success); }
  .bar-warning { background: var(--color-warning); }
  .bar-danger  { background: var(--color-danger); }
  .bar-empty   { background: var(--color-border-2); width: 2px !important; }

  .trend-right {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 1px;
    min-width: 56px;
  }
  .trend-pct   { font-size: 12px; font-weight: 600; }
  .trend-count { font-size: 10.5px; color: var(--color-muted); font-variant-numeric: tabular-nums; }

  /* text color overrides (Tailwind might not reach inside <style>) */
  :global(.text-success) { color: var(--color-success) !important; }
  :global(.text-warning) { color: var(--color-warning) !important; }
  :global(.text-danger)  { color: var(--color-danger) !important; }
</style>
