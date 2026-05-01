// ─── Enums ────────────────────────────────────────────────────────────────────

export type TaskLevel = 'week' | 'month' | 'year'

export type TaskStatus =
  | 'todo'
  | 'done'
  | 'archived'
  | 'failed'
  | 'backlog'

// ─── Core Task ────────────────────────────────────────────────────────────────

export type Task = {
  id: string
  title: string
  description?: string
  level: TaskLevel
  status: TaskStatus

  /** For year-level tasks: which month is the deadline (1–12) */
  deadlineMonth?: number

  /** Timestamp when the task was marked done — starts the archive delay */
  doneAt?: string

  /** Minutes to wait in Done state before auto-archiving (default: 120) */
  archiveDelayMinutes: number

  /** Deadline ISO date — set automatically based on level + creation date */
  deadline: string

  /** Whether this is a recurring task */
  isRecurring: boolean
  recurringConfig?: RecurringConfig

  /** Tags from backlog flow */
  failedAt?: string
  archivedAt?: string

  createdAt: string
  updatedAt: string
  userId: string
}

// ─── Recurring ────────────────────────────────────────────────────────────────

export type RecurringConfig = {
  level: TaskLevel
  /** For week-level: 0 (Sun) – 6 (Sat) */
  dayOfWeek?: number
  /** For month-level: 1–31 */
  dayOfMonth?: number
}

// ─── View helpers ─────────────────────────────────────────────────────────────

export type TaskView = 'day' | 'week' | 'month' | 'year' | 'backlog' | 'archive'

export type GroupedTasks = {
  primary: Task[]
  week: Task[]
  month: Task[]
  year: Task[]
}
