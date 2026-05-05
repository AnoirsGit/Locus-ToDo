import { api } from '$shared/api/client'
import type { TaskPeriod, TaskWithPeriod, TaskLevel, TaskStatus } from '../model/task.types'

type CreateTaskDto = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string    // ISO date — start of the period
  deadlineMonth?: number // year-tasks only
}

type UpdateTaskDto = Partial<{
  title: string
  description: string | null
}>

type UpdatePeriodDto = Partial<{
  status: TaskStatus
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

  /** Update task metadata (title, description) */
  update: (taskId: string, dto: UpdateTaskDto) =>
    api.patch<TaskWithPeriod>(`/tasks/${taskId}`, dto),

  /** Toggle period status (done ↔ todo) */
  updatePeriod: (periodId: string, dto: UpdatePeriodDto) =>
    api.patch<TaskPeriod>(`/task-periods/${periodId}`, dto),

  /** Replan: create a new period for the task in the next period */
  replan: (taskId: string, dto: { periodStart: string }) =>
    api.post<TaskWithPeriod>(`/tasks/${taskId}/replan`, dto),

  remove: (taskId: string) => api.delete<void>(`/tasks/${taskId}`),
}
