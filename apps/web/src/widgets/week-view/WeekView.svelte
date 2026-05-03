<script lang="ts">
  import { taskStore, TaskCard } from '$entities/task'
  import { MONTH_NAMES_SHORT, DAY_NAMES_SHORT } from '$entities/task'
  import type { TaskWithPeriod } from '$entities/task'
  import { toggleTask } from '$features/toggle-task'
  import { createTask, CreateTaskForm } from '$features/create-task'
  import { EditTaskForm } from '$features/edit-task'
  import { TaskModal } from '$widgets/task-modal'

  type ModalState =
    | { mode: 'create'; defaultLevel: 'day'; defaultPeriodStart: string }
    | { mode: 'edit'; task: TaskWithPeriod }

  let weekOffset = $state(0)
  let creatingNew = $state(false)
  let editingPeriodId = $state<string | null>(null)

  // Day-column quick-create
  let quickCreateDay = $state<string | null>(null)
  let quickTitle = $state('')

  // Modal
  let modal = $state<ModalState | null>(null)

  // Kanban scroll ref
  let kanbanRef = $state<HTMLElement | null>(null)

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
    if (sm === em) {
      return `${start.getDate()}–${end.getDate()} ${MONTH_NAMES_SHORT[sm + 1]} ${ey}`
    }
    return `${start.getDate()} ${MONTH_NAMES_SHORT[sm + 1]} – ${end.getDate()} ${MONTH_NAMES_SHORT[em + 1]} ${ey}`
  })

  const weekTasks = $derived(
    taskStore.items.filter(
      (t) =>
        t.level === 'week' &&
        (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done'),
    ),
  )

  const tasksByDay = $derived.by(() => {
    const map = new Map<string, TaskWithPeriod[]>()
    for (const d of weekDays) {
      const key = toISO(d)
      map.set(
        key,
        taskStore.items.filter(
          (t) =>
            (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done') &&
            (t.period.targetDate === key || (t.level === 'day' && t.period.periodStart === key)),
        ),
      )
    }
    return map
  })

  const monthTasks = $derived(
    taskStore.items.filter(
      (t) =>
        t.level === 'month' &&
        (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done'),
    ),
  )

  const yearTasks = $derived(
    taskStore.items.filter(
      (t) =>
        t.level === 'year' &&
        (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done'),
    ),
  )

  // Auto-scroll to today's column
  $effect(() => {
    const _offset = weekOffset
    if (_offset !== 0) return
    const col = kanbanRef?.querySelector(`[data-date="${today}"]`) as HTMLElement | null
    col?.scrollIntoView({ inline: 'nearest', block: 'nearest', behavior: 'smooth' })
  })

  const startQuickCreate = (date: string) => {
    quickCreateDay = date
    quickTitle = ''
  }

  const cancelQuickCreate = () => {
    quickCreateDay = null
    quickTitle = ''
  }

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

<div class="p-6 max-w-5xl">
  <!-- ── Header ─────────────────────────────────────────── -->
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-2">
      <button
        onclick={() => weekOffset -= 1}
        class="p-1.5 text-gray-500 hover:text-gray-300 rounded hover:bg-gray-800 transition-colors"
        aria-label="Предыдущая неделя"
      >
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M10 12L6 8l4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
      <span class="text-base font-medium text-gray-200 min-w-44 text-center">{weekLabel}</span>
      <button
        onclick={() => weekOffset += 1}
        class="p-1.5 text-gray-500 hover:text-gray-300 rounded hover:bg-gray-800 transition-colors"
        aria-label="Следующая неделя"
      >
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M6 4l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
    </div>
    <div class="flex gap-1">
      <a href="/month" class="text-sm text-gray-500 hover:text-gray-300 px-3 py-1.5 rounded hover:bg-gray-800 transition-colors">Месяц</a>
      <a href="/year" class="text-sm text-gray-500 hover:text-gray-300 px-3 py-1.5 rounded hover:bg-gray-800 transition-colors">Год</a>
    </div>
  </div>

  <!-- ── Задачи недели ──────────────────────────────────── -->
  <section class="mb-8">
    <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Задачи недели</h2>

    {#if weekTasks.length > 0}
      <div class="flex flex-col gap-2">
        {#each weekTasks as task (task.period.id)}
          {#if editingPeriodId === task.period.id}
            <EditTaskForm {task} onClose={() => { editingPeriodId = null }} />
          {:else}
            <TaskCard {task} onToggle={toggleTask} onEdit={(id) => { editingPeriodId = id }} showLevel={false} />
          {/if}
        {/each}
      </div>
    {:else}
      <p class="text-sm text-gray-600">Нет задач</p>
    {/if}

    {#if creatingNew}
      <div class="mt-2">
        <CreateTaskForm
          defaultLevel="week"
          onSuccess={() => { creatingNew = false }}
          onCancel={() => { creatingNew = false }}
        />
      </div>
    {:else}
      <button
        onclick={() => { creatingNew = true }}
        class="mt-2 text-sm text-gray-600 hover:text-gray-400 border border-dashed border-gray-800 hover:border-gray-700 rounded px-3 py-2 w-full text-left transition-colors"
      >
        + Добавить задачу
      </button>
    {/if}
  </section>

  <!-- ── По дням (kanban) ─────────────────────────────── -->
  <section class="mb-8">
    <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">По дням</h2>
    <div class="overflow-x-auto pb-1" bind:this={kanbanRef}>
      <div class="flex gap-3 min-w-max">
        {#each weekDays as day (toISO(day))}
          {@const key = toISO(day)}
          {@const isToday = key === today}
          {@const dayTasks = tasksByDay.get(key) ?? []}
          <div
            data-date={key}
            class="w-52 flex-shrink-0 flex flex-col rounded border border-gray-800"
          >
            <!-- Column header -->
            <div
              class="px-3 py-2 border-b border-gray-800 flex items-center gap-2"
              class:bg-gray-800={isToday}
            >
              <span class="text-xs text-gray-500 uppercase tracking-wide">{DAY_NAMES_SHORT[day.getDay()]}</span>
              <span
                class="text-sm font-medium w-6 h-6 flex items-center justify-center rounded-full"
                class:bg-blue-600={isToday}
                class:text-white={isToday}
                class:text-gray-400={!isToday}
              >{day.getDate()}</span>
            </div>

            <!-- Task cards -->
            <div class="p-2 flex flex-col gap-2 min-h-24 flex-1">
              {#each dayTasks as task (task.period.id)}
                <TaskCard
                  {task}
                  onToggle={toggleTask}
                  onEdit={() => { modal = { mode: 'edit', task } }}
                  showLevel={false}
                />
              {/each}
            </div>

            <!-- Column footer: quick-create or add button -->
            <div class="p-2 border-t border-gray-800/50">
              {#if quickCreateDay === key}
                <div class="flex items-center gap-1">
                  <input
                    type="text"
                    bind:value={quickTitle}
                    onkeydown={(e) => handleQuickKeydown(e, key)}
                    placeholder="Название задачи..."
                    autofocus
                    class="flex-1 text-xs bg-gray-800 text-gray-200 placeholder-gray-600 border border-gray-700 rounded px-2 py-1.5 outline-none focus:border-blue-600"
                  />
                  <!-- Expand to full modal -->
                  <button
                    type="button"
                    onclick={() => { cancelQuickCreate(); modal = { mode: 'create', defaultLevel: 'day', defaultPeriodStart: key } }}
                    class="p-1 text-gray-500 hover:text-gray-300 rounded hover:bg-gray-700 transition-colors flex-shrink-0"
                    aria-label="Открыть полную форму"
                    title="Открыть полную форму"
                  >
                    <svg class="w-3.5 h-3.5" viewBox="0 0 16 16" fill="none">
                      <path d="M10 2h4v4M14 2l-5 5M6 14H2v-4M2 14l5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                  </button>
                </div>
              {:else}
                <button
                  onclick={() => startQuickCreate(key)}
                  class="w-full text-left text-xs text-gray-600 hover:text-gray-400 py-1 px-1 rounded hover:bg-gray-800/50 transition-colors"
                >
                  + Добавить задачу
                </button>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    </div>
  </section>

  <!-- ── Задачи месяца ──────────────────────────────────── -->
  {#if monthTasks.length > 0}
    <section class="mb-6">
      <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Задачи месяца</h2>
      <div class="flex flex-col gap-2">
        {#each monthTasks as task (task.period.id)}
          <TaskCard {task} onToggle={toggleTask} />
        {/each}
      </div>
    </section>
  {/if}

  <!-- ── Задачи года ────────────────────────────────────── -->
  {#if yearTasks.length > 0}
    <section>
      <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Задачи года</h2>
      <div class="flex flex-col gap-2">
        {#each yearTasks as task (task.period.id)}
          <TaskCard {task} onToggle={toggleTask} />
        {/each}
      </div>
    </section>
  {/if}
</div>

<!-- Task modal (create or edit) -->
{#if modal}
  <TaskModal state={modal} onClose={() => { modal = null }} />
{/if}
