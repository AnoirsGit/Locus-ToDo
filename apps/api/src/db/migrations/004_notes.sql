-- ─────────────────────────────────────────────────────────────────────────────
-- Notes: self-referencing tree structure.
-- parent_id NULL = root node.
-- sort_order used to maintain sibling order.
-- node_type: text | heading1 | heading2 | bullet | image | link
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id   UUID REFERENCES notes(id) ON DELETE CASCADE,
  node_type   VARCHAR(20) NOT NULL DEFAULT 'bullet',
  content     TEXT NOT NULL DEFAULT '',
  url         TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  collapsed   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notes_user_id    ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_parent_id  ON notes(parent_id);
CREATE INDEX IF NOT EXISTS idx_notes_sort_order ON notes(user_id, parent_id, sort_order);
