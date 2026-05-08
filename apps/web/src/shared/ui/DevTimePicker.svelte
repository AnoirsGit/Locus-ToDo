<script lang="ts">
  import { devTime } from '$shared/lib/devTime.svelte'
  import { api } from '$shared/api/client'

  let expanded = $state(false)
  let tickResult = $state<{ ok: boolean; date?: string; users?: number; error?: string } | null>(null)
  let ticking = $state(false)
  let autoTick = $state(false)

  // Local editor state
  let dateStr = $state('')
  let timeStr = $state('')

  function pad(n: number) { return String(n).padStart(2, '0') }

  function toInputs(d: Date) {
    dateStr = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
    timeStr = `${pad(d.getHours())}:${pad(d.getMinutes())}`
  }

  function open() {
    toInputs(devTime.now())
    expanded = true
  }

  async function apply(d: Date) {
    devTime.set(d)
    toInputs(d)
    if (autoTick) await runTick(d)
  }

  async function applyFromInputs() {
    const d = new Date(`${dateStr}T${timeStr}:00`)
    if (!isNaN(d.getTime())) await apply(d)
  }

  async function reset() {
    devTime.reset()
    toInputs(new Date())
    tickResult = null
  }

  // ── Quick jumps ──────────────────────────────────────────────────────────

  function jump(fn: (d: Date) => Date) {
    const next = fn(devTime.now())
    apply(next)
  }

  const jumps: { label: string; fn: (d: Date) => Date }[] = [
    { label: '+1d',  fn: (d) => addDays(d, 1) },
    { label: '+2d',  fn: (d) => addDays(d, 2) },
    { label: '+1w',  fn: (d) => addDays(d, 7) },
    { label: '+1m',  fn: (d) => addMonths(d, 1) },
    { label: '+1y',  fn: (d) => addYears(d, 1) },
    { label: 'End wk',  fn: endOfWeek },
    { label: 'End mo',  fn: endOfMonth },
    { label: 'End yr',  fn: endOfYear },
    { label: 'Mon next wk', fn: nextMonday },
  ]

  function addDays(d: Date, n: number) {
    const r = new Date(d); r.setDate(r.getDate() + n); return r
  }
  function addMonths(d: Date, n: number) {
    const r = new Date(d); r.setMonth(r.getMonth() + n); return r
  }
  function addYears(d: Date, n: number) {
    const r = new Date(d); r.setFullYear(r.getFullYear() + n); return r
  }
  function endOfWeek(d: Date) {
    // End of ISO week = Sunday
    const r = new Date(d)
    const dow = r.getDay() // 0=Sun
    const daysToSun = dow === 0 ? 0 : 7 - dow
    r.setDate(r.getDate() + daysToSun)
    r.setHours(23, 59, 0, 0)
    return r
  }
  function endOfMonth(d: Date) {
    const r = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 0, 0)
    return r
  }
  function endOfYear(d: Date) {
    return new Date(d.getFullYear(), 11, 31, 23, 59, 0, 0)
  }
  function nextMonday(d: Date) {
    const r = new Date(d)
    const dow = r.getDay()
    const daysToMon = dow === 0 ? 1 : 8 - dow
    r.setDate(r.getDate() + daysToMon)
    r.setHours(0, 0, 0, 0)
    return r
  }

  // ── Scheduler tick ───────────────────────────────────────────────────────

  async function runTick(d?: Date) {
    ticking = true
    tickResult = null
    const date = (d ?? devTime.now()).toISOString().slice(0, 10)
    try {
      const res = await api.post<{ ok: boolean; date: string; users: number }>('/dev/tick', { date })
      tickResult = res
    } catch (e: any) {
      tickResult = { ok: false, error: e?.message ?? 'Network error' }
    } finally {
      ticking = false
    }
  }

  // ── Period info ──────────────────────────────────────────────────────────

  const periodInfo = $derived.by(() => {
    const d = devTime.now()
    const y = d.getFullYear()
    const m = d.getMonth()

    // ISO week Monday
    const dow = d.getDay()
    const monday = new Date(d)
    monday.setDate(d.getDate() - (dow === 0 ? 6 : dow - 1))
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)

    const fmtDay = (dt: Date) =>
      dt.toLocaleDateString('en', { month: 'short', day: 'numeric' })
    const fmtMonth = (dt: Date) =>
      dt.toLocaleDateString('en', { month: 'long', year: 'numeric' })

    return {
      week:  `${fmtDay(monday)} – ${fmtDay(sunday)}`,
      month: fmtMonth(d),
      year:  String(y),
    }
  })

  const isOverriding = $derived(devTime.override !== null)

  const displayDate = $derived((() => {
    const d = devTime.now()
    return d.toLocaleDateString('en', { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' })
      + '  ' + d.toLocaleTimeString('en', { hour: '2-digit', minute: '2-digit', hour12: false })
  })())
</script>

<!-- Floating trigger pill -->
{#if !expanded}
  <button
    class="dev-pill"
    class:overriding={isOverriding}
    onclick={open}
    title="Open dev time control"
  >
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="2"/>
      <path d="M12 7v5l3 3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
    </svg>
    {isOverriding ? displayDate : 'DEV TIME'}
  </button>
{:else}
  <!-- Expanded panel -->
  <div class="dev-panel">

    <!-- Header -->
    <div class="dev-header">
      <span class="dev-title">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="2"/>
          <path d="M12 7v5l3 3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
        Dev Time Control
      </span>
      <button class="dev-x" onclick={() => expanded = false}>✕</button>
    </div>

    <!-- Current date display -->
    <div class="dev-current" class:overriding={isOverriding}>
      {displayDate}
      {#if isOverriding}
        <button class="dev-reset-inline" onclick={reset} title="Reset to real time">↺ now</button>
      {/if}
    </div>

    <!-- Manual date/time inputs -->
    <div class="dev-inputs">
      <input class="dev-input" type="date" bind:value={dateStr} />
      <input class="dev-input" type="time" bind:value={timeStr} />
      <button class="dev-btn-apply" onclick={applyFromInputs}>Set</button>
    </div>

    <!-- Quick jumps -->
    <div class="dev-section-label">Quick jump</div>
    <div class="dev-jumps">
      {#each jumps as j}
        <button class="dev-jump-btn" onclick={() => jump(j.fn)}>{j.label}</button>
      {/each}
    </div>

    <!-- Period info -->
    <div class="dev-periods">
      <div class="dev-period-row">
        <span class="dev-period-label">Week</span>
        <span class="dev-period-val">{periodInfo.week}</span>
      </div>
      <div class="dev-period-row">
        <span class="dev-period-label">Month</span>
        <span class="dev-period-val">{periodInfo.month}</span>
      </div>
      <div class="dev-period-row">
        <span class="dev-period-label">Year</span>
        <span class="dev-period-val">{periodInfo.year}</span>
      </div>
    </div>

    <!-- Scheduler -->
    <div class="dev-section-label">Scheduler</div>

    <label class="dev-auto-tick">
      <input type="checkbox" bind:checked={autoTick} />
      Auto-run on jump
    </label>

    <button
      class="dev-tick-btn"
      onclick={() => runTick()}
      disabled={ticking}
    >
      {#if ticking}
        <span class="dev-spinner"></span> Running…
      {:else}
        ↻ Run scheduler tick for this date
      {/if}
    </button>

    {#if tickResult}
      <div class="dev-tick-result" class:ok={tickResult.ok} class:err={!tickResult.ok}>
        {#if tickResult.ok}
          ✓ Processed {tickResult.users} user{tickResult.users !== 1 ? 's' : ''} · {tickResult.date}
        {:else}
          ✗ {tickResult.error}
        {/if}
      </div>
    {/if}

  </div>
{/if}

<style>
  :global(.dev-time-wrap) { position: fixed; bottom: 72px; right: 14px; z-index: 9999; font-family: 'Inter', sans-serif; }
  @media (min-width: 768px) { :global(.dev-time-wrap) { bottom: 16px; } }

  .dev-pill {
    display: flex; align-items: center; gap: 6px;
    padding: 5px 11px; border-radius: 20px;
    font-size: 11px; font-weight: 600; letter-spacing: .04em;
    border: 1px solid rgba(255,255,255,.12);
    background: rgba(30,36,40,.92); color: rgba(196,205,214,.65);
    backdrop-filter: blur(8px); cursor: pointer;
    transition: color .15s, border-color .15s;
  }
  .dev-pill:hover { color: #c4cdd6; border-color: rgba(255,255,255,.22); }
  .dev-pill.overriding { color: #f0c040; border-color: rgba(240,192,64,.4); background: rgba(30,26,18,.92); }

  .dev-panel {
    width: 280px;
    background: #1e2428; border: 1px solid #2e3740;
    border-radius: 12px; padding: 14px;
    box-shadow: 0 12px 40px rgba(0,0,0,.6);
    display: flex; flex-direction: column; gap: 10px;
  }

  .dev-header { display: flex; align-items: center; justify-content: space-between; }
  .dev-title { display: flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #f0c040; letter-spacing: .05em; }
  .dev-x { font-size: 11px; color: #7a8a97; background: none; border: none; cursor: pointer; padding: 2px 4px; border-radius: 4px; }
  .dev-x:hover { color: #c4cdd6; }

  .dev-current {
    font-size: 13px; font-weight: 600; color: #9eaab6;
    background: #252c32; border-radius: 8px; padding: 8px 10px;
    display: flex; align-items: center; justify-content: space-between;
  }
  .dev-current.overriding { color: #f0c040; background: rgba(50,42,12,.6); }
  .dev-reset-inline { font-size: 11px; color: #7a8a97; background: none; border: none; cursor: pointer; padding: 2px 6px; border-radius: 4px; }
  .dev-reset-inline:hover { color: #c4cdd6; }

  .dev-inputs { display: flex; gap: 6px; }
  .dev-input {
    flex: 1; background: #252c32; border: 1px solid #3a4550;
    border-radius: 6px; padding: 6px 7px; font-size: 12px; color: #c4cdd6;
    outline: none; color-scheme: dark; min-width: 0;
  }
  .dev-input:focus { border-color: #579dff; }
  .dev-btn-apply {
    padding: 6px 12px; border-radius: 6px; border: none;
    background: #579dff; color: #fff; font-size: 12px; font-weight: 600; cursor: pointer;
  }
  .dev-btn-apply:hover { background: #4a8de8; }

  .dev-section-label {
    font-size: 10px; font-weight: 600; letter-spacing: .08em;
    text-transform: uppercase; color: #5d6e7a;
    border-top: 1px solid #252c32; padding-top: 8px; margin-top: 2px;
  }

  .dev-jumps { display: flex; flex-wrap: wrap; gap: 5px; }
  .dev-jump-btn {
    padding: 4px 9px; border-radius: 12px; font-size: 11px; font-weight: 500;
    border: 1px solid #2e3740; background: transparent; color: #9eaab6; cursor: pointer;
    transition: background .12s, border-color .12s, color .12s;
  }
  .dev-jump-btn:hover { background: #252c32; border-color: #579dff; color: #579dff; }

  .dev-periods { display: flex; flex-direction: column; gap: 4px; }
  .dev-period-row { display: flex; align-items: baseline; gap: 8px; }
  .dev-period-label { font-size: 10px; color: #5d6e7a; width: 36px; flex-shrink: 0; }
  .dev-period-val { font-size: 12px; color: #9eaab6; }

  .dev-auto-tick {
    display: flex; align-items: center; gap: 6px;
    font-size: 12px; color: #7a8a97; cursor: pointer;
  }
  .dev-auto-tick input { accent-color: #579dff; }

  .dev-tick-btn {
    width: 100%; padding: 8px; border-radius: 8px; border: 1px solid #3a4550;
    background: #252c32; color: #c4cdd6; font-size: 12px; font-weight: 600;
    cursor: pointer; transition: background .15s, border-color .15s;
    display: flex; align-items: center; justify-content: center; gap: 6px;
  }
  .dev-tick-btn:hover:not(:disabled) { background: #2e3740; border-color: #579dff; color: #579dff; }
  .dev-tick-btn:disabled { opacity: .5; cursor: not-allowed; }

  .dev-spinner {
    width: 12px; height: 12px; border: 2px solid #3a4550;
    border-top-color: #579dff; border-radius: 50%;
    animation: spin .6s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  .dev-tick-result {
    font-size: 12px; border-radius: 6px; padding: 6px 10px; text-align: center;
  }
  .dev-tick-result.ok { background: rgba(78,206,155,.1); color: #4ece9b; }
  .dev-tick-result.err { background: rgba(248,113,104,.1); color: #f87168; }
</style>
