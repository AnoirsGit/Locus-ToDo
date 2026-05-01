import type { Task, TaskView, GroupedTasks } from '@locus/shared'

type TasksState = {
  tasks: Task[]
  loading: boolean
  error: string | null
}

const state = $state<TasksState>({
  tasks: [],
  loading: false,
  error: null,
})

const getTasksForView = (view: TaskView): GroupedTasks => {
  const now = new Date().toISOString()

  const active = state.tasks.filter(
    (t) => t.status === 'todo' || t.status === 'done',
  )

  if (view === 'backlog') {
    return {
      primary: state.tasks.filter((t) => t.status === 'backlog'),
      week: [],
      month: [],
      year: [],
    }
  }

  if (view === 'archive') {
    return {
      primary: state.tasks.filter((t) => t.status === 'archived'),
      week: [],
      month: [],
      year: [],
    }
  }

  const primary = active.filter((t) => t.level === levelForView(view))
  const week = view !== 'week' ? active.filter((t) => t.level === 'week') : []
  const month = view !== 'month' ? active.filter((t) => t.level === 'month') : []
  const year = view !== 'year' ? active.filter((t) => t.level === 'year') : []

  return { primary, week, month, year }
}

const levelForView = (view: TaskView) => {
  if (view === 'day' || view === 'week') return 'week'
  if (view === 'month') return 'month'
  return 'year'
}

export const tasksStore = {
  get tasks() { return state.tasks },
  get loading() { return state.loading },
  get error() { return state.error },
  getTasksForView,
}
