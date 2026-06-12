<script lang="ts">
  import { TaskFormFields, taskStore, tasksApi } from '$entities/task'
  import type { TaskWithPeriod, TaskLevel } from '$entities/task'
  import { tagsApi } from '$shared/api/tags.api'
  import { tagStore } from '$entities/tag'
  import { ApiError } from '$shared/api/client'
  import { i18n } from '$shared/lib/i18n'
  import { toLocalISO, weekStartISO, monthStartISO, yearStartISO } from '$shared/lib/date'
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

  // Danger zone: delete (any task) + replan (backlog only)
  let confirming  = $state<'delete' | 'replan' | null>(null)
  let dangerBusy  = $state(false)
  let deleteError = $state<string | null>(null)

  const isBacklog = task.period.status === 'backlog'

  const replanPeriodStart = (): string => {
    const now = new Date()
    if (task.level === 'day') return toLocalISO(now)
    if (task.level === 'week') return weekStartISO(now)
    if (task.level === 'month') return monthStartISO(now)
    return yearStartISO(now)
  }

  const handleDelete = async () => {
    dangerBusy = true
    deleteError = null
    try {
      await tasksApi.remove(task.id)
      taskStore.removeByTaskId(task.id)
      onClose?.()
    } catch (e) {
      // API contract: 409 when the task has archived periods (hard delete blocked)
      deleteError = e instanceof ApiError && e.status === 409
        ? i18n.t('action.delete_blocked')
        : e instanceof Error ? e.message : String(e)
      confirming = null
    } finally {
      dangerBusy = false
    }
  }

  const handleReplan = async () => {
    dangerBusy = true
    try {
      const saved = await tasksApi.replan(task.id, { periodStart: replanPeriodStart() })
      // Old backlog period is archived as a failure server-side; mirror locally
      taskStore.updatePeriod(task.period.id, { status: 'archived' })
      taskStore.upsert(saved)
      onClose?.()
    } catch {
      confirming = null // API client already showed the error toast
    } finally {
      dangerBusy = false
    }
  }

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

<form
  onsubmit={handleSubmit}
  onkeydown={(e) => { if (e.key === 'Enter' && (e.ctrlKey || e.metaKey) && title.trim()) (e.currentTarget as HTMLFormElement).requestSubmit() }}
  class="flex flex-col"
>
  <TaskFormFields
    bind:title bind:description bind:level bind:scheduledTime
    bind:targetDate bind:deadlineMonth bind:recurring bind:daysOfWeek bind:dayOfMonth
    bind:tagIds
    {subtasks}
    onAddSubtask={handleAddSubtask}
    onToggleSubtask={handleToggleSubtask}
    onDeleteSubtask={handleDeleteSubtask}
  />
  {#if deleteError}
    <p class="px-1 pt-2 text-sm" style="color: var(--color-danger)">{deleteError}</p>
  {/if}

  <div class="modal-footer">
    <div class="flex items-center gap-2 mr-auto">
      {#if confirming === 'delete'}
        <span class="text-sm text-muted">{i18n.t('action.delete_confirm')}</span>
        <button type="button" class="btn ghost sm" style="color: var(--color-danger)" disabled={dangerBusy} onclick={handleDelete}>
          {i18n.t('action.delete')}
        </button>
        <button type="button" class="btn ghost sm" onclick={() => { confirming = null }}>{i18n.t('action.cancel')}</button>
      {:else if confirming === 'replan'}
        <span class="text-sm text-muted">{i18n.t('action.replan_confirm')} ({replanPeriodStart()})</span>
        <button type="button" class="btn ghost sm" disabled={dangerBusy} onclick={handleReplan}>{i18n.t('action.replan')}</button>
        <button type="button" class="btn ghost sm" onclick={() => { confirming = null }}>{i18n.t('action.cancel')}</button>
      {:else}
        <button type="button" class="btn ghost sm" style="color: var(--color-danger)" onclick={() => { confirming = 'delete'; deleteError = null }}>
          {i18n.t('action.delete')}
        </button>
        {#if isBacklog}
          <button type="button" class="btn ghost sm" onclick={() => { confirming = 'replan' }}>{i18n.t('action.replan')}</button>
        {/if}
      {/if}
    </div>
    <button type="button" onclick={onClose} class="btn ghost">{i18n.t('action.cancel')}</button>
    <button type="submit" disabled={!title.trim()} class="btn primary">{i18n.t('action.save')}</button>
  </div>
</form>
