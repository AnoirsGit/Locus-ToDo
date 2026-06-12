<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import { tagStore } from '$entities/tag'
  import { i18n } from '$shared/lib/i18n'
  import { weekStartISO, monthStartISO, yearStartISO } from '$shared/lib/date'
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
    const periodStart =
      defaultLevel === 'week'  ? weekStartISO(now)  :
      defaultLevel === 'month' ? monthStartISO(now) :
      yearStartISO(now)
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
    <div class="page-actions">
      {#if canCreate}
        <a href="/backlog" class="btn">
          <svg viewBox="0 0 16 16" fill="none" style="width:13px;height:13px;flex-shrink:0">
            <path d="M2 4h12M2 8h8M2 12h5" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
          </svg>
          Бэклог
        </a>
        <a href="/archive" class="btn">
          <svg viewBox="0 0 16 16" fill="none" style="width:13px;height:13px;flex-shrink:0">
            <rect x="1.5" y="3.5" width="13" height="9" rx="1.5" stroke="currentColor" stroke-width="1.2"/>
            <path d="M1.5 6.5h13" stroke="currentColor" stroke-width="1.2"/>
            <path d="M6 9.5h4" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
          </svg>
          Архив
        </a>
        <button class="btn primary" onclick={openCreate}>+ Add task</button>
      {/if}
    </div>
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
          compact={key === 'week'}
        />
      {/if}
    {/each}

  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
