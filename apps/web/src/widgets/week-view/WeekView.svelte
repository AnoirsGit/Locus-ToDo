<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import { MONTH_NAMES_SHORT, DAY_NAMES_SHORT } from '$entities/task'
  import type { TaskLevel, TaskWithPeriod } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { createTask } from '$features/create-task'
  import { TaskModal } from '$widgets/task-modal'

  type ModalState =
    | { mode: 'create'; defaultLevel: TaskLevel; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let weekOffset    = $state(0)
  let quickCreateDay = $state<string | null>(null)
  let quickTitle    = $state('')
  let modal         = $state<ModalState | null>(null)
  let kanbanRef     = $state<HTMLElement | null>(null)

  const toISO = (d: Date) => d.toISOString().split('T')[0]
  const today = toISO(new Date())

  const weekDays = $derived.by(() => {
    const now = new Date()
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
    if (sm === em) return `${start.getDate()}–${end.getDate()} ${MONTH_NAMES_SHORT[sm + 1]} ${ey}`
    return `${start.getDate()} ${MONTH_NAMES_SHORT[sm + 1]} – ${end.getDate()} ${MONTH_NAMES_SHORT[em + 1]} ${ey}`
  })

  const weekTasks = $derived(
    taskStore.items.filter(
      (t) => t.level === 'week' &&
        (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done'),
    ),
  )

  const tasksByDay = $derived.by(() => {
    const map = new Map<string, TaskWithPeriod[]>()
    for (const d of weekDays) {
      const key = toISO(d)
      map.set(key, taskStore.items.filter(
        (t) =>
          (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done') &&
          (t.period.targetDate === key || (t.level === 'day' && t.period.periodStart === key)),
      ))
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
    col?.scrollIntoView({ inline: 'nearest', block: 'nearest', behavior: 'smooth' })
  })

  const startQuickCreate = (date: string) => { quickCreateDay = date; quickTitle = '' }
  const cancelQuickCreate = () => { quickCreateDay = null; quickTitle = '' }
  const submitQuickCreate = async (date: string) => {
    const t = quickTitle.trim()
    if (!t) { cancelQuickCreate(); return }
    cancelQuickCreate()
    await createTask({ title: t, level: 'day', periodStart: date })
  }
  const handleQuickKeydown = (e: KeyboardEvent, date: string) => {
    if (e.key === 'Enter') { e.preventDefault(); submitQuickCreate(date) }
    if (e.key === 'Escape') cancelQuickCreate()
  }
</script>

<div class="main-inner">
  <!-- Page header -->
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">Горизонт · неделя</div>
      <h1 class="page-title"><em>Неделя.</em></h1>
    </div>
    <div class="page-actions">
      <button class="btn-icon" onclick={() => weekOffset -= 1} aria-label="Предыдущая неделя">
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M10 12L6 8l4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
      <span class="font-medium text-sm min-w-44 text-center" style="color:var(--color-text);">{weekLabel}</span>
      <button class="btn-icon" onclick={() => weekOffset += 1} aria-label="Следующая неделя">
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M6 4l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
    </div>
  </div>

  <!-- Week tasks strip -->
  <section class="section">
    <div class="section-header">
      <h2 class="section-title">Задачи недели</h2>
      <span class="section-meta">{weekTasks.length}</span>
    </div>
    <div class="task-list">
      <div class="flex items-center gap-2 flex-wrap p-2 min-h-10">
        {#each weekTasks as task (task.period.id)}
          {@const isDone    = task.period.status === 'done'}
          {@const isOverdue = task.period.status === 'overdue'}
          <div
            class="group flex items-center gap-2 px-3 py-1.5 rounded text-xs transition-colors select-none"
            style={isDone
              ? 'border:1px solid var(--color-week-soft); background:var(--color-week-tint); opacity:0.7;'
              : isOverdue
                ? 'border:1px solid var(--color-warning-soft); background:var(--color-warning-tint);'
                : 'border:1px solid var(--color-border); background:var(--color-card);'}
          >
            <span
              style={isDone
                ? 'text-decoration:line-through; color:var(--color-muted);'
                : isOverdue
                  ? 'color:var(--color-warning-ink); font-weight:500;'
                  : 'color:var(--color-text);'}
              class="max-w-48 truncate"
            >{task.title}</span>
            {#if task.recurringConfig}
              <span style="color:var(--color-muted);">↻</span>
            {/if}
            <button
              class="btn-icon w-5 h-5 opacity-0 group-hover:opacity-100 transition-opacity"
              onclick={() => { modal = { mode: 'edit', task } }}
              aria-label="Редактировать"
            >
              <svg class="w-3 h-3" viewBox="0 0 14 14" fill="none">
                <path d="M9.5 2.5L11.5 4.5M2 10L2.5 12L4.5 11.5L11.5 4.5L9.5 2.5L2 10Z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
            <button
              class="shrink-0 w-3.5 h-3.5 rounded-full transition-all flex items-center justify-center"
              style={isDone
                ? 'background:var(--color-week);'
                : isOverdue ? 'border:1.5px solid var(--color-warning);' : 'border:1.5px solid var(--color-border-2);'}
              onclick={() => toggleTask(task.period.id)}
              aria-label={isDone ? 'Снять отметку' : 'Выполнено'}
            >
              {#if isDone}
                <svg class="w-2 h-2" viewBox="0 0 8 8" fill="none">
                  <path d="M1.5 4l1.5 1.5L6.5 2" stroke="white" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              {/if}
            </button>
          </div>
        {/each}
        <button
          class="btn ghost btn-sm"
          onclick={() => { modal = { mode: 'create', defaultLevel: 'week', defaultPeriodStart: toISO(weekDays[0]) } }}
        >+ Добавить</button>
      </div>
    </div>
  </section>

  <!-- Day columns kanban -->
  <section class="section">
    <div class="section-header">
      <h2 class="section-title">По дням</h2>
    </div>
    <div class="overflow-x-auto pb-1" bind:this={kanbanRef}>
      <div class="flex gap-3 min-w-max">
        {#each weekDays as day (toISO(day))}
          {@const key = toISO(day)}
          {@const isToday = key === today}
          {@const dayTasks = tasksByDay.get(key) ?? []}
          <div class="day-col w-52 shrink-0" data-date={key}>
            <div class="day-col-header" class:today={isToday}>
              <span class="day-col-dow">{DAY_NAMES_SHORT[day.getDay()]}</span>
              <span class="day-col-num" class:today={isToday}>{day.getDate()}</span>
            </div>
            <div class="day-col-body">
              {#each dayTasks as task (task.period.id)}
                <TaskCard
                  {task}
                  onToggle={toggleTask}
                  onEdit={(t) => { modal = { mode: 'edit', task: t } }}
                  showLevel={false}
                />
              {/each}
            </div>
            <div class="day-col-footer">
              {#if quickCreateDay === key}
                <div class="flex items-center gap-1">
                  <input
                    type="text"
                    bind:value={quickTitle}
                    onkeydown={(e) => handleQuickKeydown(e, key)}
                    placeholder="Название задачи…"
                    autofocus
                    class="input flex-1"
                    style="padding:4px 8px; font-size:12px;"
                  />
                  <button
                    type="button"
                    onclick={() => { cancelQuickCreate(); modal = { mode: 'create', defaultLevel: 'day', defaultPeriodStart: key } }}
                    class="btn-icon"
                    aria-label="Открыть полную форму"
                  >
                    <svg class="w-3.5 h-3.5" viewBox="0 0 16 16" fill="none">
                      <path d="M10 2h4v4M14 2l-5 5M6 14H2v-4M2 14l5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                  </button>
                </div>
              {:else}
                <button
                  class="w-full text-left text-xs py-1 px-1 transition-colors"
                  style="color:var(--color-muted-2);"
                  onclick={() => startQuickCreate(key)}
                >+ Добавить</button>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    </div>
  </section>

  <!-- Month tasks -->
  {#if monthTasks.length > 0}
    <section class="section">
      <div class="section-header">
        <h2 class="section-title">Задачи месяца</h2>
        <span class="section-meta">{monthTasks.length}</span>
      </div>
      <div class="task-list">
        {#each monthTasks as task (task.period.id)}<TaskCard {task} onToggle={toggleTask} />{/each}
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
        {#each yearTasks as task (task.period.id)}<TaskCard {task} onToggle={toggleTask} />{/each}
      </div>
    </section>
  {/if}
</div>

{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
