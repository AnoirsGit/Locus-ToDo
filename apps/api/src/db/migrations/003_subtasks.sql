-- ─────────────────────────────────────────────────────────────────────────────
-- Subtasks: self-referencing parent_task_id on tasks.
-- ON DELETE RESTRICT — deleting a parent with subtasks requires deleting them first.
-- Level constraint (subtask.level ≤ parent.level) enforced at app layer.
-- Recurring blocked for subtasks (enforced at app layer).
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE tasks
  ADD COLUMN parent_task_id UUID REFERENCES tasks(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_tasks_parent_task_id ON tasks(parent_task_id);
