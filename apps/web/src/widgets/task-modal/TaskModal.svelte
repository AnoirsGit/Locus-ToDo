<script lang="ts">
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { TaskLevelBadge } from '$entities/task'
  import { CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'

  type CreateMode = { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart?: string }
  type EditMode   = { mode: 'edit';   task: TaskWithPeriod }

  type Props = {
    state: CreateMode | EditMode
    onClose: () => void
  }
  const { state, onClose }: Props = $props()

  const STATUS_LABELS: Record<string, string> = {
    todo: 'To do', done: 'Done', overdue: 'Overdue', backlog: 'Backlog', archived: 'Archived',
  }

  const fmt = (iso: string) => {
    const [y, m, d] = iso.split('-')
    return `${d}.${m}.${y}`
  }
</script>

<svelte:window onkeydown={(e) => { if (e.key === 'Escape') onClose() }} />

<div class="modal-backdrop" role="dialog" aria-modal="true">
  <button
    class="absolute inset-0 w-full h-full cursor-default"
    aria-label="Close"
    onclick={onClose}
  ></button>

  <div class="modal modal-wide">

    <!-- Header: minimal for create, task meta for edit -->
    <div class="tmodal-header">
      {#if state.mode === 'edit'}
        <div class="tmodal-header-meta">
          <TaskLevelBadge level={state.task.level} />
          <span class="tmodal-status-badge">{STATUS_LABELS[state.task.period.status] ?? state.task.period.status}</span>
          <span class="tmodal-period-range">{fmt(state.task.period.periodStart)}–{fmt(state.task.period.periodEnd)}</span>
          {#if state.task.recurringConfig}
            <span class="tmodal-recurring-badge">↻ recurring</span>
          {/if}
        </div>
      {:else}
        <span class="modal-eyebrow">New task</span>
      {/if}
      <button class="btn-icon ml-auto shrink-0" onclick={onClose} aria-label="Close">
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Body -->
    <div class="overflow-y-auto" style="max-height: calc(100vh - 160px)">
      {#if state.mode === 'create'}
        <CreateTaskForm
          defaultLevel={state.defaultLevel}
          defaultPeriodStart={state.defaultPeriodStart}
          onSuccess={onClose}
          onCancel={onClose}
        />
      {:else}
        <EditTaskForm task={state.task} onClose={onClose} />
      {/if}
    </div>
  </div>
</div>
