import { tasksApi, taskStore } from '$entities/task'
import type { TaskLevel } from '$entities/task'

type CreateTaskInput = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string    // ISO date — start of the target period
  deadlineMonth?: number // year-tasks only
}

export const createTask = async (input: CreateTaskInput) => {
  const item = await tasksApi.create(input)
  taskStore.upsert(item)
  return item
}
