<script lang="ts">
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'

  type CreateMode = { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart: string }
  type EditMode   = { mode: 'edit';   task: TaskWithPeriod }

  type Props = {
    state: CreateMode | EditMode
    onClose: () => void
  }
  const { state, onClose }: Props = $props()

  const handleKey = (e: KeyboardEvent) => {
    if (e.key === 'Escape') onClose()
  }
</script>

<svelte:window onkeydown={handleKey} />

<!-- Backdrop -->
<div
  class="fixed inset-0 z-50 flex items-center justify-center bg-black/60"
  role="dialog"
  aria-modal="true"
>
  <!-- Click outside to close -->
  <button
    class="absolute inset-0 w-full h-full cursor-default"
    aria-label="Закрыть"
    onclick={onClose}
  ></button>

  <!-- Panel -->
  <div class="relative z-10 w-full max-w-lg mx-4">
    {#if state.mode === 'create'}
      <CreateTaskForm
        defaultLevel={state.defaultLevel}
        defaultPeriodStart={state.defaultPeriodStart}
        onSuccess={onClose}
        onCancel={onClose}
      />
    {:else}
      <EditTaskForm
        task={state.task}
        onClose={onClose}
      />
    {/if}
  </div>
</div>
