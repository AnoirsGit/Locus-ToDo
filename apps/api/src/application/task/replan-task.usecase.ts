import type { ITaskRepository } from '../../domain/task/task.port.js'
import type { TaskWithPeriod } from '@locus/shared'
import { computePeriodEnd, toMonday } from '../period-utils.js'

/**
 * Replan a backlog task to a new period (atomic):
 * 1. Find the backlog period for the given taskId
 * 2. Archive the old backlog period (failure — done_at stays NULL)
 * 3. Create a new todo period at the target periodStart
 *
 * Both steps run via the repository's replan method to ensure atomicity.
 */
export const replanTaskUseCase = async (
  tasks: ITaskRepository,
  taskId: string,
  userId: string,
  newPeriodStart: string,
): Promise<TaskWithPeriod> => {
  const existing = await tasks.findBacklogPeriodByTaskId(taskId, userId)
  if (!existing) {
    throw Object.assign(new Error('No backlog period found for this task'), { statusCode: 404 })
  }

  // Snap week to Monday in case the client sends an arbitrary day
  const periodStart = existing.level === 'week' ? toMonday(newPeriodStart) : newPeriodStart
  const periodEnd   = computePeriodEnd(existing.level, periodStart)

  return tasks.replanTask({
    taskId: existing.id,
    userId,
    level: existing.level,
    oldPeriodId: existing.period.id,
    newPeriodStart: periodStart,
    newPeriodEnd: periodEnd,
    targetDate: existing.period.targetDate,
    deadlineMonth: existing.period.deadlineMonth,
  })
}
