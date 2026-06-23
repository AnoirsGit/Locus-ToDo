import { tasksApi, taskStore } from '$entities/task'
import { userStore } from '$entities/user'
import type { TaskLevel, RecurringConfig } from '$entities/task'

type CreateTaskInput = {
  title: string
  description?: string
  level: TaskLevel
  periodStart: string
  deadlineMonth?: number
  targetDate?: string
  scheduledTime?: string
  recurringConfig?: Omit<RecurringConfig, 'id' | 'taskId' | 'createdAt'>
}

export const createTask = async (input: CreateTaskInput) => {
  // Optimistic insert with local IDs
  const now = new Date().toISOString()
  const taskId = crypto.randomUUID()
  const periodId = crypto.randomUUID()

  const uid = userStore.user?.id ?? ''

  const optimistic = {
    id: taskId,
    userId: uid,
    title: input.title,
    description: input.description,
    level: input.level,
    scheduledTime: input.scheduledTime,
    recurringConfig: input.recurringConfig
      ? { id: crypto.randomUUID(), taskId, createdAt: now, ...input.recurringConfig }
      : undefined,
    createdAt: now,
    updatedAt: now,
    period: {
      id: periodId,
      taskId,
      userId: uid,
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
      targetDate: input.targetDate,
      scheduledTime: input.scheduledTime,
      recurringConfig: input.recurringConfig,
    })
    taskStore.remove(periodId)
    taskStore.upsert(item)
    return item
  } catch {
    return optimistic
  }
}

export { default as CreateTaskForm } from './ui/CreateTaskForm.svelte'
