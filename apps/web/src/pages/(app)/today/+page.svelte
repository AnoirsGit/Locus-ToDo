<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import type { TaskWithPeriod } from '$entities/task'
  import { MONTH_NAMES_GENITIVE } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { TaskModal } from '$widgets/task-modal'

  const now = new Date()
  const today = now.toISOString().split('T')[0]
  const dateLabel = `${now.getDate()} ${MONTH_NAMES_GENITIVE[now.getMonth() + 1]}`

  const active = $derived(
    taskStore.items.filter(
      (t) => t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done',
    ),
  )

  const todayTasks = $derived(taskStore.getForDate(today))
  const weekTasks  = $derived(active.filter((t) => t.level === 'week'))
  const monthTasks = $derived(active.filter((t) => t.level === 'month'))
  const yearTasks  = $derived(active.filter((t) => t.level === 'year'))

  type ModalState =
    | { mode: 'create'; defaultLevel: 'day'; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let modal = $state<ModalState | null>(null)
</script>

<div class="p-6 max-w-2xl">
  <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Сегодня</p>
  <h1 class="text-xl font-semibold text-gray-100 mb-6">{dateLabel}</h1>

  {#if taskStore.loading}
    <p class="text-sm text-gray-500">Загрузка...</p>
  {:else}

    <!-- Day tasks -->
    <div class="flex flex-col gap-2 mb-3">
      {#each todayTasks as task (task.period.id)}
        <TaskCard
          {task}
          onToggle={toggleTask}
          onEdit={(t) => { modal = { mode: 'edit', task: t } }}
          showLevel={false}
        />
      {/each}
    </div>

    <button
      onclick={() => { modal = { mode: 'create', defaultLevel: 'day', defaultPeriodStart: today } }}
      class="text-sm text-gray-600 hover:text-gray-400 border border-dashed border-gray-800 hover:border-gray-700 rounded px-3 py-2 w-full text-left mb-6 transition-colors"
    >
      + Добавить задачу на сегодня
    </button>

    <!-- Week tasks -->
    {#if weekTasks.length > 0}
      <section class="mb-5">
        <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Задачи недели</p>
        <div class="flex flex-col gap-2">
          {#each weekTasks as task (task.period.id)}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            />
          {/each}
        </div>
      </section>
    {/if}

    <!-- Month tasks -->
    {#if monthTasks.length > 0}
      <section class="mb-5">
        <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Задачи месяца</p>
        <div class="flex flex-col gap-2">
          {#each monthTasks as task (task.period.id)}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            />
          {/each}
        </div>
      </section>
    {/if}

    <!-- Year tasks -->
    {#if yearTasks.length > 0}
      <section class="mb-5">
        <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Задачи года</p>
        <div class="flex flex-col gap-2">
          {#each yearTasks as task (task.period.id)}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            />
          {/each}
        </div>
      </section>
    {/if}

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
