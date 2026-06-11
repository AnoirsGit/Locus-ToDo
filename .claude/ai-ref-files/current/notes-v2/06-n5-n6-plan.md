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

### Phase A — Notes tags UI (N5.1) — no schema ✅ DONE
- [x] Backend: bulk `GET /api/tags/note-assignments` (mirrors task-assignments) — repo+usecase+route
- [x] Web `tagStore` note state: `loadNoteAssignments`, `getTagsForNote`, `setNoteTags`, note filter set + `noteMatchesFilter`
- [x] Web: tag chips on note rows (`TagChip`); `TagPicker` "Tags ▸" section in `NoteRowMenu`
- [x] Web: `NoteTagFilterBar` above the tree; `pruneByTag` keeps matching branches + ancestors, force-expands
- [x] Mobile: note-tag state in `tag_store`; `NoteTagChips` + `showNoteTagPicker` (`note_tags.dart`); `NoteRow`→Consumer; picker tile in actions sheet; filter bar + prune in `notes_page`
- [x] `tsc` (web+api) + `flutter analyze` clean

### Phase B — Search (N5.2) ✅ DONE
- [x] **Client-side** search over the already-loaded tree (the API returns all notes, so
  no endpoint needed — instant, offline-friendly). Deviation from plan noted with rationale.
- [x] Web: `noteStore.search(q)` (content `includes`, breadcrumb path); search field + results list above the tree; click → zoom
- [x] Mobile: `NotesNotifier.search(q)`; search `TextField` + results `ListView` in `notes_page`; tap → zoom
- [x] `tsc` (web) + `flutter analyze` clean

### Phase C — Checkbox / todo nodes (N6.1) — migration 006 ✅ DONE (⚠️ migration not yet applied to a live DB)
- [x] `006_notes_todo.sql` written (user-approved): `ADD COLUMN done BOOLEAN NOT NULL DEFAULT false`
- [x] API: `done` in `NoteRow`/RETURNING/update; `'todo'` in `nodeTypeSchema`; `done` in update zod + usecase patch
- [x] Web types/DTO: `'todo'` + `done`; `dtoToNode`/`update` map `done`; store persists `done`
- [x] Web: `todo` renders as checkbox + strikethrough label; "Turn into → To-do" in menu
- [x] Mobile: `NoteNodeType.todo` + `done` on `NoteNode`/DTO/copyWith; `toggleDone`; checkbox + strikethrough; "Turn into → To-do" in sheet; board label `☑`
- [x] `tsc` (web+api) + `flutter analyze` clean
- [ ] **Apply migration on live DB** (pending stack up) — `done` column must exist before `done`/`todo` round-trips work

### Phase D — Undo delete (N6.3) ✅ DONE
- [x] Web: `toastStore.withAction` (new) + `<Toasts>` action button; `captureForUndo`/`restoreEntries`
  re-create parent-first with original ids. `remove(id, {undo})` (menu delete) + `deleteSelected`
  (disjoint roots). Keyboard backspace-merge intentionally skips the toast.
- [x] Mobile: `removeNoteWithUndo`/`deleteMultipleWithUndo` return an undo closure; `showNoteUndoSnack`
  shows a SnackBar with Undo; wired in actions sheet (leaf + subtree confirm) and selection bar.
- [x] `tsc` (web) + `flutter analyze` clean

### Phase E — Export Markdown / OPML (N6.4) ✅ DONE
- [x] **Client-side** generation from the loaded tree (`note-export.ts`: `toMarkdown`, `toOpml`,
  `downloadText`) — no endpoint needed, same rationale as search. Deviation noted.
- [x] Markdown: headings `#/##`, `- [ ]/[x]` todos, `[text](url)` links, `![]()` images, indented bullets.
  OPML: nested `<outline text _type _url _done>`.
- [x] Web: "Export ▾" menu in the notes header → downloads `.md` / `.opml` via Blob
- [x] `tsc` (web) clean

### Phase F — Drag-and-drop reorder/reparent, web (N5.3) ✅ DONE (⚠️ needs browser QA)
- [x] Native HTML5 DnD: `⠿` drag handle (draggable) on each row; row is the drop target
- [x] `noteStore.dragId`/`setDrag` + `dropNode(dragId, targetId, before|after|child)` — top/bottom 25% = sibling, middle = child; renumbers siblings + sets parentId via PATCH; blocks self-descendant drops
- [x] Drop indicator: inset top/bottom line (sibling) or highlight+ring (child)
- [x] Move up/down kept as fallback; `tsc` (web) clean
- [ ] **Browser QA** — DnD interaction can't be verified statically

### Phase G — Move to… dialog (N5.4) ✅ DONE
- [x] Web: `noteStore.moveCandidates(excludeId)` (flattened, excludes own subtree) + `moveToParent(id, parentId|null)`;
  "Move to ▸" section in `NoteRowMenu` with a find-filter + Root option
- [x] Mobile: same notifier methods; `_MoveToSheet` (search + list + Root) from the actions sheet
- [x] `tsc` (web) + `flutter analyze` clean

### Phase H — Offline notes, mobile (N6.2) ✅ DONE (⚠️ device QA pending)
- [x] Drift `Notes` + `NotesOutbox` tables + queries in `app_database.dart`; schemaVersion 2 + onUpgrade migration; `build_runner` regenerated `app_database.g.dart`
- [x] `LocalNoteRepository` (cache tree, rebuild tree, upsert/applyUpdate/delete, outbox enqueue) behind a `NoteLocalStore` interface (so tests inject in-memory)
- [x] `OfflineNotesApi` (same surface as `NotesApi`): network-first with local cache + outbox fallback; `NotesApi.createRaw`/`patchRaw` for replay
- [x] `NotesSyncWorker.flush()` replays the outbox with backoff; `NotesNotifier` reads `offlineNotesApiProvider` and flushes on build — internals unchanged, last-write-wins per field
- [x] `flutter analyze` clean (0 errors); regression test `notes_delete_test` updated for the offline path and **passes**
- [ ] **Device QA** — airplane-mode create/edit/delete survive restart + sync on reconnect (needs a device + live API)

## Status: A B C D E F G H all implemented. Remaining = live verification only.
- Apply migration 006 on a live DB; bring up the stack.
- Live QA: tags/search/checkbox/undo/move-to (functional), drag-drop (browser), offline (device).
- Note: mobile `app_database.g.dart` is gitignored — run `flutter pub run build_runner build` after pull.

## Verification (all phases)
Static: web `tsc`, `flutter analyze`, API `tsc`/build. Live QA needs Docker stack up
(Postgres + API) — run migrations, then the per-phase manual checks + web↔mobile round trip.
</content>
</invoke>
