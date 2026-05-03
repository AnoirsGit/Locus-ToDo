<script lang="ts">
  import { taskStore, tasksApi } from '$entities/task'
  import type { TaskLevel, TaskWithPeriod } from '$entities/task'
  import TaskFormFields from '$entities/task/ui/TaskFormFields.svelte'

  type Props = {
    defaultLevel: TaskLevel
    defaultPeriodStart?: string
    onSuccess?: () => void
    onCancel?: () => void
  }
  const { defaultLevel, defaultPeriodStart, onSuccess, onCancel }: Props = $props()

  let title = $state('')
  let description = $state('')
  let level = $state<TaskLevel>(defaultLevel)
  let targetDate = $state('')
  let deadlineMonth = $state('')
  let recurring = $state(false)
  let dayOfWeek = $state('')
  let dayOfMonth = $state('')

  // Clear level-specific fields when level changes
  $effect(() => {
    if (level !== 'week') { targetDate = ''; dayOfWeek = '' }
    if (level !== 'year') { deadlineMonth = '' }
    if (level !== 'month') { dayOfMonth = '' }
  })

  const computePeriod = (lvl: TaskLevel): { periodStart: string; periodEnd: string } => {
    const now = new Date()
    const fmt = (d: Date) => d.toISOString().split('T')[0]
    if (lvl === 'day') {
      const date = defaultPeriodStart ?? fmt(now)
      return { periodStart: date, periodEnd: date }
    }
    if (lvl === 'week') {
      const day = now.getDay()
      const diff = day === 0 ? -6 : 1 - day
      const monday = new Date(now)
      monday.setDate(now.getDate() + diff)
      const sunday = new Date(monday)
      sunday.setDate(monday.getDate() + 6)
      return { periodStart: fmt(monday), periodEnd: fmt(sunday) }
    }
    if (lvl === 'month') {
      const start = new Date(now.getFullYear(), now.getMonth(), 1)
      const end = new Date(now.getFullYear(), now.getMonth() + 1, 0)
      return { periodStart: fmt(start), periodEnd: fmt(end) }
    }
    return {
      periodStart: `${now.getFullYear()}-01-01`,
      periodEnd: `${now.getFullYear()}-12-31`,
    }
  }

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    if (!title.trim()) return

    const now = new Date().toISOString()
    const { periodStart, periodEnd } = computePeriod(level)
    const dm = deadlineMonth ? parseInt(deadlineMonth) : undefined
    const dow = dayOfWeek ? parseInt(dayOfWeek) : undefined
    const dom = dayOfMonth ? parseInt(dayOfMonth) : undefined
    const taskId = crypto.randomUUID()
    const periodId = crypto.randomUUID()

    const newTask: TaskWithPeriod = {
      id: taskId,
      userId: 'u1',
      title: title.trim(),
      description: description.trim() || undefined,
      level,
      recurringConfig: recurring
        ? {
            id: crypto.randomUUID(),
            taskId,
            isActive: true,
            dayOfWeek: level === 'week' ? dow : undefined,
            dayOfMonth: level === 'month' ? dom : undefined,
            createdAt: now,
          }
        : undefined,
      createdAt: now,
      updatedAt: now,
      period: {
        id: periodId,
        taskId,
        userId: 'u1',
        periodType: level,
        periodStart,
        periodEnd,
        status: 'todo',
        targetDate: level === 'week' && targetDate ? targetDate : undefined,
        deadlineMonth: level === 'year' ? dm : undefined,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      },
    }

    taskStore.upsert(newTask)

    // Reset form
    title = ''
    description = ''
    targetDate = ''
    deadlineMonth = ''
    recurring = false
    dayOfWeek = ''
    dayOfMonth = ''
    level = defaultLevel

    onSuccess?.()

    try {
      const created = await tasksApi.create({
        title: newTask.title,
        description: newTask.description,
        level,
        periodStart,
        deadlineMonth: level === 'year' ? dm : undefined,
      })
      taskStore.upsert(created)
    } catch {
      // keep optimistic update
    }
  }
</script>

<form onsubmit={handleSubmit} class="flex flex-col">
  <TaskFormFields
    bind:title
    bind:description
    bind:level
    bind:targetDate
    bind:deadlineMonth
    bind:recurring
    bind:dayOfWeek
    bind:dayOfMonth
  />
  <div class="flex gap-2 justify-end p-4 border-t border-gray-800">
    <button
      type="button"
      onclick={onCancel}
      class="text-sm text-gray-500 hover:text-gray-300 px-3 py-1.5 rounded-lg hover:bg-gray-800 transition-colors"
    >
      Отмена
    </button>
    <button
      type="submit"
      disabled={!title.trim()}
      class="bg-blue-600 hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed text-sm text-white px-4 py-1.5 rounded-lg transition-colors"
    >
      Создать
    </button>
  </div>
</form>
