<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import type { TaskView, TaskLevel } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'

  type Props = { view: TaskView }
  const { view }: Props = $props()

  const grouped = $derived(taskStore.getForView(view))

  const canCreate = $derived(view === 'week' || view === 'month' || view === 'year')
  const defaultLevel = $derived<TaskLevel>(
    view === 'month' ? 'month' : view === 'year' ? 'year' : 'week',
  )

  let creatingNew = $state(false)
  let editingPeriodId = $state<string | null>(null)

  const VIEW_LABELS: Record<TaskView, string> = {
    day:     'Сегодня',
    week:    'Неделя',
    month:   'Месяц',
    year:    'Год',
    backlog: 'Беклог',
    archive: 'Архив',
  }

  const CONTEXT_LABELS: Record<string, string> = {
    week:  'Задачи недели',
    month: 'Задачи месяца',
    year:  'Задачи года',
  }
</script>

<div class="p-6 max-w-2xl">
  <h1 class="text-lg font-semibold mb-6">{VIEW_LABELS[view]}</h1>

  {#if taskStore.loading}
    <p class="text-sm text-gray-500">Загрузка...</p>
  {:else}

    <!-- Primary tasks -->
    {#if grouped.primary.length > 0}
      <div class="flex flex-col gap-2 mb-4">
        {#each grouped.primary as task (task.period.id)}
          {#if editingPeriodId === task.period.id}
            <EditTaskForm
              {task}
              onClose={() => { editingPeriodId = null }}
            />
          {:else}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(id) => { editingPeriodId = id }}
              showLevel={false}
            />
          {/if}
        {/each}
      </div>
    {:else if view !== 'backlog' && view !== 'archive'}
      <p class="text-sm text-gray-500 mb-4">Нет задач</p>
    {:else}
      <p class="text-sm text-gray-500 mb-4">Пусто</p>
    {/if}

    <!-- Inline create form -->
    {#if canCreate}
      {#if creatingNew}
        <div class="mb-4">
          <CreateTaskForm
            {defaultLevel}
            onSuccess={() => { creatingNew = false }}
            onCancel={() => { creatingNew = false }}
          />
        </div>
      {:else}
        <button
          class="text-sm text-gray-500 hover:text-gray-300 border border-dashed border-gray-700 hover:border-gray-600 rounded px-3 py-2 w-full text-left mb-4 transition-colors"
          onclick={() => { creatingNew = true }}
        >
          + Добавить задачу
        </button>
      {/if}
    {/if}

    <!-- Context sections (Week → Month + Year context, Month → Year context) -->
    {#each (['week', 'month', 'year'] as const) as key}
      {@const items = grouped[key]}
      {#if items && items.length > 0}
        <div class="mb-4">
          <p class="text-xs font-medium text-gray-500 mb-2 uppercase tracking-wide">
            {CONTEXT_LABELS[key]}
          </p>
          <div class="flex flex-col gap-2">
            {#each items as task (task.period.id)}
              {#if editingPeriodId === task.period.id}
                <EditTaskForm
                  {task}
                  onClose={() => { editingPeriodId = null }}
                />
              {:else}
                <TaskCard
                  {task}
                  onToggle={toggleTask}
                  onEdit={(id) => { editingPeriodId = id }}
                />
              {/if}
            {/each}
          </div>
        </div>
      {/if}
    {/each}

  {/if}
</div>
