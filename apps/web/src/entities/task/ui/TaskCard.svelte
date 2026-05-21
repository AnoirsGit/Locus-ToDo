<script lang="ts">
  import type { TaskWithPeriod } from '../model/task.types'
  import TaskLevelBadge from './TaskLevelBadge.svelte'
  import SubtaskChecklist from './SubtaskChecklist.svelte'
  import { DAY_NAMES_SHORT, MONTH_NAMES_SHORT } from '../model/task.constants'

  type TagLike = { id: string; name: string; color: string | null }

  type Props = {
    task: TaskWithPeriod
    onToggle?: (periodId: string) => void
    onEdit?: (task: TaskWithPeriod) => void
    showLevel?: boolean
    tags?: TagLike[]
  }
  const { task, onToggle, onEdit, showLevel = true, tags = [] }: Props = $props()

  let subtasksOpen = $state(false)

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

  // Strip HTML tags for the card snippet (description is rich HTML from the editor)
  const descText = $derived(
    task.description
      ? task.description.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
      : null
  )

  const periodLabel = $derived((() => {
    if (task.level === 'day')   return fmt(p.periodStart)
    if (task.level === 'week')  return `${fmt(p.periodStart)} – ${fmt(p.periodEnd)}`
    if (task.level === 'month') return fmtMonth(p.periodStart)
    if (task.level === 'year')  return fmtYear(p.periodStart)
    return ''
  })())

  // ── Archive outcome ───────────────────────────────────────────────────────

  type Outcome = 'on-time' | 'late' | 'failed'
  const outcome = $derived<Outcome | null>((() => {
    if (!isArchived) return null
    if (!p.doneAt) return 'failed'
    return new Date(p.doneAt) <= new Date(p.periodEnd + 'T23:59:59Z') ? 'on-time' : 'late'
  })())

  const outcomeLabel: Record<Outcome, string> = {
    'on-time': '✓ Done on time',
    'late':    '✓ Done late',
    'failed':  '✗ Not completed',
  }
  const outcomeClass: Record<Outcome, string> = {
    'on-time': 'text-success',
    'late':    'text-warning',
    'failed':  'text-muted',
  }

  const doneAtLabel = $derived((() => {
    if (!isArchived || !p.doneAt) return null
    return new Date(p.doneAt).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })
  })())

  // ── Meta chips ───────────────────────────────────────────────────────────

  const recurringLabel = $derived((() => {
    const r = task.recurringConfig
    if (!r) return null
    const parts: string[] = []
    if (task.level === 'week' && r.daysOfWeek?.length) {
      // Show day abbreviations sorted Mon-first
      const sorted = [...r.daysOfWeek].sort((a, b) => (a === 0 ? 7 : a) - (b === 0 ? 7 : b))
      parts.push(sorted.map((d) => DAY_NAMES_SHORT[d]).join(' '))
    } else if (task.level === 'month' && r.dayOfMonth != null) {
      parts.push(`${r.dayOfMonth}-го`)
    }
    if (task.scheduledTime) parts.push(task.scheduledTime)
    return parts.length ? `↻ ${parts.join(' · ')}` : '↻'
  })())

  const targetDayLabel = $derived((() => {
    if (task.level !== 'week' || !p.targetDate) return null
    const d = new Date(p.targetDate + 'T00:00:00Z')
    return DAY_NAMES_SHORT[d.getUTCDay()]
  })())

  const deadlineLabel = $derived((() => {
    if (task.level !== 'year' || !p.deadlineMonth) return null
    return `до ${MONTH_NAMES_SHORT[p.deadlineMonth]}`
  })())

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

    {#if descText}
      <p class="task-desc truncate">{descText}</p>
    {/if}

    <div class="task-meta">
      {#if showLevel}<TaskLevelBadge level={task.level} />{/if}

      {#if recurringLabel}
        <span class="font-mono text-[10.5px] text-muted">{recurringLabel}</span>
      {:else}
        {#if task.scheduledTime}
          <span class="font-mono text-[10.5px] text-muted">⏱ {task.scheduledTime}</span>
        {/if}
        {#if targetDayLabel}
          <span class="font-mono text-[10.5px] text-muted">→ {targetDayLabel}</span>
        {/if}
      {/if}

      {#if deadlineLabel}
        <span class="font-mono text-[10.5px] text-muted">{deadlineLabel}</span>
      {/if}

      <!-- Backlog context -->
      {#if isBacklog}
        <span class="text-[10.5px] text-muted">{periodLabel}</span>
        {#if backlogAge}
          <span class="text-[10.5px] text-muted opacity-60">· {backlogAge}</span>
        {/if}
      {/if}

      <!-- Archive: period + outcome + done date -->
      {#if isArchived}
        <span class="text-[10.5px] text-muted">{periodLabel}</span>
        {#if outcome}
          <span class="text-[10.5px] {outcomeClass[outcome]}">{outcomeLabel[outcome]}</span>
          {#if doneAtLabel}
            <span class="text-[10.5px] text-muted opacity-60">· {doneAtLabel}</span>
          {/if}
        {/if}
      {/if}
    </div>

    {#if tags.length > 0}
      <div class="task-tags">
        {#each tags as tag (tag.id)}
          <span
            class="tag-chip"
            style:background={tag.color ?? 'var(--color-surface)'}
            style:color={tag.color ? '#fff' : 'var(--color-text)'}
          >{tag.name}</span>
        {/each}
      </div>
    {/if}

    {#if !isArchived && !isBacklog}
      <div class="subtask-toggle-row">
        <button
          class="subtask-toggle-btn"
          onclick={(e) => { e.stopPropagation(); subtasksOpen = !subtasksOpen }}
          type="button"
        >
          <svg width="9" height="9" viewBox="0 0 9 9" fill="none" style:transform={subtasksOpen ? 'rotate(90deg)' : 'none'} style="transition:transform 0.15s">
            <path d="M2.5 1.5l3 3-3 3" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          Subtasks
        </button>
      </div>

      {#if subtasksOpen}
        <SubtaskChecklist
          parentTaskId={task.id}
          parentLevel={task.level}
          parentPeriodStart={task.period.periodStart}
        />
      {/if}
    {/if}
  </div>

  {#if onEdit}
    <div class="task-aside opacity-100 md:opacity-0 md:group-hover:opacity-100 transition-opacity">
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
