<script lang="ts">
  import { TaskFormFields } from '$entities/task'
  import type { TaskLevel } from '$entities/task'
  import { createTask } from '$features/create-task'
  import { tagsApi } from '$shared/api/tags.api'
  import { tagStore } from '$entities/tag'

  type Props = {
    defaultLevel?: TaskLevel
    defaultPeriodStart?: string
    onSuccess?: () => void
    onCancel?: () => void
  }
  const { defaultLevel = 'week', defaultPeriodStart, onSuccess, onCancel }: Props = $props()

  let title         = $state('')
  let description   = $state('')
  let level         = $state<TaskLevel>(defaultLevel)
  let scheduledTime = $state('')
  let targetDate    = $state('')
  let deadlineMonth = $state('')
  let recurring     = $state(false)
  let daysOfWeek    = $state<number[]>([])
  let dayOfMonth    = $state('')
  let tagIds        = $state<string[]>([])

  const computePeriodStart = (): string => {
    const now = new Date()
    const fmt = (d: Date) => d.toISOString().split('T')[0]
    if (level === 'day') return defaultPeriodStart ?? fmt(now)
    if (level === 'week') {
      const dow = now.getDay()
      const diff = dow === 0 ? -6 : 1 - dow
      const mon = new Date(now)
      mon.setDate(now.getDate() + diff)
      return fmt(mon)
    }
    if (level === 'month') return fmt(new Date(now.getFullYear(), now.getMonth(), 1))
    return `${now.getFullYear()}-01-01`
  }

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    if (!title.trim()) return

    const dom = dayOfMonth ? parseInt(dayOfMonth) : undefined

    const item = await createTask({
      title: title.trim(),
      description: description.trim() || undefined,
      level,
      periodStart: computePeriodStart(),
      scheduledTime: scheduledTime || undefined,
      targetDate: level === 'week' && targetDate ? targetDate : undefined,
      deadlineMonth: level === 'year' && deadlineMonth ? parseInt(deadlineMonth) : undefined,
      recurringConfig: recurring
        ? {
            isActive: true,
            daysOfWeek: level === 'week' && daysOfWeek.length > 0 ? daysOfWeek : undefined,
            dayOfMonth: level === 'month' ? dom : undefined,
          }
        : undefined,
    })

    if (tagIds.length > 0) {
      tagsApi.setTaskTags(item.id, tagIds).then(() => tagStore.setTaskTagsLocal(item.id, tagIds)).catch(() => {})
    }

    onSuccess?.()
  }
</script>

<form onsubmit={handleSubmit} class="flex flex-col">
  <TaskFormFields
    bind:title bind:description bind:level bind:scheduledTime
    bind:targetDate bind:deadlineMonth bind:recurring bind:daysOfWeek bind:dayOfMonth
    bind:tagIds
  />
  <div class="modal-footer">
    <button type="button" onclick={onCancel} class="btn ghost">Отмена</button>
    <button type="submit" disabled={!title.trim()} class="btn primary">Создать</button>
  </div>
</form>
