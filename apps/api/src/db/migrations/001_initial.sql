-- ─────────────────────────────────────────────────────────────────────────────
-- Users
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  name          TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url    TEXT,
  timezone      TEXT NOT NULL DEFAULT 'UTC',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- User settings (1:1, created automatically on register)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_settings (
  user_id                 UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notification_offset_min SMALLINT NOT NULL DEFAULT 15,
  notify_overdue          BOOLEAN  NOT NULL DEFAULT true,
  notify_daily_summary    BOOLEAN  NOT NULL DEFAULT false,
  daily_summary_time      TIME     NOT NULL DEFAULT '08:00'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- User push tokens (multiple devices per user)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_push_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      TEXT NOT NULL UNIQUE,
  platform   TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Tasks (definition — level, title, etc.)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tasks (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT,
  level          TEXT NOT NULL CHECK (level IN ('day', 'week', 'month', 'year')),
  scheduled_time TIME,  -- HH:MM, day-tasks only; used for sorting + notifications
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- Recurring configs (presence = recurring; 1:1 with tasks)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recurring_configs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id       UUID NOT NULL UNIQUE REFERENCES tasks(id) ON DELETE CASCADE,
  day_of_week   SMALLINT CHECK (day_of_week  BETWEEN 0 AND 6),   -- week tasks only
  day_of_month  SMALLINT CHECK (day_of_month BETWEEN 1 AND 31),  -- month tasks only
  month_of_year SMALLINT CHECK (month_of_year BETWEEN 1 AND 12), -- month-yearly tasks
  is_active     BOOLEAN NOT NULL DEFAULT true,
  allow_overdue BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recurring_configs_task ON recurring_configs(task_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- Task periods (one row = one appearance of a task in a time period)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS task_periods (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id      UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id),

  period_type  TEXT NOT NULL CHECK (period_type IN ('day', 'week', 'month', 'year')),
  period_start DATE NOT NULL,
  period_end   DATE NOT NULL,

  status       TEXT NOT NULL DEFAULT 'todo'
               CHECK (status IN ('todo', 'done', 'overdue', 'backlog', 'archived')),

  target_date    DATE,
  deadline_month SMALLINT CHECK (deadline_month BETWEEN 1 AND 12),

  sort_order   INTEGER NOT NULL DEFAULT 0,

  done_at      TIMESTAMPTZ,
  backlog_at   TIMESTAMPTZ,
  archived_at  TIMESTAMPTZ,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One active period per task per start date (allows multiple archived)
CREATE UNIQUE INDEX IF NOT EXISTS idx_task_periods_active_unique
  ON task_periods(task_id, period_start)
  WHERE status != 'archived';

CREATE INDEX IF NOT EXISTS idx_task_periods_user_period
  ON task_periods(user_id, period_type, period_start);

CREATE INDEX IF NOT EXISTS idx_task_periods_task_id
  ON task_periods(task_id);

CREATE INDEX IF NOT EXISTS idx_task_periods_status
  ON task_periods(status)
  WHERE status IN ('todo', 'done', 'overdue', 'backlog');

CREATE INDEX IF NOT EXISTS idx_task_periods_target_date
  ON task_periods(target_date)
  WHERE target_date IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- Task templates (user_id = NULL → system template)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS task_templates (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  items       JSONB NOT NULL DEFAULT '[]',
  is_public   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Sent notifications (deduplication)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sent_notifications (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_period_id     UUID NOT NULL REFERENCES task_periods(id) ON DELETE CASCADE,
  notification_type  TEXT NOT NULL
                     CHECK (notification_type IN ('task_reminder', 'task_overdue', 'daily_summary')),
  sent_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (task_period_id, notification_type)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- updated_at trigger
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tasks_updated_at ON tasks;
CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS task_periods_updated_at ON task_periods;
CREATE TRIGGER task_periods_updated_at
  BEFORE UPDATE ON task_periods
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
