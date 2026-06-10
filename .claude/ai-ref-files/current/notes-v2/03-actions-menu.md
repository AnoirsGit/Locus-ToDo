# 03 — Workflowy-style three-dots actions menu

User requirement: current per-row actions are disliked. Replace with a single
**"⋯" (three dots)** trigger per row that opens a list of actions, like Workflowy.

## What gets removed

- **Web `NoteRow`**: the `<select>` type dropdown shown on focus; the inline trash
  icon shown when `singleSelected`; the "Set URL / Hide URL" toggle buttons inside
  image/link nodes (URL editing moves into the menu).
- **Mobile `_NoteRow`**: the always-visible `+` and trash icons on every row.

Multi-select keeps its existing selection toolbar (it acts on N nodes; the menu acts on one).

## Trigger

- **Web**: "⋯" button at the row's right edge, visible on row hover or when the row
  has focus (CSS `opacity: 0; .note-row:hover & { opacity: 1 }` pattern). Opens an
  anchored popover below the button. Also open on right-click of the row (`contextmenu`).
- **Mobile**: "⋯" `IconButton` always visible at the row's right edge (no hover on
  touch), opens a **bottom sheet** (`showModalBottomSheet`) — standard mobile idiom
  Workflowy also uses.

## Menu actions (MVP — both platforms unless noted)

Order matters; destructive last, separated.

1. **Open as page** — navigate to the note's route (see `02-note-pages-routing.md`).
2. **Add child** — create empty child, expand node, focus it.
3. **Add sibling below** — `addAfter(id)`, focus it. (Web also keeps Enter shortcut.)
4. **Turn into ▸** — submenu / second sheet: Text · H1 · H2 · Bullet · Image · Link.
   Mobile gets node types as part of parity (`04-mobile-parity.md`); until then mobile hides this item.
5. **Set URL…** — only for `image`/`link` nodes; small inline input (web popover) /
   text-field dialog (mobile). Replaces the current "Set URL" toggle.
6. **Indent** / **Outdent** — call existing `indent`/`unindent`. Disabled when not
   applicable (first sibling / root level). Primarily for mobile (no Tab key); web
   shows them with `Tab`/`Shift+Tab` hints.
7. **Move up / Move down** — swap `sort_order` with adjacent sibling (new store method,
   `PATCH sortOrder`; cheap precursor to full drag-and-drop).
8. **Duplicate** — deep-copy subtree with fresh UUIDs, insert after the node
   (sequence of `POST /notes` calls, parent-first; no API change needed). *Nice-to-have — may slip to a later phase.*
9. ─ separator ─
10. **Delete** (danger-styled) — leaf: delete immediately; has descendants: confirm
    "Delete note and N nested notes?" (see `01-delete-bug.md`, Cause E).

## Implementation notes

### Web
- New component `widgets/note-tree/NoteRowMenu.svelte` (popover; no shadcn dependency
  needed — follow existing hand-rolled popover patterns in the codebase if any; else
  a positioned `div` + outside-click close + `Escape` close).
- FSD: menu lives in `widgets/note-tree/` next to `NoteRow`; mutations stay in
  `noteStore` (`entities/note`) — add `moveUp/moveDown/duplicate` to the store.
- Keyboard: menu opens with `Ctrl+.` on the focused row (Workflowy muscle memory) —
  optional, cheap.
- The type-select removal frees the focus-state UI; `Turn into` writes via existing
  `noteStore.update(id, { type })`.

### Mobile
- `showModalBottomSheet` with a `ListTile` column; destructive tile in red
  (`context.colorDanger` equivalent from theme extensions).
- `Move up/down`, `Indent`, `Outdent` require new `NotesNotifier` methods mirroring
  the web store logic (`indent`, `unindent`, `moveSibling`) — port from
  `note.store.svelte.ts` (same optimistic-update + `PATCH parentId/sortOrder` calls).
- After `Add child` / `Add sibling`, auto-enter edit mode on the new row (the
  empty-content autofocus in `_NoteRowState.initState` already handles this once keys
  from `01-delete-bug.md` are in place).

## Store additions required (both platforms)

| Method | API call | Notes |
|---|---|---|
| `moveUp(id)` / `moveDown(id)` | `PATCH { sortOrder }` ×2 (swap with neighbor) | renumber `(idx)*10` scheme locally |
| `duplicate(id)` | N× `POST /notes` parent-first | client UUIDs, insert after source |
| `addChild(parentId)` (web) | `POST /notes` | mobile already has it; web only has `addAfter`/`addRoot` |
| descendant count helper | — | for the delete confirm text |
