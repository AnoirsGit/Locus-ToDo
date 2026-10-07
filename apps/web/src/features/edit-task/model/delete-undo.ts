import { tasksApi, taskStore } from '$entities/task'
import type { TaskWithPeriod, TaskLevel } from '$entities/task'
import { tagStore } from '$entities/tag'
import { tagsApi } from '$shared/api/tags.api'
import { toastStore } from '$shared/lib/toast.svelte'
import { i18n } from '$shared/lib/i18n'

/**
 * What a client-side re-create restores. DELETE is refused (409) once a task
 * has archived periods, so a deletable task is fully described by its metadata
 * and its single live period.
 */
export type DeletedTask = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string
  scheduledTime?: string
  targetDate?: string
  deadlineMonth?: number
  recurringConfig?: { daysOfWeek?: number[]; dayOfMonth?: number }
  done: boolean
  tagIds: string[]
}

/**
 * Undo is offered only when the re-create is faithful. `overdue`/`backlog` are
 * set by the scheduler and cannot be re-created through the API: the copy
 * would come back as a fresh `todo` and silently skip its penalty.
 */
export const canUndoDelete = (task: TaskWithPeriod): boolean =>
  task.period.status === 'todo' || task.period.status === 'done'

// The API serializes absent values as null and times as HH:MM:SS, while the
// create endpoint only accepts omitted fields and HH:MM.
export const snapshotForUndo = (task: TaskWithPeriod, tagIds: string[]): DeletedTask => {
  const rc = task.recurringConfig
  return {
    title: task.title,
    description: task.description ?? undefined,
    level: task.level,
    periodStart: task.period.periodStart,
    scheduledTime: task.scheduledTime ? task.scheduledTime.slice(0, 5) : undefined,
    targetDate: task.period.targetDate ?? undefined,
    deadlineMonth: task.period.deadlineMonth ?? undefined,
    recurringConfig: rc
      ? {
          daysOfWeek: rc.daysOfWeek?.length ? rc.daysOfWeek : undefined,
          dayOfMonth: rc.dayOfMonth ?? undefined,
        }
      : undefined,
    done: task.period.status === 'done',
    tagIds: [...tagIds],
  }
}

/** Re-create a just-deleted task (it gets new ids) with its done state and tags. */
export const restoreDeletedTask = async (snap: DeletedTask): Promise<void> => {
  let item: TaskWithPeriod
  try {
    item = await tasksApi.create(
      {
        title: snap.title,
        description: snap.description,
        level: snap.level,
        periodStart: snap.periodStart,
        scheduledTime: snap.level === 'day' ? snap.scheduledTime : undefined,
        targetDate: snap.level === 'week' ? snap.targetDate : undefined,
        deadlineMonth: snap.level === 'year' ? snap.deadlineMonth : undefined,
        recurringConfig: snap.recurringConfig ? { isActive: true, ...snap.recurringConfig } : undefined,
      },
      { quiet: true },
    )
  } catch {
    toastStore.error(i18n.t('undo.task_restore_failed'))
    return
  }
  taskStore.upsert(item)

  if (snap.tagIds.length > 0) {
    tagStore.setTaskTagsLocal(item.id, snap.tagIds)
    tagsApi.setTaskTags(item.id, snap.tagIds).catch(() => { /* client already toasted */ })
  }

  if (snap.done) {
    try {
      const period = await tasksApi.updatePeriod(item.period.id, { status: 'done' })
      // Patch status + doneAt only (see toggleTask: date columns may not be plain strings).
      taskStore.updatePeriod(item.period.id, { status: period.status, doneAt: period.doneAt ?? undefined })
    } catch {
      /* client already toasted; the task stays restored as todo */
    }
  }
}
