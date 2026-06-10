# feat/notes

> v1 — shipped. Follow-up analysis & v2 plan: `current/notes-v2/` (delete bug, note-page routes, three-dots menu, mobile parity).

## Goal
Notes section in LocusToDo web app — tree-structured notes with typed nodes,
inline editing, two views: Outline (tree) and Board (columns).

## Checklist

- [x] Branch created: `feat/notes`
- [x] `entities/note/` — NoteNode types, API-backed store, CRUD + indent/unindent/collapse
- [x] `widgets/note-tree/` — NoteTree + NoteRow (outline view, keyboard nav, multi-select, pages/zoom)
- [x] `widgets/note-board/` — NoteBoard (column view); uses rootNodes for page scope; async addAfter/addRoot fixed
- [x] `pages/(app)/notes/+page.svelte` — Notes page with view toggle (route: /notes)
- [x] Bottom nav: Archive → Notes
- [x] `(app)/+layout.svelte` — 'docs' AppView, '/notes' route
- [x] Sidebar: /notes link, label "Заметки / Notes"
- [x] `frontend.md` updated

## Node types
`text | heading1 | heading2 | bullet | image | link`

## Views
- **Outline** — recursive indented tree, inline edit, Tab/Shift+Tab indent
- **Board** — top-level nodes = columns, their children = cards

## Keyboard shortcuts (Outline)
- Enter — create new sibling after current node
- Backspace on empty — delete node, focus previous
- Tab — indent (become child of previous sibling)
- Shift+Tab — unindent (move up one level)
- ArrowUp / ArrowDown — move focus between visible nodes
- Shift+ArrowUp / Shift+ArrowDown — extend/shrink selection
- Escape — clear selection
- Click bullet (leaf node) — zoom into node as page root
- Click bullet (parent node) — collapse/expand children

## Pages (Workflowy-style zoom)

- `noteStore.rootId` — the node currently acting as the page root (null = global root)
- `noteStore.rootNodes` — visible top-level nodes (children of rootId, or all nodes)
- `noteStore.breadcrumbs` — path array `[{id, content}]` from global root to rootId
- `noteStore.setRoot(id)` — zoom into a node; `setRoot(null)` returns to global root
- Breadcrumb nav rendered at top of NoteTree: Home → ancestor1 → … → current (bold)
- Clicking any ancestor breadcrumb navigates to that level
- `addRoot()` adds as child of rootId when inside a page

## Multi-select

- `noteStore.selectedIds: Set<string>` — currently selected node IDs
- `noteStore.setSelection(ids)` / `clearSelection()` / `deleteSelected()`
- Selection toolbar appears when `selectedIds.size > 0`: shows count + Delete + Clear (✕)
- **Range select**: Shift+Click from anchor to clicked node (contiguous range in flat list)
- **Toggle select**: Ctrl/Cmd+Click toggles individual node
- **Single select**: plain Click selects only the clicked node, sets anchor
- **Keyboard extend**: Shift+Arrow grows/shrinks selection from current focus end
- Selected rows get `background: var(--color-brand-soft)` highlight

## Storage
API-backed: `notesApi` CRUD, debounced PATCH for content, immediate PATCH for type/collapsed/parent.
Migration: `004_notes.sql`.
