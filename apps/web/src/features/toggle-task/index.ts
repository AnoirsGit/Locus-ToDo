import { tasksApi, taskStore } from '$entities/task'

export const toggleTask = async (periodId: string, currentStatus: 'todo' | 'done') => {
  const newStatus = currentStatus === 'todo' ? 'done' : 'todo'
  const period = await tasksApi.updatePeriod(periodId, { status: newStatus })
  taskStore.updatePeriod(periodId, period)
  return period
}
