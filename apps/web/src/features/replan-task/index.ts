import { tasksApi, taskStore } from '$entities/task'

type ReplanInput = {
  taskId: string
  periodStart: string  // ISO date — start of the new period
}

export const replanTask = async ({ taskId, periodStart }: ReplanInput) => {
  const item = await tasksApi.replan(taskId, { periodStart })
  taskStore.upsert(item)
  return item
}
