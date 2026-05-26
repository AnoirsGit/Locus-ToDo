<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import { tagStore } from '$entities/tag'
  import { i18n } from '$shared/lib/i18n'
  import type { TaskView, TaskLevel, TaskWithPeriod } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { TaskModal } from '$widgets/task-modal'
  import TaskSection from '$widgets/week-view/ui/TaskSection.svelte'

  type Props = { view: TaskView }
  const { view }: Props = $props()

  const _grouped = $derived(taskStore.getForView(view))
  const grouped = $derived({
    primary: tagStore.filterTasks(_grouped.primary),
    context: _grouped.context,
  })

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

  const VIEW_LABELS: Record<TaskView, { title: string; eyebrow: string }> = $derived({
    day:     { title: i18n.t('view.today'),   eyebrow: i18n.t('nav.today') },
    week:    { title: i18n.t('view.week'),    eyebrow: i18n.t('nav.week') },
    month:   { title: i18n.t('view.month'),   eyebrow: i18n.t('nav.month') },
    year:    { title: i18n.t('view.year'),    eyebrow: i18n.t('nav.year') },
    backlog: { title: i18n.t('view.backlog'), eyebrow: i18n.t('nav.backlog') },
    archive: { title: i18n.t('view.archive'), eyebrow: i18n.t('nav.archive') },
  })

  const CONTEXT_LABELS: Record<string, string> = $derived({
    week: i18n.t('view.week_tasks'), month: i18n.t('view.month_tasks'), year: i18n.t('view.year_tasks'),
  })

  const { title, eyebrow } = $derived(VIEW_LABELS[view])
</script>

<div class="main-inner">
  <!-- Page header -->
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">{eyebrow} </div>
      <h1 class="page-title"><em>{title}</em></h1>
    </div>
    {#if canCreate}
      <div class="page-actions">
        <button class="btn primary" onclick={openCreate}>+ Add task</button>
      </div>
    {/if}
  </div>

  {#if taskStore.loading}
    <div class="empty"><p class="text-muted">{i18n.t('action.loading')}</p></div>
  {:else}

    <!-- Primary tasks -->
    <section class="section">
      <div class="task-list cards">
        {#if grouped.primary.length > 0}
          {#each grouped.primary as task (task.period.id)}
            <TaskCard
              {task}
              onToggle={toggleTask}
              onEdit={(t) => { modal = { mode: 'edit', task: t } }}
              showLevel={view === 'backlog' || view === 'archive'}
              tags={tagStore.getTagsForTask(task.id)}
            />
          {/each}
        {:else}
          <div class="empty">
            <p class="empty-title">{view === 'backlog' || view === 'archive' ? i18n.t('common.empty') : i18n.t('common.no_tasks')}</p>
            <p class="empty-body">{view === 'backlog' ? i18n.t('common.keep_going') : ''}</p>
          </div>
        {/if}
        {#if canCreate}
          <button class="add-task-row" onclick={openCreate}>+ {i18n.t('action.add')}</button>
        {/if}
      </div>
    </section>

    <!-- Context sections -->
    {#each (['week', 'month', 'year'] as const) as key}
      {@const items = grouped[key]}
      {#if items && items.length > 0}
        <TaskSection
          title={CONTEXT_LABELS[key]}
          tasks={items}
          storageKey="{view}:{key}"
          onToggle={toggleTask}
          onEdit={(t) => { modal = { mode: 'edit', task: t } }}
        />
      {/if}
    {/each}

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
