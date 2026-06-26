<script lang="ts">
  import { TaskFormFields } from '$entities/task'
  import type { TaskLevel } from '$entities/task'
  import { createTask } from '$features/create-task'
  import { tagsApi } from '$shared/api/tags.api'
  import { tagStore } from '$entities/tag'
  import { i18n } from '$shared/lib/i18n'
  import { toLocalISO, weekStartISO, monthStartISO, yearStartISO } from '$shared/lib/date'

  type Props = {
    defaultLevel?: TaskLevel
    defaultPeriodStart?: string
    onSuccess?: () => void
    onCancel?: () => void
    dirty?: boolean
  }
  let { defaultLevel = 'week', defaultPeriodStart, onSuccess, onCancel, dirty = $bindable(false) }: Props = $props()

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

  // Report unsaved input upward so the modal can guard against accidental close.
  const isDirty = $derived(
    title.trim() !== '' || description.trim() !== '' || scheduledTime !== '' ||
    targetDate !== '' || deadlineMonth !== '' || recurring ||
    daysOfWeek.length > 0 || dayOfMonth !== '' || tagIds.length > 0,
  )
  $effect(() => { dirty = isDirty })

  const computePeriodStart = (): string => {
    const now = new Date()
    if (level === 'day') return defaultPeriodStart ?? toLocalISO(now)
    if (level === 'week') return weekStartISO(now)
    if (level === 'month') return monthStartISO(now)
    return yearStartISO(now)
  }

  let submitting = $state(false)

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    // Guard against double submit (Enter + click, or repeated Ctrl+Enter) while in flight.
    if (submitting || !title.trim()) return
    submitting = true

    const dom = dayOfMonth ? parseInt(dayOfMonth) : undefined

    try {
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
    } catch {
      // API client already surfaces the error toast; keep the form open to retry.
      submitting = false
    }
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
  />
  <div class="modal-footer">
    <button type="button" onclick={onCancel} class="btn ghost">{i18n.t('action.cancel')}</button>
    <button type="submit" disabled={submitting || !title.trim()} class="btn primary">{submitting ? i18n.t('action.saving') : i18n.t('action.create')}</button>
  </div>
</form>
