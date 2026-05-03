<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import type { TaskView, TaskLevel, TaskWithPeriod } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { TaskModal } from '$widgets/task-modal'

  type Props = { view: TaskView }
  const { view }: Props = $props()

  const grouped = $derived(taskStore.getForView(view))

  const canCreate = $derived(view === 'week' || view === 'month' || view === 'year')
  const defaultLevel = $derived<TaskLevel>(
    view === 'month' ? 'month' : view === 'year' ? 'year' : 'week',
  )

  type ModalState =
    | { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let modal = $state<ModalState | null>(null)

  const openCreate = () => {
    const now = new Date()
    const fmt = (d: Date) => d.toISOString().split('T')[0]
    // compute periodStart for the current level
    let periodStart: string
    if (defaultLevel === 'week') {
      const dow = now.getDay()
      const diff = dow === 0 ? -6 : 1 - dow
      const monday = new Date(now)
      monday.setDate(now.getDate() + diff)
      periodStart = fmt(monday)
    } else if (defaultLevel === 'month') {
      periodStart = fmt(new Date(now.getFullYear(), now.getMonth(), 1))
    } else {
      periodStart = `${now.getFullYear()}-01-01`
    }
    modal = { mode: 'create', defaultLevel, defaultPeriodStart: periodStart }
  }

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
          <TaskCard
            {task}
            onToggle={toggleTask}
            onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            showLevel={false}
          />
        {/each}
      </div>
    {:else if view !== 'backlog' && view !== 'archive'}
      <p class="text-sm text-gray-500 mb-4">Нет задач</p>
    {:else}
      <p class="text-sm text-gray-500 mb-4">Пусто</p>
    {/if}

    <!-- Add task button -->
    {#if canCreate}
      <button
        class="text-sm text-gray-500 hover:text-gray-300 border border-dashed border-gray-700 hover:border-gray-600 rounded px-3 py-2 w-full text-left mb-4 transition-colors"
        onclick={openCreate}
      >
        + Добавить задачу
      </button>
    {/if}

    <!-- Context sections -->
    {#each (['week', 'month', 'year'] as const) as key}
      {@const items = grouped[key]}
      {#if items && items.length > 0}
        <div class="mb-4">
          <p class="text-xs font-medium text-gray-500 mb-2 uppercase tracking-wide">
            {CONTEXT_LABELS[key]}
          </p>
          <div class="flex flex-col gap-2">
            {#each items as task (task.period.id)}
              <TaskCard
                {task}
                onToggle={toggleTask}
                onEdit={(t) => { modal = { mode: 'edit', task: t } }}
              />
            {/each}
          </div>
        </div>
      {/if}
    {/each}

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
