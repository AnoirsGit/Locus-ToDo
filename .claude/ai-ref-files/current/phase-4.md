# Phase 4 — Backlog features

## Status
DONE

## Items

- [x] **Recurring: multiple days per week** — migration 002, UI day-picker, API array handling, TaskCard display
- [x] **Subtasks (web)** — `SubtaskChecklist.svelte` in `entities/task/ui/`; lazy-loaded in `TaskCard` via toggle; `GET /api/tasks/:id/subtasks` + inline add + toggle
- [x] **Mobile: notes screen** — `NotesPage` + `_NoteRow` (recursive tree, inline edit, collapse/expand, add child/root); API-backed via `notesApiProvider`; in router at `/notes`
- [x] **Tag system** — migration 005; full CRUD backend; web `tagStore` + `TagChip` + `TagPicker` in `entities/tag/`; tag picker in `EditTaskForm`; mobile `tag_store.dart` + tag chips in `TaskCard` + picker in `TaskFormSheet`

---

## Lessons
(filled after user corrections)
