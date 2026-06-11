-- ─────────────────────────────────────────────────────────────────────────────
-- Checkbox notes: a 'todo' node_type renders as a checkbox; `done` holds state.
-- node_type column is already VARCHAR(20) — no type change, just a new value.
-- Additive, no backfill: existing rows default done=false and keep their type.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE notes
  ADD COLUMN IF NOT EXISTS done BOOLEAN NOT NULL DEFAULT false;
