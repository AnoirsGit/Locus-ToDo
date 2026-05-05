<script lang="ts">
  import type { TaskWithPeriod } from '../model/task.types'
  import TaskLevelBadge from './TaskLevelBadge.svelte'

  type Props = {
    task: TaskWithPeriod
    onToggle?: (periodId: string) => void
    onEdit?: (task: TaskWithPeriod) => void
    showLevel?: boolean
  }
  const { task, onToggle, onEdit, showLevel = true }: Props = $props()

  const p         = $derived(task.period)
  const isDone    = $derived(p.status === 'done')
  const isOverdue = $derived(p.status === 'overdue')
  const isBacklog = $derived(p.status === 'backlog')
  const isArchived = $derived(p.status === 'archived')
  const canToggle = $derived(p.status === 'todo' || p.status === 'done' || p.status === 'overdue')

  // ── Period label ──────────────────────────────────────────────────────────

  const fmt = (iso: string) => {
    const d = new Date(iso + 'T00:00:00Z')
    return d.toLocaleDateString('en', { month: 'short', day: 'numeric', timeZone: 'UTC' })
  }
  const fmtMonth = (iso: string) => {
    const d = new Date(iso + 'T00:00:00Z')
    return d.toLocaleDateString('en', { month: 'long', year: 'numeric', timeZone: 'UTC' })
  }
  const fmtYear = (iso: string) => iso.slice(0, 4)

  const periodLabel = $derived((() => {
    if (task.level === 'day')   return fmt(p.periodStart)
    if (task.level === 'week')  return `${fmt(p.periodStart)} – ${fmt(p.periodEnd)}`
    if (task.level === 'month') return fmtMonth(p.periodStart)
    if (task.level === 'year')  return fmtYear(p.periodStart)
    return ''
  })())

  // ── Archive outcome ───────────────────────────────────────────────────────

  type Outcome = 'on-time' | 'late' | 'failed'
  const outcome = $derived<Outcome | null>(() => {
    if (!isArchived) return null
    if (!p.doneAt) return 'failed'
    return new Date(p.doneAt) <= new Date(p.periodEnd + 'T23:59:59Z') ? 'on-time' : 'late'
  })

  const outcomeLabel: Record<Outcome, string> = {
    'on-time': 'Done on time',
    'late':    'Done late',
    'failed':  'Failed',
  }
  const outcomeClass: Record<Outcome, string> = {
    'on-time': 'text-success',
    'late':    'text-warning',
    'failed':  'text-muted',
  }

  // ── Backlog age ───────────────────────────────────────────────────────────

  const backlogAge = $derived((() => {
    if (!isBacklog || !p.backlogAt) return null
    const days = Math.floor((Date.now() - new Date(p.backlogAt).getTime()) / 86_400_000)
    if (days === 0) return 'today'
    if (days === 1) return '1 day ago'
    if (days < 30)  return `${days} days ago`
    const months = Math.floor(days / 30)
    return months === 1 ? '1 month ago' : `${months} months ago`
  })())
</script>

<div
  class="task level-{task.level} group"
  class:done={isDone}
  class:overdue={isOverdue}
>
  {#if canToggle}
    <button
      class="checkbox"
      class:checked={isDone}
      onclick={() => onToggle?.(p.id)}
      aria-label={isDone ? 'Unmark' : 'Mark done'}
    >
      {#if isDone}
        <svg class="checkbox-tick" viewBox="0 0 10 10" fill="none">
          <path d="M1.5 5l2.5 2.5L8.5 2" stroke="currentColor" stroke-width="1.6"
            stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      {/if}
    </button>
  {:else}
    <div class="w-[18px] shrink-0"></div>
  {/if}

  <div class="task-body">
    <span class="task-title">{task.title}</span>

    {#if task.description}
      <p class="task-desc truncate">{task.description}</p>
    {/if}

    <div class="task-meta">
      {#if showLevel}<TaskLevelBadge level={task.level} />{/if}

      {#if task.scheduledTime}
        <span class="font-mono text-[10.5px] text-muted">{task.scheduledTime}</span>
      {/if}

      {#if task.recurringConfig}
        <span class="font-mono text-[10.5px] text-muted">↻</span>
      {/if}

      <!-- Backlog / Archive context -->
      {#if isBacklog || isArchived}
        <span class="text-[10.5px] text-muted">{periodLabel}</span>
      {/if}

      {#if isBacklog && backlogAge}
        <span class="text-[10.5px] text-muted opacity-60">· {backlogAge}</span>
      {/if}

      {#if isArchived && outcome}
        <span class="text-[10.5px] {outcomeClass[outcome]}">{outcomeLabel[outcome]}</span>
      {/if}
    </div>
  </div>

  {#if onEdit}
    <div class="task-aside opacity-0 group-hover:opacity-100 transition-opacity">
      <button
        class="btn-icon"
        onclick={() => onEdit(task)}
        aria-label="Edit"
      >
        <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
          <path d="M9.5 2.5L11.5 4.5M2 10L2.5 12L4.5 11.5L11.5 4.5L9.5 2.5L2 10Z"
            stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
    </div>
  {/if}
</div>
