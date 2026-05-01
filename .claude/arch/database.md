# arch/database.md

> Load when: DB schema, migrations, queries, indexes, table relations.

## Status: DRAFT ⚠️ — not confirmed

---

## Tables

### `users`
```
id            UUID PK  DEFAULT gen_random_uuid()
email         TEXT     UNIQUE NOT NULL
name          TEXT     NOT NULL
password_hash TEXT     NOT NULL
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
```

### `tasks`
```
id                    UUID PK
user_id               UUID FK → users.id  ON DELETE CASCADE
title                 TEXT NOT NULL (max 500)
description           TEXT
level                 TEXT CHECK ('week' | 'month' | 'year')
status                TEXT DEFAULT 'todo'
                        CHECK ('todo' | 'done' | 'archived' | 'failed' | 'backlog')
deadline              TIMESTAMPTZ NOT NULL
deadline_month        INT  CHECK (1–12)    -- year-tasks with a month-level deadline
done_at               TIMESTAMPTZ          -- set when status → done
archive_delay_minutes INT  DEFAULT 120     -- delay before auto-archive (minutes)
failed_at             TIMESTAMPTZ          -- set on auto-fail
archived_at           TIMESTAMPTZ
is_recurring          BOOLEAN DEFAULT false
recurring_config      JSONB                -- { level, dayOfWeek?, dayOfMonth? }
created_at            TIMESTAMPTZ DEFAULT now()
updated_at            TIMESTAMPTZ DEFAULT now()  -- maintained by update_updated_at trigger
```

### `recurring_templates`
```
id                    UUID PK
user_id               UUID FK → users.id  ON DELETE CASCADE
title                 TEXT NOT NULL
description           TEXT
level                 TEXT CHECK ('week' | 'month' | 'year')
archive_delay_minutes INT  DEFAULT 120
recurring_config      JSONB NOT NULL
is_active             BOOLEAN DEFAULT true
created_at            TIMESTAMPTZ DEFAULT now()
```

---

## Relations

```
users ──< tasks                (1:N, ON DELETE CASCADE)
users ──< recurring_templates  (1:N, ON DELETE CASCADE)
```

---

## Indexes (proposed)

```sql
idx_tasks_user_id   ON tasks(user_id)
idx_tasks_status    ON tasks(status)
idx_tasks_deadline  ON tasks(deadline)
```

**To discuss:**
- Composite `(status, deadline)` — for scheduler Job B (`status='todo' AND deadline < now()`)
- Composite `(status, done_at)` — for scheduler Job A (`status='done' AND done_at + interval <= now()`)

---

## Scheduler SQL (internal, not HTTP)

```sql
-- Job A: auto-archive
UPDATE tasks
SET status = 'archived', archived_at = now()
WHERE status = 'done'
  AND done_at + (archive_delay_minutes * INTERVAL '1 minute') <= now();

-- Job B: auto-fail
UPDATE tasks
SET status = 'backlog', failed_at = now()
WHERE status = 'todo'
  AND deadline < now();
```

---

## Open Questions

- [ ] Soft-delete vs hard-delete for tasks?
- [ ] Partition `tasks` by `user_id` at scale?
- [ ] Composite indexes for the scheduler — confirm
- [ ] Separate `sessions` table or refresh tokens in Redis? → see `backend.md`
