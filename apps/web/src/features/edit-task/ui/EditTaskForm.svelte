<script lang="ts">
  import { TaskFormFields, taskStore, tasksApi } from '$entities/task'
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'

  type Props = { task: TaskWithPeriod; onClose?: () => void }
  const { task, onClose }: Props = $props()

  let title         = $state(task.title)
  let description   = $state(task.description ?? '')
  let level         = $state<TaskLevel>(task.level)
  let scheduledTime = $state(task.scheduledTime ?? '')
  let targetDate    = $state(task.period.targetDate ?? '')
  let deadlineMonth = $state(task.period.deadlineMonth?.toString() ?? '')
  let recurring     = $state(!!task.recurringConfig)
  let dayOfWeek     = $state(task.recurringConfig?.dayOfWeek?.toString() ?? '')
  let dayOfMonth    = $state(task.recurringConfig?.dayOfMonth?.toString() ?? '')

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    if (!title.trim()) return

    const now = new Date().toISOString()
    const dm  = deadlineMonth ? parseInt(deadlineMonth) : undefined
    const dow = dayOfWeek ? parseInt(dayOfWeek) : undefined
    const dom = dayOfMonth ? parseInt(dayOfMonth) : undefined

    const updated: TaskWithPeriod = {
      ...task,
      title: title.trim(),
      description: description.trim() || undefined,
      level,
      scheduledTime: scheduledTime || undefined,
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
      const saved = await tasksApi.update(task.id, {
        title: updated.title,
        description: updated.description ?? null,
      })
      taskStore.upsert(saved)
    } catch {
      // keep optimistic update
    }
  }
</script>

<form onsubmit={handleSubmit} class="flex flex-col">
  <TaskFormFields
    bind:title bind:description bind:level bind:scheduledTime
    bind:targetDate bind:deadlineMonth bind:recurring bind:dayOfWeek bind:dayOfMonth
  />
  <div class="modal-footer">
    <button type="button" onclick={onClose} class="btn ghost">Отмена</button>
    <button type="submit" disabled={!title.trim()} class="btn primary">Сохранить</button>
  </div>
</form>
