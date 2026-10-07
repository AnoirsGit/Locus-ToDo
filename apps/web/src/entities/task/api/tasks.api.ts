import { api, type CallOptions } from '$shared/api/client'
import type { TaskPeriod, TaskWithPeriod, TaskLevel, TaskStatus, RecurringConfig } from '../model/task.types'

type CreateTaskDto = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string
  deadlineMonth?: number
  targetDate?: string
  scheduledTime?: string
  parentTaskId?: string
  recurringConfig?: Omit<RecurringConfig, 'id' | 'taskId' | 'createdAt'>
}

type UpdateTaskDto = Partial<{
  title: string
  description: string | null
  scheduledTime: string | null
  targetDate: string | null
  deadlineMonth: number | null
  recurringConfig: Omit<RecurringConfig, 'id' | 'taskId' | 'createdAt'> | null
}>

type UpdatePeriodDto = Partial<{
  status: TaskStatus
}>

export const tasksApi = {
  /** Get tasks with their current period for a given week/month/year */
  getByPeriod: (params: { periodType: TaskLevel; periodStart: string }, opts?: CallOptions) =>
    api.get<TaskWithPeriod[]>(`/tasks?${new URLSearchParams(params).toString()}`, opts),

  /** Get all backlog periods */
  getBacklog: (opts?: CallOptions) => api.get<TaskWithPeriod[]>('/tasks?status=backlog', opts),

  /** Get archived */
  getArchive: (opts?: CallOptions) => api.get<TaskWithPeriod[]>('/tasks?status=archived', opts),

  create: (dto: CreateTaskDto, opts?: CallOptions) => api.post<TaskWithPeriod>('/tasks', dto, opts),

  /** Update task metadata (title, description) */
  update: (taskId: string, dto: UpdateTaskDto) =>
    api.patch<TaskWithPeriod>(`/tasks/${taskId}`, dto),

  /** Toggle period status (done ↔ todo) */
  updatePeriod: (periodId: string, dto: UpdatePeriodDto, opts?: CallOptions) =>
    api.patch<TaskPeriod>(`/task-periods/${periodId}`, dto, opts),

  /** Replan: create a new period for the task in the next period */
  replan: (taskId: string, dto: { periodStart: string }) =>
    api.post<TaskWithPeriod>(`/tasks/${taskId}/replan`, dto),

  remove: (taskId: string, opts?: CallOptions) => api.delete<void>(`/tasks/${taskId}`, opts),

  /** Get subtasks for a task */
  getSubtasks: (taskId: string) => api.get<TaskWithPeriod[]>(`/tasks/${taskId}/subtasks`),
}
