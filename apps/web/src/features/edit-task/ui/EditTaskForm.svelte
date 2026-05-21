<script lang="ts">
  import { TaskFormFields, taskStore, tasksApi } from '$entities/task'
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { tagsApi } from '$shared/api/tags.api'
  import { tagStore } from '$entities/tag'
  import { onMount } from 'svelte'

  type Props = { task: TaskWithPeriod; onClose?: () => void }
  const { task, onClose }: Props = $props()

  let title         = $state(task.title)
  let description   = $state(task.description ?? '')
  let level         = $state<TaskLevel>(task.level)
  let scheduledTime = $state(task.scheduledTime ?? '')
  let targetDate    = $state(task.period.targetDate ?? '')
  let deadlineMonth = $state(task.period.deadlineMonth?.toString() ?? '')
  let recurring     = $state(!!task.recurringConfig)
  let daysOfWeek    = $state<number[]>(task.recurringConfig?.daysOfWeek ?? [])
  let dayOfMonth    = $state(task.recurringConfig?.dayOfMonth?.toString() ?? '')

  let subtasks = $state<TaskWithPeriod[]>([])
  let tagIds = $state<string[]>([])

  onMount(async () => {
    try {
      subtasks = await tasksApi.getSubtasks(task.id)
    } catch { /* no subtasks or offline */ }
    try {
      const tags = await tagsApi.getTaskTags(task.id)
      tagIds = tags.map(t => t.id)
    } catch { /* offline or no tags */ }
  })

  const handleAddSubtask = async (subTitle: string) => {
    const now = new Date().toISOString()
    const item = await tasksApi.create({
      title: subTitle,
      level: task.level,
      periodStart: task.period.periodStart,
      parentTaskId: task.id,
    })
    subtasks = [...subtasks, item]
  }

  const handleToggleSubtask = (periodId: string) => {
    const sub = subtasks.find(s => s.period.id === periodId)
    if (!sub) return
    const newStatus = sub.period.status === 'done' ? 'todo' : 'done'
    // Optimistic update
    subtasks = subtasks.map(s =>
      s.period.id === periodId
        ? { ...s, period: { ...s.period, status: newStatus } }
        : s
    )
    tasksApi.updatePeriod(periodId, { status: newStatus }).catch(() => {
      // revert on error
      subtasks = subtasks.map(s => s.period.id === periodId ? sub : s)
    })
  }

  const handleDeleteSubtask = async (taskId: string) => {
    subtasks = subtasks.filter(s => s.id !== taskId)
    try { await tasksApi.remove(taskId) } catch {
      // restore on error
      subtasks = await tasksApi.getSubtasks(task.id)
    }
  }

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    if (!title.trim()) return

    const now = new Date().toISOString()
    const dm  = deadlineMonth ? parseInt(deadlineMonth) : undefined
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
            daysOfWeek: level === 'week' && daysOfWeek.length > 0 ? daysOfWeek : undefined,
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
        recurringConfig: updated.recurringConfig
          ? { isActive: true, daysOfWeek: updated.recurringConfig.daysOfWeek, dayOfMonth: updated.recurringConfig.dayOfMonth }
          : null,
      })
      taskStore.upsert(saved)
    } catch {
      // keep optimistic update
    }
    tagsApi.setTaskTags(task.id, tagIds).catch(() => { /* best effort */ })
    tagStore.setTaskTagsLocal(task.id, tagIds)
  }
</script>

<form onsubmit={handleSubmit} class="flex flex-col">
  <TaskFormFields
    bind:title bind:description bind:level bind:scheduledTime
    bind:targetDate bind:deadlineMonth bind:recurring bind:daysOfWeek bind:dayOfMonth
    bind:tagIds
    {subtasks}
    onAddSubtask={handleAddSubtask}
    onToggleSubtask={handleToggleSubtask}
    onDeleteSubtask={handleDeleteSubtask}
  />
  <div class="modal-footer">
    <button type="button" onclick={onClose} class="btn ghost">Отмена</button>
    <button type="submit" disabled={!title.trim()} class="btn primary">Сохранить</button>
  </div>
</form>
