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

  const eyebrow = $derived(state.mode === 'create' ? 'New task' : 'Edit task')

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

  <div class="modal">
    <!-- Header -->
    <div class="modal-header flex items-start justify-between">
      <div class="min-w-0 flex-1">
        <div class="modal-eyebrow">{eyebrow}</div>
        {#if state.mode === 'edit'}
          <h2 class="modal-title mb-[10px]">{state.task.title}</h2>
          <div class="flex items-center gap-2 flex-wrap">
            <TaskLevelBadge level={state.task.level} />
            <span
              class="font-mono text-[10px] font-semibold uppercase tracking-[0.06em] px-[7px] pt-[1px] pb-[2px] rounded-[3px] border border-border-2 text-muted"
            >{STATUS_LABELS[state.task.period.status] ?? state.task.period.status}</span>
            <span class="font-mono text-[10.5px] text-muted">
              {fmt(state.task.period.periodStart)}–{fmt(state.task.period.periodEnd)}
            </span>
            {#if state.task.scheduledTime}
              <span class="font-mono text-[10.5px] text-muted">
                ⏱ {state.task.scheduledTime}
              </span>
            {/if}
            {#if state.task.recurringConfig}
              <span class="font-mono text-[10.5px] text-muted">↻ recurring</span>
            {/if}
          </div>
        {:else}
          <h2 class="modal-title">New task</h2>
        {/if}
      </div>
      <button class="btn-icon ml-3 shrink-0" onclick={onClose} aria-label="Close">
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Body -->
    <div class="overflow-y-auto max-h-[80vh]">
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
