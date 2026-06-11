# 06 — N5 + N6 implementation plan (power features)

> User authorized N5 and N6. For N6 schema, user said "верю в твои решения".
> DB is DRAFT — migration SQL is shown before it runs even with that go-ahead.
> Branch: `feat/notes-n5-n6` off `feat/notes-mobile-parity-2`. One commit per phase.

## My N6 decisions (schema)

- **Checkbox nodes** → migration **006**: add `done BOOLEAN NOT NULL DEFAULT false`
  to `notes`, and use a new `node_type = 'todo'` (the `VARCHAR(20)` column already
  permits it — no column-type change). A `todo` node renders a checkbox + label;
  `done` holds the checked state; other types ignore `done`. Additive, no data backfill.
- **Undo delete** → **client-side**, no schema. We already hold the deleted subtree
  in memory; "Undo" re-creates it parent-first with the original ids. Rejected
  server-side `deleted_at` soft-delete (cascade + scheduler complexity, not worth it).
- **Export** → read-only `GET /api/notes/export?format=md|opml`, no schema.
- **Offline notes** → mirror tasks: Drift table + outbox + `LocalNoteRepository` +
  reuse `SyncWorker`. Conflict = last-write-wins per field (same as tasks). Heaviest;
  scheduled last.

## Phases (value-dense + low-risk first, schema isolated, heaviest last)

### Phase A — Notes tags UI (N5.1) — no schema
- [ ] Web `noteTagStore` (`entities/tag` or note-scoped): load `GET /api/tags/notes/:id` lazily, `setNoteTags` on change, note-tag filter set
- [ ] Web: tag chips on note rows (reuse `TagChip`); `TagPicker` entry in `NoteRowMenu`
- [ ] Web: `TagFilterBar` (note variant) above the tree; filter visible nodes by tag (keep ancestors of matches)
- [ ] Mobile: note-tag map in `NotesNotifier` or a small provider; chips in `NoteRow`; picker tile in actions sheet; filter control in `notes_page`
- [ ] `pnpm --filter web typecheck` + `flutter analyze` clean

### Phase B — Search (N5.2) — tiny backend
- [ ] API: `GET /api/notes/search?q=` → `ILIKE` over content, return rows + breadcrumb path; usecase + repo method + route + zod
- [ ] Web: search field above tree; results list with breadcrumb paths; click → zoom/focus
- [ ] Mobile: search field in `notes_page`; same results UX
- [ ] Typecheck + analyze clean; backend builds

### Phase C — Checkbox / todo nodes (N6.1) — migration 006 ⚠️ show SQL first
- [ ] Write `006_notes_todo.sql`; **present SQL, get explicit OK, then run**
- [ ] API: add `done` to `NoteRow`/RETURNING/create/update; add `'todo'` to `nodeTypeSchema`
- [ ] Shared/web types: `'todo'` node type + `done` field; API DTO mapping
- [ ] Web: render `todo` as checkbox + label; toggle persists `done`; "Turn into → Todo" in menu
- [ ] Mobile: `NoteNodeType.todo`, `done` on `NoteNode`/DTO/copyWith; checkbox render + toggle; "Turn into → Todo" in sheet
- [ ] Typecheck + analyze clean

### Phase D — Undo delete (N6.3) — no schema
- [ ] Web: capture deleted subtree; toast with "Undo" → re-create parent-first (original ids); applies to single + multi delete
- [ ] Mobile: same via SnackBar action
- [ ] Typecheck + analyze clean

### Phase E — Export Markdown / OPML (N6.4) — read-only endpoint
- [ ] API: `GET /api/notes/export?format=md|opml` walks tree → text; route + usecase
- [ ] Web: "Export" action (download .md/.opml) in notes page header
- [ ] Typecheck clean; backend builds

### Phase F — Drag-and-drop reorder/reparent, web (N5.3) — no schema
- [ ] Web: pointer-based DnD on `NoteRow` (drag handle); drop = reparent/reorder via `PATCH parentId/sortOrder`; visual drop indicator
- [ ] Keep move up/down as fallback
- [ ] Typecheck clean

### Phase G — Move to… dialog (N5.4) — no schema
- [ ] Web: dialog with fuzzy node search; pick target → reparent (`indent`-style PATCH); exclude self/descendants
- [ ] Mobile: same as a full-screen/sheet picker
- [ ] Typecheck + analyze clean

### Phase H — Offline notes, mobile (N6.2) — heaviest, last
- [ ] Drift `notes` table + DAO in `app_database.dart`
- [ ] `LocalNoteRepository` + outbox entries; wire into `NotesNotifier` (read-local-first, enqueue mutations)
- [ ] Reuse `SyncWorker` to flush note outbox; last-write-wins per field
- [ ] `flutter analyze` clean; offline create/edit/delete survive restart + sync

## Verification (all phases)
Static: web `tsc`, `flutter analyze`, API `tsc`/build. Live QA needs Docker stack up
(Postgres + API) — run migrations, then the per-phase manual checks + web↔mobile round trip.
</content>
</invoke>
