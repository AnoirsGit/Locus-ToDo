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

  const VIEW_LABELS: Record<TaskView, { title: string; eyebrow: string }> = {
    day:     { title: 'Сегодня',   eyebrow: 'День' },
    week:    { title: 'Неделя.',   eyebrow: 'Горизонт · неделя' },
    month:   { title: 'Месяц.',    eyebrow: 'Горизонт · месяц' },
    year:    { title: 'Год.',      eyebrow: 'Горизонт · год' },
    backlog: { title: 'Беклог.',   eyebrow: 'Задачи без решения' },
    archive: { title: 'Архив.',    eyebrow: 'Завершённые периоды' },
  }

  const CONTEXT_LABELS: Record<string, string> = {
    week: 'Задачи недели', month: 'Задачи месяца', year: 'Задачи года',
  }

  const { title, eyebrow } = $derived(VIEW_LABELS[view])
</script>

<div class="main-inner">
  <!-- Page header -->
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">{eyebrow}</div>
      <h1 class="page-title"><em>{title}</em></h1>
    </div>
    {#if canCreate}
      <div class="page-actions">
        <button class="btn primary" onclick={openCreate}>+ Добавить задачу</button>
      </div>
    {/if}
  </div>

  {#if taskStore.loading}
    <div class="empty"><p style="color:var(--color-muted);">Загрузка…</p></div>
  {:else}

    <!-- Primary tasks -->
    <section class="section">
      <div class="task-list">
        {#if grouped.primary.length > 0}
          {#each grouped.primary as task (task.period.id)}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(t) => { modal = { mode: 'edit', task: t } }}
              showLevel={false}
            />
          {/each}
        {:else}
          <div class="empty">
            <p class="empty-title">{view === 'backlog' || view === 'archive' ? 'Чисто' : 'Нет задач'}</p>
            <p class="empty-body">{view === 'backlog' ? 'Продолжай в том же духе.' : ''}</p>
          </div>
        {/if}
        {#if canCreate}
          <button class="quick-add" onclick={openCreate}>
            <span class="quick-add-plus">+</span>
            Добавить задачу
          </button>
        {/if}
      </div>
    </section>

    <!-- Context sections -->
    {#each (['week', 'month', 'year'] as const) as key}
      {@const items = grouped[key]}
      {#if items && items.length > 0}
        <section class="section">
          <div class="section-header">
            <h2 class="section-title">{CONTEXT_LABELS[key]}</h2>
            <span class="section-meta">{items.length}</span>
          </div>
          <div class="task-list">
            {#each items as task (task.period.id)}
              <TaskCard
                {task}
                onToggle={toggleTask}
                onEdit={(t) => { modal = { mode: 'edit', task: t } }}
              />
            {/each}
          </div>
        </section>
      {/if}
    {/each}

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
