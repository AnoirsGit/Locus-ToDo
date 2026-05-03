import { tasksApi, taskStore } from '$entities/task'
import type { TaskLevel, RecurringConfig } from '$entities/task'

type CreateTaskInput = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string
  deadlineMonth?: number
  targetDate?: string
  recurringConfig?: Omit<RecurringConfig, 'id' | 'taskId' | 'createdAt'>
}

export const createTask = async (input: CreateTaskInput) => {
  // Optimistic insert with local IDs
  const now = new Date().toISOString()
  const taskId = crypto.randomUUID()
  const periodId = crypto.randomUUID()

  const optimistic = {
    id: taskId,
    userId: 'u1',
    title: input.title,
    description: input.description,
    level: input.level,
    recurringConfig: input.recurringConfig
      ? { id: crypto.randomUUID(), taskId, createdAt: now, ...input.recurringConfig }
      : undefined,
    createdAt: now,
    updatedAt: now,
    period: {
      id: periodId,
      taskId,
      userId: 'u1',
      periodType: input.level,
      periodStart: input.periodStart,
      periodEnd: input.periodStart, // placeholder, API returns real value
      status: 'todo' as const,
      targetDate: input.targetDate,
      deadlineMonth: input.deadlineMonth,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    },
  }

  taskStore.upsert(optimistic)

  try {
    const item = await tasksApi.create({
      title: input.title,
      description: input.description,
      level: input.level,
      periodStart: input.periodStart,
      deadlineMonth: input.deadlineMonth,
    })
    taskStore.upsert(item)
    return item
  } catch {
    return optimistic
  }
}

export { default as CreateTaskForm } from './ui/CreateTaskForm.svelte'
