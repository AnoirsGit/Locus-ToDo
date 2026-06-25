<script lang="ts">
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { TaskLevelBadge } from '$entities/task'
  import { CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'
  import { i18n } from '$shared/lib/i18n'
  import { trapFocus } from '$shared/lib/focusTrap'

  type CreateMode = { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart?: string }
  type EditMode   = { mode: 'edit';   task: TaskWithPeriod }

  type Props = {
    state: CreateMode | EditMode
    onClose: () => void
  }
  // Aliased to `modalState` so the `$state` rune below isn't read as a `$state` store.
  const { state: modalState, onClose }: Props = $props()

  // Tracks unsaved input in the embedded form; guards Escape/backdrop/Cancel.
  let formDirty = $state(false)
  const requestClose = () => {
    if (formDirty && !confirm(i18n.t('action.discard_confirm'))) return
    onClose()
  }

  const STATUS_LABELS: Record<string, string> = {
    todo: 'To do', done: 'Done', overdue: 'Overdue', backlog: 'Backlog', archived: 'Archived',
  }

  const fmt = (iso: string) => {
    const [y, m, d] = iso.split('-')
    return `${d}.${m}.${y}`
  }
</script>

<svelte:window onkeydown={(e) => { if (e.key === 'Escape') requestClose() }} />

<div class="modal-backdrop" role="dialog" aria-modal="true">
  <button
    class="absolute inset-0 w-full h-full cursor-default"
    aria-label={i18n.t('action.close')}
    tabindex="-1"
    onclick={requestClose}
  ></button>

  <div class="modal modal-wide" tabindex="-1" use:trapFocus>

    <!-- Header: minimal for create, task meta for edit -->
    <div class="tmodal-header">
      {#if modalState.mode === 'edit'}
        <div class="tmodal-header-meta">
          <TaskLevelBadge level={modalState.task.level} />
          <span class="tmodal-status-badge">{STATUS_LABELS[modalState.task.period.status] ?? modalState.task.period.status}</span>
          <span class="tmodal-period-range">{fmt(modalState.task.period.periodStart)}–{fmt(modalState.task.period.periodEnd)}</span>
          {#if modalState.task.recurringConfig}
            <span class="tmodal-recurring-badge">↻ recurring</span>
          {/if}
        </div>
      {:else}
        <span class="modal-eyebrow">New task</span>
      {/if}
      <button class="btn-icon ml-auto shrink-0" onclick={requestClose} aria-label={i18n.t('action.close')}>
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Body -->
    <div class="overflow-y-auto" style="max-height: calc(100vh - 160px)">
      {#if modalState.mode === 'create'}
        <CreateTaskForm
          defaultLevel={modalState.defaultLevel}
          defaultPeriodStart={modalState.defaultPeriodStart}
          onSuccess={onClose}
          onCancel={requestClose}
          bind:dirty={formDirty}
        />
      {:else}
        <EditTaskForm task={modalState.task} onClose={onClose} onCancel={requestClose} bind:dirty={formDirty} />
      {/if}
    </div>
  </div>
</div>
