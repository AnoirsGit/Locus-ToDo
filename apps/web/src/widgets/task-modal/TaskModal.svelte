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

  const title = $derived(state.mode === 'create' ? 'Новая задача' : 'Редактировать задачу')
</script>

<svelte:window onkeydown={handleKey} />

<!-- Backdrop -->
<div
  class="fixed inset-0 z-50 flex items-start justify-center pt-16 px-4"
  role="dialog"
  aria-modal="true"
>
  <button
    class="absolute inset-0 w-full h-full bg-black/60 cursor-default"
    aria-label="Закрыть"
    onclick={onClose}
  ></button>

  <!-- Panel -->
  <div class="relative z-10 w-full max-w-2xl bg-gray-900 border border-gray-700 rounded-xl shadow-2xl flex flex-col overflow-hidden">

    <!-- Header -->
    <div class="flex items-center justify-between px-5 py-4 border-b border-gray-800 flex-shrink-0">
      <h2 class="text-sm font-semibold text-gray-200">{title}</h2>
      <button
        onclick={onClose}
        class="p-1.5 text-gray-500 hover:text-gray-300 rounded-md hover:bg-gray-800 transition-colors"
        aria-label="Закрыть"
      >
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Body -->
    <div class="overflow-y-auto max-h-[75vh]">
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
</div>
