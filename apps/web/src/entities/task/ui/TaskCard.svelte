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
  const canToggle = $derived(p.status === 'todo' || p.status === 'done' || p.status === 'overdue')
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
      aria-label={isDone ? 'Снять отметку' : 'Отметить выполненной'}
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
      {#if task.recurringConfig}
        <span class="font-mono text-[10.5px]" style="color:var(--color-muted);">↻</span>
      {/if}
    </div>
  </div>

  {#if onEdit}
    <div class="task-aside opacity-0 group-hover:opacity-100 transition-opacity">
      <button
        class="btn-icon"
        onclick={() => onEdit(task)}
        aria-label="Редактировать"
      >
        <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
          <path d="M9.5 2.5L11.5 4.5M2 10L2.5 12L4.5 11.5L11.5 4.5L9.5 2.5L2 10Z"
            stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
    </div>
  {/if}
</div>
