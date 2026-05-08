import type { ITaskRepository } from '../../domain/task/task.port.js'

/**
 * Deletes a task.
 * Blocked (409) if the task itself OR any of its subtasks have archived periods —
 * i.e., historical data that is worth preserving.
 * Tasks with only active (todo/overdue/backlog) periods can be freely deleted.
 */
export const deleteTaskUseCase = async (
  tasks: ITaskRepository,
  taskId: string,
  userId: string,
): Promise<void> => {
  const [hasArchived, subtasksArchived] = await Promise.all([
    tasks.hasArchivedPeriods(taskId),
    tasks.subtasksHaveArchivedPeriods(taskId),
  ])

  if (hasArchived || subtasksArchived) {
    throw Object.assign(
      new Error('Cannot delete a task that has archived periods. Archive it instead.'),
      { statusCode: 409 },
    )
  }

  const deleted = await tasks.deleteTask(taskId, userId)
  if (!deleted) throw Object.assign(new Error('Task not found'), { statusCode: 404 })
}
