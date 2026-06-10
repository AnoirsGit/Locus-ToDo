# 05 — Notes v2 roadmap (work top-to-bottom)

> Each phase is a separate branch + PR. No DB/schema changes anywhere in phases 1–4.
> Phase 5+ items need user discussion first.

## Phase N1 — Delete fixes (bug, highest priority) — `fix/notes-delete`
Spec: `01-delete-bug.md`
- [x] Mobile: `ValueKey(node.id)` on all `_NoteRow`s; `_commit` guard; `didUpdateWidget` re-sync
- [x] Web: Delete/Backspace key deletes selected nodes (not just text) — requires the row to be in the selection AND (multi-select OR full text selected), so plain click-to-edit keeps normal text editing
- [x] Web + mobile: cancel pending content debounce for node + descendants on delete
- [x] Web: await in-flight create before delete (ghost-note race) — `pendingCreates` map in note store
- [ ] Subtree delete confirm ("Delete note and N nested notes?") — **deferred to N3** (lands with the three-dots menu)
- [ ] Run the verification checklist in `01-delete-bug.md` — `pnpm typecheck` + `flutter analyze` pass; Cause A proven by regression widget test `apps/mobile/test/notes_delete_test.dart` (fails on pre-fix code, passes with fix); web manual UI checks still pending

## Phase N2 — Note pages routing — `feat/notes-routes`
Spec: `02-note-pages-routing.md`
- [ ] Web: `notes/[id]/+page.svelte` + shared `NotePage` widget; zoom/breadcrumbs via `goto`; back button; deep-link guard
- [ ] Mobile: `/notes/:id` GoRoute (inside ShellRoute, `startsWith` tab matching); `context.push` zoom; AppBar back; rootId out of provider into route param
- [ ] Verify: reload on a zoomed page restores it; system back walks up; stale id redirects

## Phase N3 — Three-dots actions menu — `feat/notes-actions-menu`
Spec: `03-actions-menu.md`
- [ ] Web: `NoteRowMenu.svelte` popover (hover/focus trigger, right-click); remove type dropdown, inline trash, Set-URL toggles
- [ ] Mobile: bottom sheet; remove per-row +/trash icons
- [ ] Store methods both platforms: `addChild` (web), `moveUp/moveDown`, descendant count; `duplicate` if time allows
- [ ] Delete confirm wired here if not done in N1

## Phase N4 — Mobile parity — `feat/notes-mobile-parity`
Spec: `04-mobile-parity.md`
- [ ] File split per FSD (entities/note, pages/notes/widgets)
- [ ] DTO + model carry `nodeType`/`url`; per-type rendering (h1/h2/bullet/link/image)
- [ ] Indent/outdent/addAfter/move ported to `NotesNotifier`; Enter = add sibling
- [ ] Board view + Outline/Board toggle
- [ ] Notes strings localized (ru/en)

## Phase N5 — Competitive quick wins (each needs a go-ahead)
- [ ] **Note tags UI** — backend + `TagPicker` already exist; add tag chips/picker to note rows (web + mobile), filter notes by tag
- [ ] **Search** — `GET /api/notes/search?q=` (`ILIKE` over content) + search field above the tree; show matches with their breadcrumb paths
- [ ] **Drag-and-drop reorder/reparent (web)** — replaces move up/down for mouse users; `PATCH parentId/sortOrder` already supports it
- [ ] **Move to… dialog** — fuzzy search target node, reparent (Dynalist-style)

## Phase N6 — Ideas needing schema discussion ⚠️ (DB rule: explicit user OK required)
- **Checkbox / completable nodes** — either new `node_type = 'todo'` value (VARCHAR already permits it — still confirm) or a `done BOOLEAN`/`done_at` column; fits the discipline product (e.g. checklists linked to tasks)
- **Offline notes on mobile** — Drift table + outbox like tasks; conflict story needed (last-write-wins per field?)
- **Undo for deletes** — client-side subtree resurrection vs server-side soft delete (`deleted_at`)
- **Export** (Markdown/OPML) — read-only endpoint, no schema change, but low priority

## Out of scope (noted from competitor analysis, intentionally skipped)
Mirrors / block references, backlinks, share links, templates, comments, file uploads.
