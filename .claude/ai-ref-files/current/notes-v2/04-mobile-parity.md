# 04 — Mobile parity: bring Flutter notes up to the web feature set

User requirement: mobile functionality and UI/UX must not be inferior to web —
everything the web version has, mobile must have.

## Gap table (mobile-missing items, priority order)

| # | Gap | Web reference | Effort |
|---|-----|---------------|--------|
| 1 | **Node types** (`text/heading1/heading2/bullet/image/link`) — DTO drops `nodeType` + `url` entirely | `note.types.ts`, `NoteRow.svelte` rendering branches | M |
| 2 | **Indent / Outdent** — tree cannot be restructured on mobile at all | `noteStore.indent/unindent` | M |
| 3 | **Add sibling** — only add-child/add-root exist | `noteStore.addAfter` | S |
| 4 | **Reorder (move up/down)** | new on both (see `03`) | S |
| 5 | **URL routes + back button for zoom** | see `02-note-pages-routing.md` | M |
| 6 | **Three-dots actions menu** | see `03-actions-menu.md` | M |
| 7 | **Board view** (columns = top-level, cards = children) | `NoteBoard.svelte` | M |
| 8 | **i18n** — mobile hardcodes Russian ('Заметки', 'Нет заметок', 'выбрано'…); web has ru/en via `i18n` store | `$shared/lib/i18n` | S |
| 9 | **Delete-bug fixes** (keys, debounce-cancel, subtree confirm) | see `01-delete-bug.md` | S |
| 10 | Offline notes (Drift + outbox, like tasks) | mobile-only concern | L — **separate later phase, needs discussion** |

Already at parity: infinite nesting, collapse/expand, zoom+breadcrumbs (state-based),
multi-select with confirm, debounced content save, optimistic updates, empty states.

## Implementation plan

### Step 1 — Refactor file layout (precondition, keeps FSD honest)
`pages/notes/notes_page.dart` currently holds model + API-mapping + 2 providers +
4 widgets in one file. Split per mobile FSD:

```
entities/note/model/note_node.dart        — NoteNode (+ nodeType, url fields)
entities/note/model/notes_notifier.dart   — NotesNotifier + notesProvider (tree ops)
features/notes/notes_ui_state.dart        — selection state (rootId removed, see 02)
pages/notes/notes_page.dart               — NotesPage scaffold
pages/notes/widgets/note_row.dart         — _NoteRow (+ ValueKey, menu trigger)
pages/notes/widgets/breadcrumb_bar.dart   — _BreadcrumbBar
pages/notes/widgets/selection_bar.dart    — _SelectionBar
pages/notes/widgets/note_actions_sheet.dart — bottom sheet (03)
```

### Step 2 — DTO + model: carry full node data
- `NoteDto`: add `nodeType` (string) and `url` (String?); parse from JSON; pass
  through `create`/`update` payloads.
- `NoteNode`: add `type` + `url`; consider making it immutable with a proper
  `copyWith` to stop hand-rolling field copies in `_mapNodes`/`_removeNode`.

### Step 3 — Rendering per node type (mirror web)
- `text` — plain (current behavior).
- `heading1` / `heading2` — larger/bolder text style (match web's `.note-h1/.note-h2` intent).
- `bullet` — current dot style.
- `link` — content as label + trailing `↗` icon, tap opens `url_launcher`; URL edited via menu "Set URL…".
- `image` — `Image.network(url)` with caption text field below; graceful error placeholder.
- "Turn into" lives in the three-dots sheet (03).

### Step 4 — Structure editing
- Port `indent`/`unindent`/`addAfter`/`moveSibling` from `note.store.svelte.ts` into
  `NotesNotifier` (same parentId/sortOrder PATCH semantics, optimistic).
- Expose via three-dots sheet; optionally also horizontal-swipe gestures
  (swipe right = indent, left = outdent) — nice-to-have, behind the menu first.
- Keyboard "Enter to add sibling": in the row TextField, `onSubmitted` → commit +
  `addAfter(node.id)` + focus new row (replaces today's commit-only behavior; matches
  web Enter semantics).

### Step 5 — Board view
- Add the same Outline/Board toggle as web (`notes_page` header or a segmented control).
- `PageView`/horizontal `ListView` of columns (top-level nodes), children as cards.
- Read-only-ish MVP like web's board: edit content inline, add card, add column.

### Step 6 — i18n
- Mobile currently hardcodes Russian across all pages, not just notes — for the notes
  scope, route all new + existing notes strings through whatever localization
  mechanism mobile adopts. If none exists yet, create a minimal
  `shared/lib/strings.dart` keyed table (ru/en) consistent with the web `i18n` store,
  and file the app-wide sweep as a separate task (out of notes scope).

### Step 7 — Verification (Prove It)
- [ ] `flutter analyze` clean.
- [ ] Create/edit/indent/outdent/move/turn-into/delete each verified against live API; reload survives.
- [ ] Web → mobile round trip: node typed as `heading1` with children on web renders and edits correctly on mobile, and vice-versa.
- [ ] Board view shows same columns/cards as web for the same account.
