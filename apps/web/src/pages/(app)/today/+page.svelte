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

<div class="main-inner">
  <!-- Page header -->
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">Сегодня · {dateLabel}</div>
      <h1 class="page-title"><em>Сегодня</em></h1>
    </div>
  </div>

  {#if taskStore.loading}
    <div class="empty">
      <p style="color:var(--color-muted);">Загрузка…</p>
    </div>
  {:else}

    <!-- Day tasks -->
    <section class="section">
      <div class="task-list">
        {#each todayTasks as task (task.period.id)}
          <TaskCard
            {task}
            onToggle={toggleTask}
            onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            showLevel={false}
          />
        {/each}
        <button
          class="quick-add"
          onclick={() => { modal = { mode: 'create', defaultLevel: 'day', defaultPeriodStart: today } }}
        >
          <span class="quick-add-plus">+</span>
          Добавить задачу на сегодня
        </button>
      </div>
    </section>

    <!-- Week tasks -->
    {#if weekTasks.length > 0}
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Задачи недели</h2>
          <span class="section-meta">{weekTasks.length}</span>
        </div>
        <div class="task-list">
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
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Задачи месяца</h2>
          <span class="section-meta">{monthTasks.length}</span>
        </div>
        <div class="task-list">
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
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Задачи года</h2>
          <span class="section-meta">{yearTasks.length}</span>
        </div>
        <div class="task-list">
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
