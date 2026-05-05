import type { ITaskRepository } from '../../domain/task/task.port.js'

export const deleteTaskUseCase = async (
  tasks: ITaskRepository,
  taskId: string,
  userId: string,
): Promise<void> => {
  const hasArchived = await tasks.hasArchivedPeriods(taskId)
  if (hasArchived) {
    throw Object.assign(
      new Error('Cannot delete a task that has archived periods'),
      { statusCode: 409 },
    )
  }

  const deleted = await tasks.deleteTask(taskId, userId)
  if (!deleted) throw Object.assign(new Error('Task not found'), { statusCode: 404 })
}
