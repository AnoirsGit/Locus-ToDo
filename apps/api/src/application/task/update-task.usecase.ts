import type { ITaskRepository, UpdateTaskInput } from '../../domain/task/task.port.js'
import type { TaskWithPeriod } from '@locus/shared'

export const updateTaskUseCase = async (
  tasks: ITaskRepository,
  taskId: string,
  userId: string,
  patch: UpdateTaskInput,
): Promise<TaskWithPeriod> => {
  const result = await tasks.updateTask(taskId, userId, patch)
  if (!result) throw Object.assign(new Error('Task not found'), { statusCode: 404 })
  return result
}
