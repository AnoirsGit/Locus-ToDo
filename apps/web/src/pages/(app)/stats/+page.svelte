<script lang="ts">
  import { onMount } from 'svelte'
  import { statsApi, type StatsData, type PeriodStat } from '$shared/api/stats.api'
  import { i18n } from '$shared/lib/i18n'

  const NOW = new Date()
  const today = NOW.toISOString().split('T')[0]

  let data    = $state<StatsData | null>(null)
  let loading = $state(true)
  let error   = $state<string | null>(null)

  onMount(async () => {
    try {
      data = await statsApi.get(today)
    } catch (e: any) {
      error = e.message ?? 'Failed to load stats'
    } finally {
      loading = false
    }
  })

  // ── Label helpers ─────────────────────────────────────────────────────────

  const addDays = (iso: string, n: number) => {
    const d = new Date(iso + 'T00:00:00Z')
    d.setUTCDate(d.getUTCDate() + n)
    return d.toISOString().split('T')[0]
  }

  const shortDate = (iso: string) =>
    new Date(iso + 'T00:00:00Z').toLocaleDateString(i18n.locale, { day: 'numeric', month: 'short', timeZone: 'UTC' })

  const weekLabel = (start: string) => `${shortDate(start)} – ${shortDate(addDays(start, 6))}`

  const monthLabel = (iso: string) => {
    const d = new Date(iso + 'T00:00:00Z')
    const sameYear = d.getUTCFullYear() === NOW.getUTCFullYear()
    return d.toLocaleDateString(i18n.locale, { month: 'short', year: sameYear ? undefined : 'numeric', timeZone: 'UTC' })
  }

  // ── Derived trend with "current" row prepended ────────────────────────────

  const pct = (done: number, total: number) => total > 0 ? Math.round((done / total) * 100) : 0

  type TrendRow = PeriodStat & { label: string; pct: number; current?: boolean }

  const weekTrendRows = $derived.by((): TrendRow[] => {
    if (!data) return []
    const currentWeekStart = (() => {
      const dow = NOW.getUTCDay()
      const d = new Date(NOW)
      d.setUTCDate(NOW.getUTCDate() + (dow === 0 ? -6 : 1 - dow))
      return d.toISOString().split('T')[0]
    })()
    const cur: TrendRow = {
      periodStart: currentWeekStart,
      label: weekLabel(currentWeekStart),
      done: data.snapshot.week.done,
      total: data.snapshot.week.total,
      pct: pct(data.snapshot.week.done, data.snapshot.week.total),
      current: true,
    }
    const hist = data.weekTrend.map(s => ({ ...s, label: weekLabel(s.periodStart), pct: pct(s.done, s.total) }))
    return [cur, ...hist]
  })

  const monthTrendRows = $derived.by((): TrendRow[] => {
    if (!data) return []
    const currentMonthStart = `${NOW.getUTCFullYear()}-${String(NOW.getUTCMonth() + 1).padStart(2, '0')}-01`
    const cur: TrendRow = {
      periodStart: currentMonthStart,
      label: monthLabel(currentMonthStart),
      done: data.snapshot.month.done,
      total: data.snapshot.month.total,
      pct: pct(data.snapshot.month.done, data.snapshot.month.total),
      current: true,
    }
    const hist = data.monthTrend.map(s => ({ ...s, label: monthLabel(s.periodStart), pct: pct(s.done, s.total) }))
    return [cur, ...hist]
  })

  const yearRows = $derived.by((): TrendRow[] => {
    if (!data) return []
    return data.yearHistory.map(s => ({
      ...s,
      label: String(new Date(s.periodStart + 'T00:00:00Z').getUTCFullYear()),
      pct: pct(s.done, s.total),
    }))
  })

  // ── UI helpers ────────────────────────────────────────────────────────────

  const pctColor = (p: number) =>
    p >= 80 ? 'bar-success' : p >= 50 ? 'bar-warning' : p > 0 ? 'bar-danger' : 'bar-empty'

  const pctTextColor = (p: number) =>
    p >= 80 ? 'text-success' : p >= 50 ? 'text-warning' : p > 0 ? 'text-danger' : 'text-muted'
</script>

<div class="main-inner">

  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">{i18n.locale === 'ru' ? 'ОБЗОР' : 'OVERVIEW'}</div>
      <h1 class="page-title"><em>{i18n.locale === 'ru' ? 'Статистика' : 'Statistics'}</em></h1>
    </div>
  </div>

  {#if loading}
    <div class="empty"><p class="text-muted">{i18n.t('action.loading')}</p></div>

  {:else if error || !data}
    <div class="empty">
      <p class="empty-title">{i18n.locale === 'ru' ? 'Ошибка загрузки' : 'Failed to load'}</p>
      <p class="empty-body">{error}</p>
    </div>

  {:else}

    <!-- ── Snapshot cards ─────────────────────────────────────────────────── -->
    <section class="section">
      <div class="snap-grid">

        <div class="snap-card level-day">
          <div class="snap-label">{i18n.locale === 'ru' ? 'Сегодня' : 'Today'}</div>
          <div class="snap-nums">
            <span class="snap-done">{data.snapshot.today.done}</span>
            <span class="snap-total">/{data.snapshot.today.total}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill day" style="width:{pct(data.snapshot.today.done, data.snapshot.today.total)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(data.snapshot.today.done, data.snapshot.today.total)}%</span>
            {#if data.snapshot.today.overdue > 0}
              <span class="snap-penalty">{data.snapshot.today.overdue} overdue</span>
            {/if}
          </div>
        </div>

        <div class="snap-card level-week">
          <div class="snap-label">{i18n.locale === 'ru' ? 'Эта неделя' : 'This week'}</div>
          <div class="snap-nums">
            <span class="snap-done">{data.snapshot.week.done}</span>
            <span class="snap-total">/{data.snapshot.week.total}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill week" style="width:{pct(data.snapshot.week.done, data.snapshot.week.total)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(data.snapshot.week.done, data.snapshot.week.total)}%</span>
            {#if data.snapshot.week.overdue > 0}
              <span class="snap-penalty">{data.snapshot.week.overdue} overdue</span>
            {/if}
          </div>
        </div>

        <div class="snap-card level-month">
          <div class="snap-label">{i18n.locale === 'ru' ? 'Этот месяц' : 'This month'}</div>
          <div class="snap-nums">
            <span class="snap-done">{data.snapshot.month.done}</span>
            <span class="snap-total">/{data.snapshot.month.total}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill month" style="width:{pct(data.snapshot.month.done, data.snapshot.month.total)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(data.snapshot.month.done, data.snapshot.month.total)}%</span>
          </div>
        </div>

        <div class="snap-card level-year">
          <div class="snap-label">{NOW.getUTCFullYear()}</div>
          <div class="snap-nums">
            <span class="snap-done">{data.snapshot.year.done}</span>
            <span class="snap-total">/{data.snapshot.year.total}</span>
          </div>
          <div class="snap-bar-track">
            <div class="snap-bar-fill year" style="width:{pct(data.snapshot.year.done, data.snapshot.year.total)}%"></div>
          </div>
          <div class="snap-meta">
            <span class="snap-pct">{pct(data.snapshot.year.done, data.snapshot.year.total)}%</span>
          </div>
        </div>

      </div>
    </section>

    <!-- ── Weekly trend ──────────────────────────────────────────────────── -->
    {#if weekTrendRows.some(s => s.total > 0)}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.locale === 'ru' ? 'По неделям' : 'Weekly trend'}</h2>
        </div>
        <div class="trend-list">
          {#each weekTrendRows.filter(s => s.total > 0 || s.current) as stat}
            <div class="trend-row" class:trend-current={stat.current}>
              <div class="trend-label">
                {stat.label}
                {#if stat.current}
                  <span class="trend-now">{i18n.locale === 'ru' ? 'сейчас' : 'now'}</span>
                {/if}
              </div>
              <div class="trend-bar-wrap">
                <div class="trend-bar-track">
                  <div class="trend-bar-fill {pctColor(stat.pct)}" style="width:{stat.pct}%"></div>
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

    <!-- ── Monthly trend ─────────────────────────────────────────────────── -->
    {#if monthTrendRows.some(s => s.total > 0)}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.locale === 'ru' ? 'По месяцам' : 'Monthly trend'}</h2>
        </div>
        <div class="trend-list">
          {#each monthTrendRows.filter(s => s.total > 0 || s.current) as stat}
            <div class="trend-row" class:trend-current={stat.current}>
              <div class="trend-label">
                {stat.label}
                {#if stat.current}
                  <span class="trend-now">{i18n.locale === 'ru' ? 'сейчас' : 'now'}</span>
                {/if}
              </div>
              <div class="trend-bar-wrap">
                <div class="trend-bar-track">
                  <div class="trend-bar-fill {pctColor(stat.pct)}" style="width:{stat.pct}%"></div>
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

    <!-- ── Year history ──────────────────────────────────────────────────── -->
    {#if yearRows.length > 0}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.locale === 'ru' ? 'По годам' : 'Year history'}</h2>
        </div>
        <div class="trend-list">
          {#each yearRows as stat}
            <div class="trend-row">
              <div class="trend-label">{stat.label}</div>
              <div class="trend-bar-wrap">
                <div class="trend-bar-track">
                  <div class="trend-bar-fill {pctColor(stat.pct)}" style="width:{stat.pct}%"></div>
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

    {#if weekTrendRows.every(s => s.total === 0) && monthTrendRows.every(s => s.total === 0) && yearRows.length === 0}
      <div class="empty">
        <p class="empty-title">{i18n.locale === 'ru' ? 'Нет данных' : 'No history yet'}</p>
        <p class="empty-body">{i18n.locale === 'ru' ? 'Статистика появится после первых архивных периодов' : 'Stats will appear after your first archived periods'}</p>
      </div>
    {/if}

  {/if}
</div>

<style>
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
  .snap-label { font-size: 10px; font-weight: 600; letter-spacing: 0.7px; text-transform: uppercase; color: var(--color-muted); }
  .snap-nums  { display: flex; align-items: baseline; gap: 1px; }
  .snap-done  { font-size: 28px; font-weight: 600; color: var(--color-text-strong); line-height: 1; }
  .snap-total { font-size: 14px; color: var(--color-muted); }
  .snap-bar-track { height: 4px; background: var(--color-border); border-radius: 2px; overflow: hidden; margin: 2px 0; }
  .snap-bar-fill  { height: 100%; border-radius: 2px; transition: width 0.4s ease; }
  .snap-bar-fill.day   { background: var(--color-day); }
  .snap-bar-fill.week  { background: var(--color-week); }
  .snap-bar-fill.month { background: var(--color-month); }
  .snap-bar-fill.year  { background: var(--color-year); }
  .snap-meta    { display: flex; align-items: center; gap: 8px; }
  .snap-pct     { font-size: 12px; font-weight: 500; color: var(--color-muted); }
  .snap-penalty { font-size: 10.5px; color: var(--color-danger); }
  .level-day   { border-left: 3px solid var(--color-day); }
  .level-week  { border-left: 3px solid var(--color-week); }
  .level-month { border-left: 3px solid var(--color-month); }
  .level-year  { border-left: 3px solid var(--color-year); }

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
  @media (max-width: 480px) { .trend-row { grid-template-columns: 120px 1fr auto; gap: 8px; } }
  .trend-current .trend-label { color: var(--color-text-strong); font-weight: 500; }
  .trend-label { font-size: 12px; color: var(--color-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: flex; align-items: center; gap: 6px; }
  .trend-now { font-size: 9px; font-weight: 600; letter-spacing: 0.6px; text-transform: uppercase; color: var(--color-brand); background: var(--color-brand-soft); padding: 1px 5px; border-radius: 2px; }
  .trend-bar-wrap { min-width: 0; }
  .trend-bar-track { height: 6px; background: var(--color-border); border-radius: 3px; overflow: hidden; }
  .trend-bar-fill  { height: 100%; border-radius: 3px; transition: width 0.4s ease; min-width: 2px; }
  .bar-success { background: var(--color-success); }
  .bar-warning { background: var(--color-warning); }
  .bar-danger  { background: var(--color-danger); }
  .bar-empty   { background: var(--color-border-2); width: 2px !important; }
  .trend-right { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; min-width: 56px; }
  .trend-pct   { font-size: 12px; font-weight: 600; }
  .trend-count { font-size: 10.5px; color: var(--color-muted); font-variant-numeric: tabular-nums; }

  :global(.text-success) { color: var(--color-success) !important; }
  :global(.text-warning) { color: var(--color-warning) !important; }
  :global(.text-danger)  { color: var(--color-danger) !important; }
</style>
