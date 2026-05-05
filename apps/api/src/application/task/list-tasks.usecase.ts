import type { ITaskRepository } from '../../domain/task/task.port.js'
import type { TaskLevel, TaskWithPeriod } from '@locus/shared'

export const listTasksUseCase = async (
  tasks: ITaskRepository,
  userId: string,
  periodType: TaskLevel,
  periodStart: string,
): Promise<TaskWithPeriod[]> =>
  tasks.listPeriods({ userId, periodType, periodStart, statuses: ['todo', 'done', 'overdue'] })

export const listBacklogUseCase = async (
  tasks: ITaskRepository,
  userId: string,
): Promise<TaskWithPeriod[]> => tasks.listBacklog(userId)

export const listArchiveUseCase = async (
  tasks: ITaskRepository,
  userId: string,
  limit = 50,
  offset = 0,
): Promise<TaskWithPeriod[]> => tasks.listArchive(userId, limit, offset)
