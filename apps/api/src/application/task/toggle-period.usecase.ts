import type { ITaskRepository } from '../../domain/task/task.port.js'
import type { TaskPeriod } from '@locus/shared'

/**
 * Toggle a period between todo ↔ done.
 * done → sets done_at; todo → clears done_at.
 */
export const togglePeriodUseCase = async (
  tasks: ITaskRepository,
  periodId: string,
  userId: string,
  newStatus: 'todo' | 'done',
): Promise<TaskPeriod> => {
  const now = new Date().toISOString()
  const timestamps = newStatus === 'done'
    ? { doneAt: now }
    : { doneAt: null }

  const period = await tasks.updatePeriodStatus(periodId, userId, newStatus, timestamps)
  if (!period) throw Object.assign(new Error('Period not found'), { statusCode: 404 })
  return period
}
