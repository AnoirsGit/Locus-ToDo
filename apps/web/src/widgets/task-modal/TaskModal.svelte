<script lang="ts">
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'

  type CreateMode = { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart?: string }
  type EditMode   = { mode: 'edit';   task: TaskWithPeriod }

  type Props = {
    state: CreateMode | EditMode
    onClose: () => void
  }
  const { state, onClose }: Props = $props()

  const eyebrow = $derived(state.mode === 'create' ? 'Новая задача' : 'Редактировать задачу')
  const title   = $derived(state.mode === 'edit' ? state.task.title : '')
</script>

<svelte:window onkeydown={(e) => { if (e.key === 'Escape') onClose() }} />

<div class="modal-backdrop" role="dialog" aria-modal="true">
  <button
    class="absolute inset-0 w-full h-full cursor-default"
    aria-label="Закрыть"
    onclick={onClose}
  ></button>

  <div class="modal">
    <!-- Header -->
    <div class="modal-header flex items-start justify-between">
      <div>
        <div class="modal-eyebrow">{eyebrow}</div>
        {#if title}
          <h2 class="modal-title">{title}</h2>
        {/if}
      </div>
      <button class="btn-icon" onclick={onClose} aria-label="Закрыть">
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
