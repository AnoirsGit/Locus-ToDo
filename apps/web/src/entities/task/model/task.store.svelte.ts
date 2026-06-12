import type { TaskWithPeriod, GroupedTasks, TaskView, TaskPeriod } from './task.types'

type State = {
  items: TaskWithPeriod[]
  loading: boolean
  error: string | null
}

const state = $state<State>({ items: [], loading: false, error: null })

const levelForView = (view: TaskView): TaskWithPeriod['level'] => {
  if (view === 'day') return 'day'
  if (view === 'month') return 'month'
  if (view === 'year') return 'year'
  return 'week'
}

const getForView = (view: TaskView): GroupedTasks => {
  if (view === 'backlog') {
    return {
      primary: state.items.filter((t) => t.period.status === 'backlog'),
      week: [], month: [], year: [],
    }
  }

  if (view === 'archive') {
    return {
      primary: state.items.filter((t) => t.period.status === 'archived'),
      week: [], month: [], year: [],
    }
  }

  const active = state.items.filter(
    (t) => t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done',
  )
  const level = levelForView(view)

  return {
    primary: active.filter((t) => t.level === level),
    week:  level !== 'week'  ? active.filter((t) => t.level === 'week')  : [],
    month: level !== 'month' ? active.filter((t) => t.level === 'month') : [],
    year:  level !== 'year'  ? active.filter((t) => t.level === 'year')  : [],
  }
}

const setItems = (items: TaskWithPeriod[]) => { state.items = items }
const setLoading = (v: boolean) => { state.loading = v }
const setError = (e: string | null) => { state.error = e }

const upsert = (item: TaskWithPeriod) => {
  const idx = state.items.findIndex((t) => t.period.id === item.period.id)
  if (idx === -1) state.items = [...state.items, item]
  else state.items = state.items.with(idx, item)
}

const updatePeriod = (periodId: string, patch: Partial<TaskPeriod>) => {
  state.items = state.items.map((t) =>
    t.period.id === periodId ? { ...t, period: { ...t.period, ...patch } } : t,
  )
}

const remove = (periodId: string) => {
  state.items = state.items.filter((t) => t.period.id !== periodId)
}

/** Drop every period entry of a task (hard delete destroys all its periods). */
const removeByTaskId = (taskId: string) => {
  state.items = state.items.filter((t) => t.id !== taskId)
}

const getForDate = (date: string): TaskWithPeriod[] =>
  state.items.filter(
    (t) =>
      (t.period.status === 'todo' || t.period.status === 'overdue' || t.period.status === 'done') &&
      (t.period.targetDate === date || (t.level === 'day' && t.period.periodStart === date)),
  )

export const taskStore = {
  get items() { return state.items },
  get loading() { return state.loading },
  get error() { return state.error },
  getForView,
  getForDate,
  setItems,
  setLoading,
  setError,
  upsert,
  updatePeriod,
  remove,
  removeByTaskId,
}
