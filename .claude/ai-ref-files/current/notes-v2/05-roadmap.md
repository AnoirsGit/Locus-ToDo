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

## Phase N2 — Note pages routing — `feat/notes-routes` ✅ implemented (commit dc19091)
Spec: `02-note-pages-routing.md`
- [x] Web: `notes/[id]/+page.svelte` + shared `NotePage` widget; zoom/breadcrumbs via `goto`; back button; deep-link guard
- [x] Mobile: `/notes/:id` GoRoute (inside ShellRoute, `startsWith` tab matching); `context.push` zoom; AppBar back; rootId out of provider into route param (selection is now per-page local state, `NotesUiState` provider removed)
- [ ] Verify: reload on a zoomed page restores it; system back walks up; stale id redirects — **manual check pending**

## Phase N3 — Three-dots actions menu — `feat/notes-actions-menu` ✅ implemented (commit 9be4bc0)
Spec: `03-actions-menu.md`
- [x] Web: `NoteRowMenu.svelte` popover (hover trigger + right-click); type dropdown, inline trash, Set-URL toggles removed; `noteStore.update` now persists `url` (was local-only before)
- [x] Mobile: bottom sheet; per-row +/trash icons removed
- [x] Store methods both platforms: `addChild` (web), `moveUp/moveDown`, `siblingInfo`, descendant count; `duplicate` **skipped** (nice-to-have per spec, can be a follow-up)
- [x] Delete confirm wired here (web: inline confirm in menu; mobile: dialog) — Cause E closed

## Phase N4 — Mobile parity — `feat/notes-mobile-parity` ✅ implemented (commit eb6ab21)
Spec: `04-mobile-parity.md`
- [x] File split per FSD (`entities/note/model/`, `pages/notes/widgets/`)
- [x] DTO + model carry `nodeType`/`url` (immutable `NoteNode` + `copyWith`); per-type rendering (h1/h2/bullet/link/image, `url_launcher` added)
- [x] Indent/outdent/addAfter/move ported to `NotesNotifier` (landed in N3); Enter = add sibling
- [x] Board view + Outline/Board toggle (AppBar icon)
- [x] Notes strings localized ru/en (`shared/core/strings.dart`, system locale; placed in `shared/core/` because a `lib/` path segment trips `avoid_relative_lib_imports`)

## Outstanding from N1–N4 (deferred nice-to-haves + manual QA)

These are the only items from phases N1–N4 not yet done. All were optional/nice-to-have in their specs, except live QA.

- [ ] **`duplicate` node action** (N3, `03-actions-menu.md` #8) — spec marked nice-to-have; not implemented on either platform.
- [ ] **`Ctrl+.` to open the menu** (N3, web) — spec marked optional; not implemented.
- [ ] **Swipe gestures** (N4, `04-mobile-parity.md` step 4) — swipe-right indent / swipe-left outdent; spec marked nice-to-have; not implemented (menu covers it).
- [ ] **Live / manual QA** — static checks all pass, but these need a running app (DB+API were down):
  - Web: select-all text → Delete removes node; type-then-delete shows no "Note not found"; Enter→Backspace leaves no ghost.
  - Web: reload on a zoomed `/notes/[id]` restores it; back walks up; stale id redirects.
  - Mobile: same delete-in-edit + routing checks on device.
  - Web ↔ mobile round trip: a `heading1` with children created on one renders/edits correctly on the other; board shows the same columns/cards.

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
