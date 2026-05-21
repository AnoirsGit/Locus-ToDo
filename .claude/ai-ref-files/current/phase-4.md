# Phase 4 — Backlog features

## Status
In progress

## Items

- [x] **Recurring: multiple days per week** — already fully implemented (migration 002, UI day-picker, API array handling, TaskCard display)
- [ ] **Subtasks (web)** — checklist inside a task card
- [ ] **Mobile: notes screen** — tree outline with mocks (same approach as web)
- [ ] **Tag system** — needs new DB table, schema confirmation required

---

## Subtasks — Plan

**Already done:**
- DB: `parent_task_id UUID` on `tasks` via migration 003
- API: `GET /api/tasks/:taskId/subtasks`, `POST /api/tasks` with `parentTaskId`, level validation
- Web `tasksApi.create()` accepts `parentTaskId`

**To build:**
- [ ] `subtasksApi.get(taskId)` in `shared/api/tasks.api.ts`
- [ ] `SubtaskChecklist.svelte` widget — fetches + renders + toggles + adds subtasks inline
- [ ] Wire into `TaskCard.svelte` — show checklist below task body (expanded on demand)
- [ ] Wire into `EditTaskForm.svelte` — show checklist in edit view
- [ ] Typecheck pass

**Design decisions:**
- Fetch subtasks lazily when task card is expanded (avoid over-fetching on page load)
- Subtask toggle calls existing `PATCH /api/tasks/:id/periods/:periodId/toggle`
- Subtask creation: inline text input → `POST /api/tasks { parentTaskId, level: parent.level, ... }`
- Subtasks inherit parent level (same period type)
- No nested subtasks in UI (depth 1 only for now)

---

## Mobile notes — Plan

**To build:**
- [ ] `NoteNode` data model in Dart
- [ ] `NotesPage` widget — tree outline view only (simpler than web, no board)
- [ ] `NoteRow` widget — recursive row with indent, inline edit, collapse
- [ ] Wire into router + app shell nav

---

## Lessons
(filled after user corrections)
