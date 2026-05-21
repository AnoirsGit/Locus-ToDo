# feat/notes

## Goal
Notes section in LocusToDo web app — tree-structured notes with typed nodes,
inline editing, two views: Outline (tree) and Board (columns).

## Checklist

- [x] Branch created: `feat/notes`
- [ ] `entities/note/` — NoteNode types, store, mocks
- [ ] `widgets/note-tree/` — NoteTree + NoteRow (outline view)
- [ ] `widgets/note-board/` — NoteBoard (column view)
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
- Click bullet — collapse/expand children

## Storage
Mock data for now (same pattern as tasks). API integration later.
