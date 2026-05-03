<script lang="ts">
  import { taskStore, tasksApi } from '$entities/task'
  import type { TaskWithPeriod } from '$entities/task'
  import TaskFormFields from '$entities/task/ui/TaskFormFields.svelte'

  type Props = {
    task: TaskWithPeriod
    onClose?: () => void
  }
  const { task, onClose }: Props = $props()

  let title = $state(task.title)
  let description = $state(task.description ?? '')
  let level = $state(task.level)
  let targetDate = $state(task.period.targetDate ?? '')
  let deadlineMonth = $state(task.period.deadlineMonth?.toString() ?? '')
  let recurring = $state(!!task.recurringConfig)
  let dayOfWeek = $state(task.recurringConfig?.dayOfWeek?.toString() ?? '')
  let dayOfMonth = $state(task.recurringConfig?.dayOfMonth?.toString() ?? '')

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    if (!title.trim()) return

    const now = new Date().toISOString()
    const dm = deadlineMonth ? parseInt(deadlineMonth) : undefined
    const dow = dayOfWeek ? parseInt(dayOfWeek) : undefined
    const dom = dayOfMonth ? parseInt(dayOfMonth) : undefined

    const updated: TaskWithPeriod = {
      ...task,
      title: title.trim(),
      description: description.trim() || undefined,
      level,
      recurringConfig: recurring
        ? {
            id: task.recurringConfig?.id ?? crypto.randomUUID(),
            taskId: task.id,
            isActive: true,
            dayOfWeek: level === 'week' ? dow : undefined,
            dayOfMonth: level === 'month' ? dom : undefined,
            createdAt: task.recurringConfig?.createdAt ?? now,
          }
        : undefined,
      updatedAt: now,
      period: {
        ...task.period,
        targetDate: level === 'week' && targetDate ? targetDate : undefined,
        deadlineMonth: level === 'year' ? dm : undefined,
        updatedAt: now,
      },
    }

    taskStore.upsert(updated)
    onClose?.()

    try {
      await tasksApi.updatePeriod(task.period.id, {
        title: updated.title,
        description: updated.description,
      })
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
      onclick={onClose}
      class="text-sm text-gray-500 hover:text-gray-300 px-3 py-1.5 rounded-lg hover:bg-gray-800 transition-colors"
    >
      Отмена
    </button>
    <button
      type="submit"
      disabled={!title.trim()}
      class="bg-blue-600 hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed text-sm text-white px-4 py-1.5 rounded-lg transition-colors"
    >
      Сохранить
    </button>
  </div>
</form>
