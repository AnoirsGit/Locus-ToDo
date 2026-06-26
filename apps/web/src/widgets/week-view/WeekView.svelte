<script lang="ts">
  import { taskStore } from '$entities/task'
  import { tasksApi } from '$entities/task'
  import { tagStore } from '$entities/tag'
  import type { TaskLevel, TaskWithPeriod } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { createTask } from '$features/create-task'
  import { TaskModal } from '$widgets/task-modal'
  import { i18n } from '$shared/lib/i18n'
  import { clock } from '$shared/lib/clock.svelte'
  import { toLocalISO } from '$shared/lib/date'

  import WeekHeader from './ui/WeekHeader.svelte'
  import TaskSection from './ui/TaskSection.svelte'
  import DayColumn from './ui/DayColumn.svelte'
  import { dragScroll } from '$shared/lib/dragScroll'
  import { commands } from '$shared/lib/commands.svelte'

  type ModalState =
    | { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let weekOffset    = $state(0)
  let modal         = $state<ModalState | null>(null)
  let kanbanRef     = $state<HTMLElement | null>(null)

  const toISO = toLocalISO
  const today = $derived(clock.today)

  const weekDays = $derived.by(() => {
    const now = clock.now
    const dow = now.getDay()
    const daysToMon = dow === 0 ? -6 : 1 - dow
    const monday = new Date(now)
    monday.setDate(now.getDate() + daysToMon + weekOffset * 7)
    return Array.from({ length: 7 }, (_, i) => {
      const d = new Date(monday)
      d.setDate(monday.getDate() + i)
      return d
    })
  })

  const weekLabel = $derived.by(() => {
    const [start, end] = [weekDays[0], weekDays[6]]
    const sm = start.getMonth()
    const em = end.getMonth()
    const ey = end.getFullYear()
    
    const fmt = new Intl.DateTimeFormat(i18n.locale, { month: 'short' })
    const smName = fmt.format(start)
    const emName = fmt.format(end)

    if (sm === em) return `${start.getDate()}–${end.getDate()} ${smName} ${ey}`
    return `${start.getDate()} ${smName} – ${end.getDate()} ${emName} ${ey}`
  })

  const weekTasks = $derived(
    tagStore.filterTasks(taskStore.items.filter(
      (t) => t.level === 'week' &&
        (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done'),
    )),
  )

  const tasksByDay = $derived.by(() => {
    const map = new Map<string, TaskWithPeriod[]>()
    for (const d of weekDays) {
      const key = toISO(d)
      map.set(key, tagStore.filterTasks(taskStore.items.filter(
        (t) =>
          (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done') &&
          (t.period.targetDate === key || (t.level === 'day' && t.period.periodStart === key)),
      )))
    }
    return map
  })

  const monthTasks = $derived(
    taskStore.items.filter((t) => t.level === 'month' &&
      (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done')),
  )
  const yearTasks = $derived(
    taskStore.items.filter((t) => t.level === 'year' &&
      (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done')),
  )

  $effect(() => {
    const _offset = weekOffset
    if (_offset !== 0) return
    const col = kanbanRef?.querySelector(`[data-date="${today}"]`) as HTMLElement | null
    col?.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' })
  })

  const handleQuickCreate = async (title: string, date: string) => {
    await createTask({ title, level: 'day', periodStart: date })
  }

  // Drag-and-drop in the kanban: reassign a week task's target day (optimistic + PATCH).
  const handleDropTask = async (periodId: string, targetDate: string) => {
    const t = taskStore.items.find((x) => x.period.id === periodId)
    if (!t || t.level !== 'week' || t.period.targetDate === targetDate) return
    const prev = t.period.targetDate
    taskStore.updatePeriod(periodId, { targetDate })
    try {
      await tasksApi.update(t.id, { targetDate })
    } catch {
      taskStore.updatePeriod(periodId, { targetDate: prev }) // revert; client already toasted
    }
  }

  // Global "create task" shortcut (c/n) → open a week-level create on this view.
  let lastCreateTick = 0
  $effect(() => {
    if (commands.createTick !== lastCreateTick) {
      lastCreateTick = commands.createTick
      modal = { mode: 'create', defaultLevel: 'week', defaultPeriodStart: toISO(weekDays[0]) }
    }
  })
</script>

<div class="main-inner flex flex-col gap-0">
  <WeekHeader bind:weekOffset {weekLabel} />

  <!-- Day columns kanban - First on mobile -->
  <section class="section order-first md:order-none">
    <div class="section-header">
      <h2 class="section-title">{i18n.t('view.by_days')}</h2>
    </div>
    <div class="overflow-x-auto pb-1" bind:this={kanbanRef} use:dragScroll>
      <div class="flex gap-3 min-w-max">
        {#each weekDays as day (toISO(day))}
          {@const key = toISO(day)}
          <DayColumn
            {day}
            tasks={tasksByDay.get(key) ?? []}
            isToday={key === today}
            onToggle={(t) => toggleTask(t.period.id)}
            onEdit={(t) => { modal = { mode: 'edit', task: t } }}
            onQuickCreate={handleQuickCreate}
            onOpenModal={(date) => { modal = { mode: 'create', defaultLevel: 'day', defaultPeriodStart: date } }}
            onDropTask={handleDropTask}
          />
        {/each}
      </div>
    </div>
  </section>

  <!-- Week tasks strip -->
  <TaskSection
    title={i18n.t('view.week_tasks')}
    tasks={weekTasks}
    storageKey="week:week"
    onToggle={toggleTask}
    onEdit={(t) => { modal = { mode: 'edit', task: t } }}
  >
    {#snippet footer()}
      <button
        class="btn ghost btn-sm mt-2 ml-2"
        onclick={() => { modal = { mode: 'create', defaultLevel: 'week', defaultPeriodStart: toISO(weekDays[0]) } }}
      >+ {i18n.t('action.add')}</button>
    {/snippet}
  </TaskSection>

  <!-- Month tasks -->
  <TaskSection
    title={i18n.t('view.month_tasks')}
    tasks={monthTasks}
    storageKey="week:month"
    onToggle={toggleTask}
    onEdit={(t) => { modal = { mode: 'edit', task: t } }}
  />

  <!-- Year tasks -->
  <TaskSection
    title={i18n.t('view.year_tasks')}
    tasks={yearTasks}
    storageKey="week:year"
    onToggle={toggleTask}
    onEdit={(t) => { modal = { mode: 'edit', task: t } }}
  />

</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
