# Mobile subtasks on task cards (parity Gap 2)

> Branch: `feat/mobile-subtasks-card` (off main). Closes `mobile-tasks-parity.md` Gap 2.
> No DB/schema changes; `getSubtasks` already existed in `tasks_api.dart`.

## What changed
- New `entities/task/ui/subtask_checklist.dart` — `SubtaskChecklist` ConsumerStatefulWidget,
  a faithful port of web `SubtaskChecklist`:
  - Chevron expander row labelled `S.subtasks`, with a `done/total` count once loaded.
  - Lazy: fetches `getSubtasks(parent.id)` only on first expand.
  - Optimistic toggle by period id (`toggleTask`), reverts on error; haptic on tap.
  - Inline add field (`createTask` with parent level/periodStart/parentTaskId), appends
    on success, keeps typed text on failure.
  - **No delete** — matches web (card checklist is toggle+add only; delete is in the
    edit sheet). Errors revert silently (the global toast is on the B4 branch).
- `task_card.dart` — embeds `SubtaskChecklist(parent: task)` below the card body, inside
  the border, only when `!archived && !backlog` (web's rule). Keyed by task id so state
  follows the task across reorders.

## Verification (Prove It)
- [x] `flutter analyze` clean (no new issues; pre-existing baseline only).
- [ ] Run app: expand a card → subtasks load once; toggle flips + persists; add appends;
      archived/backlog cards have no expander. (needs emulator + API)
