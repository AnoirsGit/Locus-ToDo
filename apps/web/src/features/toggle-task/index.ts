import { tasksApi, taskStore } from '$entities/task'

export const toggleTask = async (periodId: string) => {
  const task = taskStore.items.find((t) => t.period.id === periodId)
  if (!task) return

  const { status } = task.period
  const newStatus = status === 'done' ? 'todo' : 'done'
  const doneAt = newStatus === 'done' ? new Date().toISOString() : undefined

  // Optimistic update — works in mock mode even without API
  taskStore.updatePeriod(periodId, { status: newStatus, doneAt })

  try {
    const period = await tasksApi.updatePeriod(periodId, { status: newStatus })
    // Only patch status + doneAt — the full period object from RETURNING * may have
    // Date objects for date columns which would break string comparisons in getForDate.
    taskStore.updatePeriod(periodId, { status: period.status, doneAt: period.doneAt ?? undefined })
  } catch {
    // API not running — keep optimistic update
  }
}
