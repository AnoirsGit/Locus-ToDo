# Notes v2 — Analysis & Implementation Plan

> Created 2026-06-10 from a full code audit of the notes feature (web + mobile + API).
> Successor to `current/feat-notes.md` (v1, shipped).

## Files in this folder

| File | Topic |
|------|-------|
| `README.md` | Current feature inventory, competitor analysis, gap summary |
| `01-delete-bug.md` | Root-cause analysis of "delete only clears content" + fix spec |
| `02-note-pages-routing.md` | URL-based note pages (web `/notes/[id]`, mobile `/notes/:id`), back button, breadcrumbs |
| `03-actions-menu.md` | Workflowy-style three-dots actions menu (replaces current inline actions) |
| `04-mobile-parity.md` | Mobile ⇄ Web feature gap table + implementation steps |
| `05-roadmap.md` | Phased checklist (work top-to-bottom) |

---

## Current architecture (audited 2026-06-10)

### Data model
- Table `notes` (migration `004_notes.sql`): self-referencing tree via `parent_id`
  (`ON DELETE CASCADE`), `node_type`, `content`, `url`, `sort_order`, `collapsed`.
- `note_tags` junction table exists (migration `005_tags.sql`) — **backend complete, zero UI**.
- Node types: `text | heading1 | heading2 | bullet | image | link`.

### API (`apps/api`)
- `notes.routes.ts`: `GET /api/notes` (full tree), `POST`, `PATCH /:id`, `DELETE /:id` (204).
- `note.repository.ts`: tree built in JS from a flat user-scoped SELECT; cascade delete is DB-level.
- Tag endpoints for notes exist: `GET /api/tags/notes/:noteId`, `PUT /api/tags/notes/:noteId`.

### Web (`apps/web`)
- `entities/note/model/note.store.svelte.ts` — single global store; tree CRUD, indent/unindent,
  collapse, multi-select, zoom (`rootId`), breadcrumbs, debounced content PATCH (600 ms).
- `widgets/note-tree/` — NoteTree (breadcrumb bar, selection toolbar) + NoteRow (recursive).
- `widgets/note-board/` — Board view: top-level nodes = columns, children = cards.
- `pages/(app)/notes/+page.svelte` — single route `/notes`, view toggle Outline/Board.
- **Zoom is store-state only** (`noteStore.setRoot`) — no URL, no history, no shareable links.

### Mobile (`apps/mobile`)
- `pages/notes/notes_page.dart` — everything in one file: model, two Riverpod notifiers, page, rows.
- `shared/api/notes_api.dart` — DTO **drops `nodeType` and `url`** (only id/parentId/content/collapsed/sortOrder).
- Single route `/notes` in `core/router/router.dart`; zoom via `notesUiProvider.rootId` (no URL, system back exits the screen instead of going up a level).
- Hardcoded Russian strings (web uses `i18n` store with ru/en).
- No offline support for notes (tasks have Drift + outbox; notes are direct HTTP).

---

## Feature inventory — what we have today

| Feature | Web | Mobile |
|---|---|---|
| Infinite nesting | ✅ | ✅ |
| Inline edit | ✅ | ✅ (tap to edit, commit on blur) |
| Node types (text/h1/h2/bullet/image/link) | ✅ (select dropdown on focus) | ❌ (plain text only, DTO drops fields) |
| Collapse / expand | ✅ | ✅ |
| Zoom into node (Workflowy pages) | ✅ store-only | ✅ store-only |
| Breadcrumbs | ✅ in-component | ✅ in-component |
| URL routes per note | ❌ | ❌ |
| Add sibling (Enter) | ✅ | ❌ (only add child / add root) |
| Indent / unindent | ✅ Tab / Shift+Tab | ❌ no way to restructure at all |
| Reorder siblings (drag or move up/down) | ❌ | ❌ |
| Multi-select | ✅ click/Ctrl/Shift/Shift+Arrow | ✅ long-press + tap |
| Bulk delete w/ confirm | ✅ (2-tap confirm) | ✅ (2-tap confirm) |
| Single delete | ⚠️ trash icon only when row selected | ⚠️ always-visible trash icon per row |
| Keyboard nav | ✅ arrows, Enter, Tab, Esc | n/a |
| Board view | ✅ | ❌ |
| Tags on notes | ❌ (backend ready) | ❌ |
| Search / filter | ❌ | ❌ |
| Duplicate node | ❌ | ❌ |
| Move-to dialog | ❌ | ❌ |
| Undo | ❌ | ❌ |
| Export (OPML/Markdown) | ❌ | ❌ |
| Offline | ❌ | ❌ (tasks have it) |
| Completed/checkbox nodes | ❌ | ❌ |

---

## Competitor analysis (outliner-style notes)

### Workflowy (primary reference per user)
- Every bullet is a page: zoom in via bullet click, **URL changes** (`workflowy.com/#/<id>`), browser back works, breadcrumbs on top.
- Per-node "..." menu (also right-click): Complete, Add note, Duplicate, Copy link,
  Expand/Collapse all, Move to…, Export, Delete. Hover-revealed on desktop, tap on mobile.
- Drag handle on bullet for drag-and-drop reorder/reparent.
- Strikethrough "complete" state; inline `#tags` and `@mentions` that act as filters;
  global search; starred/bookmarked views; kanban board view of children; mirrors (same node in 2 places); file/image embeds; live-copy share links; undo.

### Dynalist
- Same outliner core + checkboxes, numbered lists, per-node colors, headings (h1–h3),
  code formatting, due dates, "Move to" fuzzy dialog, bookmarks, document tree sidebar.

### Notion
- Block-based pages (not pure outliner): toggle blocks ≈ collapse; slash-command to change block type; every page has URL + breadcrumbs + back; databases/boards; comments.

### Logseq / Roam
- Outliner + daily journal; block references and backlinks `[[page]]`; query/filter; local-first.

### Takeaways for Locus (ranked by fit)
1. **URL-per-node zoom + breadcrumbs + back** (Workflowy/Notion) — user explicitly wants this → `02-note-pages-routing.md`.
2. **"..." menu per node** (Workflowy) — user explicitly wants this → `03-actions-menu.md`.
3. **Drag/reorder + Move-to** — we have `sort_order` + `parentId` PATCH already; only UI missing.
4. **Tags on notes** — backend 100% done (`note_tags`, `TagPicker` exists for tasks); cheap win, fits product (filter notes by tag).
5. **Search** — flat `ILIKE` over `notes.content` is enough for MVP.
6. **Checkbox/complete nodes** — fits a discipline/task product; needs `node_type` value or new column → **requires schema discussion (DB rule!)**.
7. Mirrors/backlinks/share — out of scope for now.

---

## Top problems found (summary)

1. **Delete is broken in practice** — multiple compounding causes, incl. a mobile state-reuse bug that *rewrites a neighbor note's content with the deleted note's content* (looks exactly like "only content gets deleted"). Full analysis: `01-delete-bug.md`.
2. **Zoom is not navigation** — no URL, no back button, breadcrumbs reset on reload, deep links impossible. Spec: `02-note-pages-routing.md`.
3. **Actions UI is inconsistent and discoverable-by-accident** — web: type dropdown appears on focus + trash appears only when selected; mobile: permanent +/trash icons crowding every row. Spec: `03-actions-menu.md`.
4. **Mobile is far behind web** — no node types, no indent/outdent (tree can't be restructured at all on mobile!), no sibling insert, no board, hardcoded Russian. Spec: `04-mobile-parity.md`.
