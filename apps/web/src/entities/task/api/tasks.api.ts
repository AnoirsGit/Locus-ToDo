import { api } from '$shared/api/client'
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
}>

type UpdatePeriodDto = Partial<{
  status: TaskStatus
}>

export const tasksApi = {
  /** Get tasks with their current period for a given week/month/year */
  getByPeriod: (params: { periodType: TaskLevel; periodStart: string }) =>
    api.get<TaskWithPeriod[]>(`/tasks?${new URLSearchParams(params).toString()}`),

  /** Get all backlog periods */
  getBacklog: () => api.get<TaskWithPeriod[]>('/tasks?status=backlog'),

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

  /** Get subtasks for a task */
  getSubtasks: (taskId: string) => api.get<TaskWithPeriod[]>(`/tasks/${taskId}/subtasks`),
}
