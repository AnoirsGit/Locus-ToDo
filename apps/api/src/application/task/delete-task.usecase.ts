import type { ITaskRepository } from '../../domain/task/task.port.js'

/**
 * Deletes a task.
 * Blocked (409) only if the task has archived periods from a completed/failed run —
 * i.e., it has historical data worth preserving.
 * Tasks with only active (todo/overdue/backlog) periods can be freely deleted.
 */
export const deleteTaskUseCase = async (
  tasks: ITaskRepository,
  taskId: string,
  userId: string,
): Promise<void> => {
  const hasArchived = await tasks.hasArchivedPeriods(taskId)
  if (hasArchived) {
    throw Object.assign(
      new Error('Cannot delete a task that has archived periods. Archive it instead.'),
      { statusCode: 409 },
    )
  }

  const deleted = await tasks.deleteTask(taskId, userId)
  if (!deleted) throw Object.assign(new Error('Task not found'), { statusCode: 404 })
}
