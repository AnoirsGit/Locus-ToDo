import type { ITaskRepository } from '../../domain/task/task.port.js'
import type { TaskLevel, TaskWithPeriod } from '@locus/shared'
import { computePeriodEnd } from '../period-utils.js'

export type CreateTaskInput = {
  userId: string
  title: string
  description?: string
  level: TaskLevel
  scheduledTime?: string
  periodStart: string
  targetDate?: string
  deadlineMonth?: number
  recurringConfig?: { dayOfWeek?: number; dayOfMonth?: number; isActive: boolean }
}

export const createTaskUseCase = async (
  tasks: ITaskRepository,
  input: CreateTaskInput,
): Promise<TaskWithPeriod> => {
  const periodEnd = computePeriodEnd(input.level, input.periodStart)
  return tasks.createTask({ ...input, periodEnd })
}
