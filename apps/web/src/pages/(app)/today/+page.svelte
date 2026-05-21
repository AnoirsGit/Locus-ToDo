<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { TaskModal } from '$widgets/task-modal'
  import { i18n } from '$shared/lib/i18n'
  import TaskSection from '$widgets/week-view/ui/TaskSection.svelte'
  import { tagStore } from '$entities/tag'

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

  // ── Modal ─────────────────────────────────────────────────────────────────
  type ModalState =
    | { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let modal = $state<ModalState | null>(null)

  const fmt = (d: Date) => d.toISOString().split('T')[0]

  const periodStartFor = (level: TaskLevel): string => {
    if (level === 'day') return today
    if (level === 'week') {
      const dow = now.getDay()
      const monday = new Date(now)
      monday.setDate(now.getDate() + (dow === 0 ? -6 : 1 - dow))
      return fmt(monday)
    }
    if (level === 'month') return fmt(new Date(now.getFullYear(), now.getMonth(), 1))
    return `${now.getFullYear()}-01-01`
  }

  const openCreate = (level: TaskLevel) => {
    modal = { mode: 'create', defaultLevel: level, defaultPeriodStart: periodStartFor(level) }
  }
</script>

<div class="main-inner">

  <!-- ── Header ─────────────────────────────────────────────────────────── -->
  <div class="today-header">
    <div class="today-header-left">
      <div class="today-eyebrow">{dayName.toUpperCase()} · {dateStr.toUpperCase()} · {i18n.locale === 'ru' ? 'НЕДЕЛЯ' : 'WEEK'} {weekNum}</div>
      <h1 class="today-title">{i18n.t('view.today_title')} <em>{quietWord}.</em></h1>
    </div>
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
    <section class="section">
      <div class="task-list cards">
        {#each todayTasks as task (task.period.id)}
          <TaskCard
            {task}
            onToggle={toggleTask}
            onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            showLevel={false}
            tags={tagStore.getTagsForTask(task.id)}
          />
        {/each}
        <button class="add-task-row" onclick={() => openCreate('day')}>
          + {i18n.t('action.add_today')}
        </button>
      </div>
    </section>

    <!-- ── Week context ───────────────────────────────────────────────────── -->
    <TaskSection
      title="{i18n.t('view.week_goals')} · {i18n.t('view.context')}"
      tasks={weekTasks}
      storageKey="today:week"
      onToggle={toggleTask}
      onEdit={(t) => { modal = { mode: 'edit', task: t } }}
    >
      {#snippet footer()}
        <button class="add-task-row" onclick={() => openCreate('week')}>+ {i18n.t('action.add')}</button>
      {/snippet}
    </TaskSection>

    <!-- ── Month context ──────────────────────────────────────────────────── -->
    <TaskSection
      title="{i18n.t('view.month_goals')} · {i18n.t('view.context')}"
      tasks={monthTasks}
      storageKey="today:month"
      onToggle={toggleTask}
      onEdit={(t) => { modal = { mode: 'edit', task: t } }}
    >
      {#snippet footer()}
        <button class="add-task-row" onclick={() => openCreate('month')}>+ {i18n.t('action.add')}</button>
      {/snippet}
    </TaskSection>

    <!-- ── Year context ───────────────────────────────────────────────────── -->
    <TaskSection
      title="{i18n.t('view.year_goals')} · {i18n.t('view.context')}"
      tasks={yearTasks}
      storageKey="today:year"
      onToggle={toggleTask}
      onEdit={(t) => { modal = { mode: 'edit', task: t } }}
    >
      {#snippet footer()}
        <button class="add-task-row" onclick={() => openCreate('year')}>+ {i18n.t('action.add')}</button>
      {/snippet}
    </TaskSection>

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
