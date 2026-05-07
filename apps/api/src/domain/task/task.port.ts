import type { TaskLevel, TaskStatus, TaskWithPeriod, TaskPeriod } from '@locus/shared'

export type CreateTaskInput = {
  userId: string
  title: string
  description?: string
  level: TaskLevel
  scheduledTime?: string
  periodStart: string
  periodEnd: string
  targetDate?: string
  deadlineMonth?: number
  recurringConfig?: {
    dayOfWeek?: number
    dayOfMonth?: number
    monthOfYear?: number
    isActive: boolean
  }
}

export type UpdateTaskInput = {
  // Task fields
  title?: string
  description?: string | null
  scheduledTime?: string | null
  // Period fields (applied to the current active period)
  targetDate?: string | null
  deadlineMonth?: number | null
  // Recurring config: null = delete, object = upsert
  recurringConfig?: {
    dayOfWeek?: number
    dayOfMonth?: number
    monthOfYear?: number
    isActive: boolean
  } | null
}

export type ListPeriodsInput = {
  userId: string
  periodType: TaskLevel
  periodStart: string
  statuses?: TaskStatus[]
}

export type ITaskRepository = {
  listPeriods(input: ListPeriodsInput): Promise<TaskWithPeriod[]>
  listBacklog(userId: string): Promise<TaskWithPeriod[]>
  listArchive(userId: string, limit: number, offset: number): Promise<TaskWithPeriod[]>
  findPeriodById(periodId: string, userId: string): Promise<TaskWithPeriod | null>
  createTask(input: CreateTaskInput): Promise<TaskWithPeriod>
  updateTask(taskId: string, userId: string, patch: UpdateTaskInput): Promise<TaskWithPeriod | null>
  updatePeriodStatus(
    periodId: string,
    userId: string,
    status: TaskStatus,
    timestamps?: { doneAt?: string | null; backlogAt?: string; archivedAt?: string },
  ): Promise<TaskPeriod | null>
  createPeriod(input: {
    taskId: string
    userId: string
    level: TaskLevel
    periodStart: string
    periodEnd: string
    targetDate?: string
    deadlineMonth?: number
  }): Promise<TaskWithPeriod>
  findBacklogPeriodByTaskId(taskId: string, userId: string): Promise<TaskWithPeriod | null>
  replanTask(input: {
    taskId: string
    userId: string
    level: TaskLevel
    oldPeriodId: string
    newPeriodStart: string
    newPeriodEnd: string
    targetDate?: string
    deadlineMonth?: number
  }): Promise<TaskWithPeriod>
  hasArchivedPeriods(taskId: string): Promise<boolean>
  deleteTask(taskId: string, userId: string): Promise<boolean>
}
