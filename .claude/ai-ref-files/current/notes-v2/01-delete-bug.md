# 01 — Delete bug: "deleting a note only clears its content"

User report: deleting a note doesn't remove it — only the content disappears.
The full chain (web store → `DELETE /api/notes/:id` → DB `ON DELETE CASCADE`) is
**technically correct**, so the bug is in the UI layers. Audit found 5 compounding
causes; each must be fixed and verified separately.

---

## Cause A (mobile, most likely the reported bug): unkeyed rows + state reuse

`apps/mobile/lib/pages/notes/notes_page.dart`

- `_NoteRow` is a StatefulWidget holding `TextEditingController _ctrl` and `_editing`.
- Rows are built **without keys**: `ListView.builder` items and the recursive
  `...node.children.map((child) => _NoteRow(...))` — no `key: ValueKey(node.id)`.
- When node *i* is deleted, Flutter reuses the Element/State of row *i* for the node
  that shifts into its position. The reused State still has the **deleted node's**
  `_ctrl.text` and `_editing == true`.
- `TextField.onTapOutside / onEditingComplete → _commit()` then calls
  `updateContent(widget.node.id, _ctrl.text)` — `widget.node` is now the *next* note,
  so the deleted note's text is **written onto the neighbor**.
- Net visual effect: the row "is still there" with the same text → user perceives
  "delete doesn't delete, it just messes with content".

**Fix**
1. Add `key: ValueKey(node.id)` to every `_NoteRow` instantiation (ListView itemBuilder + recursive children map).
2. In `_commit()`, skip the update if the controller text equals `widget.node.content` (no-op guard) — cheap extra safety.
3. In `didUpdateWidget`, re-sync `_ctrl.text` when `widget.node.id` changes (belt-and-braces if a key is ever forgotten).

## Cause B (web): keyboard Delete/Backspace on a selection deletes text, not nodes

`apps/web/src/widgets/note-tree/NoteRow.svelte` + `NoteTree.svelte`

- Selecting all text in an input auto-adds the node to `selectedIds` (`handleTextSelect`).
- The user then presses Delete/Backspace expecting node deletion — but there is **no
  Delete-key handler for selections**; the keypress just clears the input text.
  Node stays → literally "only the content is deleted".
- `noteStore.remove` is reachable only via: Backspace on *already-empty* content, or
  the trash icon that appears only when the row is selected.

**Fix**
1. In `handleKeydown`: if `noteStore.selectedIds.size > 0` and key is `Delete`
   (or `Backspace` with the whole text selected), `preventDefault()` and call
   `noteStore.deleteSelected()`.
2. Primary delete affordance moves to the three-dots menu (`03-actions-menu.md`).

## Cause C (web + mobile): pending debounced content PATCH outlives the DELETE

- Web `note.store.svelte.ts`: `debounceMap` timers are **not cancelled** in
  `remove()` / `deleteSelected()`. Sequence: type → delete within 600 ms →
  `DELETE` succeeds → debounce fires `PATCH /notes/:id` → 404 → toast
  "Note not found" (confusing; looks like delete failed).
- Mobile `NotesNotifier._debounceTimers`: same — `removeNote` / `deleteMultiple`
  don't cancel timers (errors are swallowed there, but it's still a stray request).

**Fix**
1. Web: in `remove()` and `deleteSelected()`, `clearTimeout(debounceMap.get('content:'+id))`
   and delete the map entry — for the node **and all its descendants** (collect ids
   from the subtree before removal).
2. Mobile: same with `_debounceTimers`.

## Cause D (web, race): delete fired before optimistic create resolves

`addAfter`/`addRoot` POST with a client UUID, fire-and-forget. If the user creates a
node (Enter) and deletes it before the POST resolves, the `DELETE` 404s first and the
`INSERT` lands after → a ghost empty note reappears on next load.

**Fix (small)**
Track in-flight creates: `pendingCreates = Map<id, Promise>`; in `remove()` /
`deleteSelected()`, `await pendingCreates.get(id)` before issuing the DELETE.

## Cause E (UX): no subtree awareness on delete

DB cascades children silently. Deleting a parent with 30 descendants has the same
affordance as deleting a leaf, and the single-node web flow has no confirmation at all.

**Fix**
In the three-dots menu Delete action: if the node has descendants, confirm with the
count — "Delete note and N nested notes?" (web: small confirm popover/dialog;
mobile: `showDialog`). Leaf nodes delete immediately (multi-select keeps its existing
2-tap confirm). Nice-to-have (later): toast with Undo that re-creates the subtree
from the in-memory copy.

---

## Verification checklist (Prove It)

- [x] Mobile: delete a row while it is in edit mode → row disappears, neighbor keeps its own text — automated: `apps/mobile/test/notes_delete_test.dart` (fails on pre-fix code).
- [x] Mobile: delete row i in a list → no stale text on row i+1 — covered by the same widget test.
- [ ] Web: select-all text in a note, press Delete → node removed (not just text).
- [ ] Web: type into a note, immediately delete it → no "Note not found" toast, note gone after reload.
- [ ] Web: Enter (new node) → instantly Backspace-delete it → no ghost note after reload.
- [ ] Parent with children: delete via menu → confirm dialog shows correct descendant count; DB rows for whole subtree gone (`SELECT count(*) FROM notes WHERE parent_id = ...`).
