<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import { MONTH_NAMES_GENITIVE } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'

  const now = new Date()
  const today = now.toISOString().split('T')[0]
  const dateLabel = `${now.getDate()} ${MONTH_NAMES_GENITIVE[now.getMonth() + 1]}`

  const todayTasks = $derived(taskStore.getForDate(today))

  let creatingNew = $state(false)
  let editingPeriodId = $state<string | null>(null)
</script>

<div class="p-6 max-w-2xl">
  <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Сегодня</p>
  <h1 class="text-xl font-semibold text-gray-100 mb-6">{dateLabel}</h1>

  {#if taskStore.loading}
    <p class="text-sm text-gray-500">Загрузка...</p>
  {:else}
    {#if todayTasks.length > 0}
      <div class="flex flex-col gap-2 mb-3">
        {#each todayTasks as task (task.period.id)}
          {#if editingPeriodId === task.period.id}
            <EditTaskForm {task} onClose={() => { editingPeriodId = null }} />
          {:else}
            <TaskCard {task} onToggle={toggleTask} onEdit={(id) => { editingPeriodId = id }} showLevel={false} />
          {/if}
        {/each}
      </div>
    {:else}
      <p class="text-sm text-gray-600 mb-3">Нет задач на сегодня</p>
    {/if}

    {#if creatingNew}
      <CreateTaskForm
        defaultLevel="day"
        onSuccess={() => { creatingNew = false }}
        onCancel={() => { creatingNew = false }}
      />
    {:else}
      <button
        onclick={() => { creatingNew = true }}
        class="text-sm text-gray-600 hover:text-gray-400 border border-dashed border-gray-800 hover:border-gray-700 rounded px-3 py-2 w-full text-left transition-colors"
      >
        + Добавить задачу на сегодня
      </button>
    {/if}
  {/if}
</div>
