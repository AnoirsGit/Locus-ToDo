import type { ITaskRepository } from '../../domain/task/task.port.js'
import type { TaskWithPeriod } from '@locus/shared'
import { computePeriodEnd } from '../period-utils.js'

/**
 * Replan a backlog task to a new period:
 * 1. Find the backlog period for the given taskId
 * 2. Archive the old backlog period (failure — done_at stays NULL)
 * 3. Create a new todo period at the target periodStart
 */
export const replanTaskUseCase = async (
  tasks: ITaskRepository,
  taskId: string,
  userId: string,
  newPeriodStart: string,
): Promise<TaskWithPeriod> => {
  const now = new Date().toISOString()

  const existing = await tasks.findBacklogPeriodByTaskId(taskId, userId)
  if (!existing) throw Object.assign(new Error('No backlog period found for this task'), { statusCode: 404 })

  // Archive the old backlog period
  await tasks.updatePeriodStatus(existing.period.id, userId, 'archived', { archivedAt: now })

  const newPeriodEnd = computePeriodEnd(existing.level, newPeriodStart)

  return tasks.createPeriod({
    taskId: existing.id,
    userId,
    level: existing.level,
    periodStart: newPeriodStart,
    periodEnd: newPeriodEnd,
    targetDate: existing.period.targetDate,
    deadlineMonth: existing.period.deadlineMonth,
  })
}
