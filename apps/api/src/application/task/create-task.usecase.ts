import type { ITaskRepository } from '../../domain/task/task.port.js'
import type { TaskWithPeriod } from '@locus/shared'
import { computePeriodEnd } from '../period-utils.js'

export type CreateTaskInput = {
  userId: string
  title: string
  description?: string
  level: string
  scheduledTime?: string
  periodStart: string
  targetDate?: string
  deadlineMonth?: number
  parentTaskId?: string
  recurringConfig?: { daysOfWeek?: number[]; dayOfMonth?: number; isActive: boolean }
}

export const createTaskUseCase = async (
  tasks: ITaskRepository,
  input: CreateTaskInput,
): Promise<TaskWithPeriod> => {
  if (input.parentTaskId && input.recurringConfig) {
    throw Object.assign(new Error('Subtasks cannot be recurring'), { statusCode: 400 })
  }

  const periodEnd = computePeriodEnd(input.level as any, input.periodStart)
  return tasks.createTask({ ...(input as any), periodEnd })
}
