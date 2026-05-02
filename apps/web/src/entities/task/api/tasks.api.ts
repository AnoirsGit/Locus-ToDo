import { api } from '$shared/api/client'
import type { Task, TaskPeriod, TaskWithPeriod, TaskLevel, TaskStatus } from '../model/task.types'

type CreateTaskDto = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string    // ISO date — start of the period
  deadlineMonth?: number // year-tasks only
}

type UpdatePeriodDto = Partial<{
  status: TaskStatus
  title: string
  description: string
}>

export const tasksApi = {
  /** Get tasks with their current period for a given week/month/year */
  getByPeriod: (params: { periodType: TaskLevel; periodStart: string }) =>
    api.get<TaskWithPeriod[]>(`/tasks?${new URLSearchParams(params).toString()}`),

  /** Get all failed periods (backlog) */
  getBacklog: () => api.get<TaskWithPeriod[]>('/tasks?status=failed'),

  /** Get archived */
  getArchive: () => api.get<TaskWithPeriod[]>('/tasks?status=archived'),

  create: (dto: CreateTaskDto) => api.post<TaskWithPeriod>('/tasks', dto),

  /** Update the period status (done, overdue, failed) */
  updatePeriod: (periodId: string, dto: UpdatePeriodDto) =>
    api.patch<TaskPeriod>(`/task-periods/${periodId}`, dto),

  /** Replan: create a new period for the task in the next period */
  replan: (taskId: string, dto: { periodStart: string }) =>
    api.post<TaskWithPeriod>(`/tasks/${taskId}/replan`, dto),

  remove: (taskId: string) => api.delete<void>(`/tasks/${taskId}`),
}
