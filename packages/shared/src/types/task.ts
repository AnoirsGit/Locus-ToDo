export type TaskLevel = 'day' | 'week' | 'month' | 'year'

export type TaskStatus = 'todo' | 'done' | 'overdue' | 'backlog' | 'archived'

// --- Task -----------------------------------------------------------------------

export type Task = {
  id: string
  userId: string
  title: string
  description?: string
  level: TaskLevel
  recurringConfig?: RecurringConfig
  createdAt: string
  updatedAt: string
}

// --- Recurring Config -----------------------------------------------------------

export type RecurringConfig = {
  id: string
  taskId: string
  /** week-level: 0 (Sun) - 6 (Sat). Null = start of week */
  dayOfWeek?: number
  /** month-level: 1-31. Null = 1st */
  dayOfMonth?: number
  isActive: boolean
  createdAt: string
}

// --- Task Period ----------------------------------------------------------------

export type TaskPeriod = {
  id: string
  taskId: string
  userId: string

  periodType: TaskLevel
  periodStart: string // ISO date -- Mon / Jan 1 / 1st of month
  periodEnd: string   // ISO date -- Sun / Dec 31 / last of month

  status: TaskStatus

  /** week-tasks only: planned day within the week */
  targetDate?: string
  /** year-tasks only: deadline narrows to a specific month (1-12) */
  deadlineMonth?: number

  sortOrder: number

  doneAt?: string
  backlogAt?: string
  archivedAt?: string

  createdAt: string
  updatedAt: string
}

// --- View helpers ---------------------------------------------------------------

export type TaskView = 'day' | 'week' | 'month' | 'year' | 'backlog' | 'archive'

/** Task + its current period -- what the UI works with */
export type TaskWithPeriod = Task & { period: TaskPeriod }

export type GroupedTasks = {
  primary: TaskWithPeriod[]
  week: TaskWithPeriod[]
  month: TaskWithPeriod[]
  year: TaskWithPeriod[]
}
