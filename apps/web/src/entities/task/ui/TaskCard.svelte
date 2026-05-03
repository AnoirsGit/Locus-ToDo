<script lang="ts">
  import type { TaskWithPeriod } from '$entities/task'
  import { MONTH_NAMES_SHORT } from '../model/task.constants'
  import TaskLevelBadge from './TaskLevelBadge.svelte'

  type Props = {
    task: TaskWithPeriod
    onToggle?: (periodId: string) => void
    onEdit?: (periodId: string) => void
    showLevel?: boolean
  }
  const { task, onToggle, onEdit, showLevel = true }: Props = $props()

  const p = $derived(task.period)
  const canToggle   = $derived(p.status === 'todo' || p.status === 'done' || p.status === 'overdue')
  const isChecked   = $derived(p.status === 'done')
  const isOverdue   = $derived(p.status === 'overdue')
  const isArchived  = $derived(p.status === 'archived')
  const isFailed    = $derived(isArchived && !p.doneAt)
  const isLate      = $derived(isArchived && !!p.doneAt && p.doneAt > p.periodEnd)
  const isRecurring = $derived(!!task.recurringConfig)
</script>

<div
  class="flex items-start gap-2 p-3 rounded border-y border-r"
  class:border-l-2={isChecked}
  class:border-l={!isChecked}
  class:border-gray-700={!isOverdue && !isChecked}
  class:border-yellow-700={isOverdue}
  class:border-green-700={isChecked}
  class:opacity-60={isArchived}
>
  <!-- Edit button -->
  {#if onEdit && !isArchived}
    <button
      class="mt-0.5 flex-shrink-0 text-gray-600 hover:text-gray-400 transition-colors"
      onclick={() => onEdit(p.id)}
      aria-label="Редактировать задачу"
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
        <path d="M9.5 2.5L11.5 4.5M2 10L2.5 12L4.5 11.5L11.5 4.5L9.5 2.5L2 10Z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
  {/if}

  <!-- Content -->
  <div class="flex-1 min-w-0">
    <div class="flex items-center gap-2 flex-wrap">
      <span
        class="text-sm font-medium"
        class:line-through={isChecked || isArchived}
        class:text-gray-500={isChecked || isArchived}
        class:text-yellow-400={isOverdue}
      >
        {task.title}
      </span>
      {#if showLevel}<TaskLevelBadge level={task.level} />{/if}
      {#if isRecurring}
        <span class="text-xs text-gray-500" title="Повторяющаяся задача">↻</span>
      {/if}
    </div>

    {#if isOverdue}
      <p class="text-xs text-yellow-600 mt-0.5">Долг с прошлого периода</p>
    {/if}

    {#if p.status === 'backlog'}
      <p class="text-xs text-gray-500 mt-0.5">В беклоге — нужно перепланировать</p>
    {/if}

    {#if isArchived}
      {#if isFailed}
        <span class="inline-block mt-1 text-xs px-1.5 py-0.5 rounded border border-red-700 text-red-400">Провал</span>
      {:else if isLate}
        <span class="inline-block mt-1 text-xs px-1.5 py-0.5 rounded border border-yellow-700 text-yellow-400">Выполнено с просрочкой</span>
      {:else}
        <span class="inline-block mt-1 text-xs px-1.5 py-0.5 rounded border border-green-700 text-green-400">Выполнено</span>
      {/if}
    {/if}

    {#if p.deadlineMonth}
      <p class="text-xs text-gray-500 mt-0.5">Дедлайн: {MONTH_NAMES_SHORT[p.deadlineMonth]}</p>
    {/if}

    {#if task.description}
      <p class="text-xs text-gray-500 mt-0.5 truncate">{task.description}</p>
    {/if}
  </div>

  <!-- Status indicator (right) -->
  {#if canToggle}
    <button
      class="mt-0.5 w-5 h-5 rounded-full flex-shrink-0 flex items-center justify-center transition-all"
      class:border-2={!isChecked}
      class:border-gray-600={!isChecked && !isOverdue}
      class:border-yellow-500={isOverdue}
      class:bg-green-600={isChecked}
      onclick={() => onToggle?.(p.id)}
      aria-label={isChecked ? 'Снять отметку' : 'Отметить выполненной'}
    >
      {#if isChecked}
        <svg class="w-3 h-3 text-white" viewBox="0 0 12 12" fill="none">
          <path d="M2.5 6l2.5 2.5L9.5 3.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      {/if}
    </button>
  {:else}
    <div class="mt-0.5 w-5 h-5 flex-shrink-0"></div>
  {/if}
</div>
