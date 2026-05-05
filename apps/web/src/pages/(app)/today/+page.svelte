<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import type { TaskWithPeriod } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { createTask } from '$features/create-task'
  import { TaskModal } from '$widgets/task-modal'
  import { i18n } from '$shared/lib/i18n'

  // ── Date ─────────────────────────────────────────────────────────────────
  const now   = new Date()
  const today = now.toISOString().split('T')[0]

  const dayName = $derived(new Intl.DateTimeFormat(i18n.locale, { weekday: 'long' }).format(now))
  const dateStr = $derived(new Intl.DateTimeFormat(i18n.locale, { day: '2-digit', month: 'short', year: 'numeric' }).format(now))
  const weekNum = (() => {
    const jan1  = new Date(Date.UTC(now.getUTCFullYear(), 0, 1))
    const diff  = now.getTime() - jan1.getTime()
    const dayOfYear = Math.floor(diff / 86400000)
    return Math.ceil((dayOfYear + jan1.getUTCDay() + 1) / 7)
  })()

  const QUIET_WORDS = ['quietly','focused','steady','present','clear','sharp','grounded']
  const quietWord = QUIET_WORDS[now.getUTCDay() % QUIET_WORDS.length]

  // ── Tasks ────────────────────────────────────────────────────────────────
  const todayTasks = $derived(taskStore.getForDate(today))
  const active     = $derived(taskStore.items.filter(t =>
    ['todo','done','overdue'].includes(t.period.status)))
  const weekTasks  = $derived(active.filter(t => t.level === 'week'))
  const monthTasks = $derived(active.filter(t => t.level === 'month'))
  const yearTasks  = $derived(active.filter(t => t.level === 'year'))

  // ── Progress ─────────────────────────────────────────────────────────────
  const totalToday = $derived(todayTasks.length)
  const doneToday  = $derived(todayTasks.filter(t => t.period.status === 'done').length)
  const inPenalty  = $derived(todayTasks.filter(t => t.period.status === 'overdue').length)
  const pct        = $derived(totalToday > 0 ? Math.round((doneToday / totalToday) * 100) : 0)

  // ── Modal / quick add ────────────────────────────────────────────────────
  type ModalState =
    | { mode: 'create'; defaultLevel: 'day'; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let modal       = $state<ModalState | null>(null)
  let quickActive = $state(false)
  let quickTitle  = $state('')

  const openQuickAdd = () => { quickActive = true; quickTitle = '' }

  const submitQuick = async () => {
    const t = quickTitle.trim()
    if (!t) { quickActive = false; return }
    quickActive = false
    const title = quickTitle
    quickTitle  = ''
    await createTask({ title, level: 'day', periodStart: today })
  }

  const handleKeydown = (e: KeyboardEvent) => {
    if (e.key === 'Enter')  { e.preventDefault(); submitQuick() }
    if (e.key === 'Escape') { quickActive = false; quickTitle = '' }
  }
</script>

<div class="main-inner">

  <!-- ── Header ─────────────────────────────────────────────────────────── -->
  <div class="today-header">
    <div class="today-header-left">
      <div class="today-eyebrow">{dayName.toUpperCase()} · {dateStr.toUpperCase()} · {i18n.locale === 'ru' ? 'НЕДЕЛЯ' : 'WEEK'} {weekNum}</div>
      <h1 class="today-title">{i18n.t('view.today_title')} <em>{quietWord}.</em></h1>
    </div>
    <button class="quick-add-btn" onclick={openQuickAdd}>
      + {i18n.t('action.quick_add')}
    </button>
  </div>

  <div class="today-divider"></div>

  {#if taskStore.loading}
    <div class="empty"><p class="text-muted">{i18n.t('action.loading')}</p></div>
  {:else}

    <!-- ── Progress ───────────────────────────────────────────────────────── -->
    {#if totalToday > 0}
      <div class="progress-card">
        <div class="progress-stat">
          <span class="progress-num">{doneToday}<span class="progress-total">/{totalToday}</span></span>
          <span class="progress-label">{i18n.t('view.done_today')}</span>
        </div>
        <div class="progress-divider"></div>
        <div class="progress-stat">
          <span class="progress-num" class:penalty={inPenalty > 0}>{inPenalty}</span>
          <span class="progress-label">{i18n.t('view.in_penalty')}</span>
        </div>
        <div class="progress-divider"></div>
        <div class="progress-bar-wrap">
          <div class="progress-bar-track">
            <div class="progress-bar-fill" style="width: {pct}%"></div>
          </div>
          <span class="progress-pct">{pct}%</span>
        </div>
      </div>
    {/if}

    <!-- ── Day tasks ──────────────────────────────────────────────────────── -->
    {#if todayTasks.length > 0}
      <section class="section">
        <div class="task-list cards">
          {#each todayTasks as task (task.period.id)}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(t) => { modal = { mode: 'edit', task: t } }}
              showLevel={false}
            />
          {/each}
        </div>
      </section>
    {/if}

    <!-- ── Quick add row ─────────────────────────────────────────────────── -->
    <div class="section">
      {#if quickActive}
        <div class="flex items-center gap-2">
          <input
            type="text"
            bind:value={quickTitle}
            onkeydown={handleKeydown}
            placeholder={i18n.t('action.add') + '...'}
            autofocus
            class="input flex-1 py-1.5 px-3 text-sm"
          />
          <button
            type="button"
            onclick={() => { quickActive = false; modal = { mode: 'create', defaultLevel: 'day', defaultPeriodStart: today } }}
            class="btn-icon"
            aria-label={i18n.t('action.open_full')}
          >
            <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
              <path d="M10 2h4v4M14 2l-5 5M6 14H2v-4M2 14l5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>
        </div>
      {:else}
        <button class="add-task-row" onclick={openQuickAdd}>
          + {i18n.t('action.add_today')}
        </button>
      {/if}
    </div>

    <!-- ── Week context ───────────────────────────────────────────────────── -->
    {#if weekTasks.length > 0}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.t('view.carried_over')} <span class="section-sub">· {i18n.t('view.week_tasks').toLowerCase()}</span></h2>
          <span class="section-meta">{weekTasks.length}</span>
        </div>
        <div class="task-list cards">
          {#each weekTasks as task (task.period.id)}
            <TaskCard {task} onToggle={toggleTask} onEdit={(t) => { modal = { mode: 'edit', task: t } }} />
          {/each}
        </div>
      </section>
    {/if}

    <!-- ── Month context ──────────────────────────────────────────────────── -->
    {#if monthTasks.length > 0}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.t('view.month_goals')} <span class="section-sub">· {i18n.t('view.context')}</span></h2>
          <span class="section-meta">{monthTasks.length}</span>
        </div>
        <div class="task-list cards">
          {#each monthTasks as task (task.period.id)}
            <TaskCard {task} onToggle={toggleTask} onEdit={(t) => { modal = { mode: 'edit', task: t } }} />
          {/each}
        </div>
      </section>
    {/if}

    <!-- ── Year context ───────────────────────────────────────────────────── -->
    {#if yearTasks.length > 0}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">{i18n.t('view.year_goals')} <span class="section-sub">· {i18n.t('view.context')}</span></h2>
          <span class="section-meta">{yearTasks.length}</span>
        </div>
        <div class="task-list cards">
          {#each yearTasks as task (task.period.id)}
            <TaskCard {task} onToggle={toggleTask} onEdit={(t) => { modal = { mode: 'edit', task: t } }} />
          {/each}
        </div>
      </section>
    {/if}

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
