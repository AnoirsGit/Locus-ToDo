# 02 — Note pages: URL routes, back button, breadcrumbs

Goal: every note can be opened as a **page** (Workflowy zoom semantics), with a real
route, a back button, and a breadcrumb trail at the top. Infinite recursive nesting
already works in the data model — this is purely a navigation-layer change.

The zoom mechanics (`rootId`, `rootNodes`, `breadcrumbs`) already exist in both
stores. The work is: **drive `rootId` from the URL instead of ephemeral state.**

No API or DB changes needed.

---

## Web (SvelteKit)

### Routes (remember: routes dir is `src/pages/`, not `src/routes/`)

```
src/pages/(app)/notes/+page.svelte          → root notes page (rootId = null)
src/pages/(app)/notes/[id]/+page.svelte     → zoomed page (rootId = params.id)
```

### Implementation steps

1. **Extract the shared page body** into a widget, e.g. `widgets/note-page/NotePage.svelte`
   with prop `rootId: string | null` — contains the header (title + view toggle),
   `NoteTree` / `NoteBoard` (current content of `notes/+page.svelte`).
2. `notes/+page.svelte` → `<NotePage rootId={null} />`.
3. `notes/[id]/+page.svelte` → read `page.params.id` (`$app/state`), `<NotePage rootId={id} />`.
4. In `NotePage`: `$effect(() => { noteStore.load().then(() => noteStore.setRoot(rootId)) })`.
   - `load()` is already idempotent (`if (state.loaded) return`).
   - **Deep-link guard**: after load, if `rootId` is set but `findNodeById` misses
     (deleted note / foreign id) → `goto('/notes', { replaceState: true })`.
5. **Replace all `setRoot` call sites with navigation:**
   - `NoteRow` `onZoom` → `goto(\`/notes/${id}\`)`.
   - Breadcrumb clicks in `NoteTree` → `goto(\`/notes/${crumb.id}\`)`; Home crumb → `goto('/notes')`.
   - "Open as page" action in the three-dots menu (see `03-actions-menu.md`) → same.
   - Keep `noteStore.setRoot()` itself — it stays as the store-level primitive the route effect calls.
6. **Back button**: on `[id]` pages show a `←` button left of the `h1` title.
   Behavior: `history.back()` when `page.state` indicates in-app navigation, else
   `goto` to parent crumb (`breadcrumbs.at(-2)` or `/notes`). Simplest robust version:
   always `goto` parent crumb — predictable hierarchical "up", and the browser back
   button already covers chronological back.
7. **Page title**: on `[id]` pages render the zoomed node's `content` as the `h1`
   (editable later — out of scope), and set `<svelte:head><title>` accordingly.
8. Breadcrumb bar: already implemented in `NoteTree`; only swap click handlers to `goto`
   and render it on the root page too when zoomed (it already hides when `rootId == null`).

### Gotchas
- `noteStore` is module-global; navigating between `[id]` pages re-runs the effect —
  `setRoot` must clear `selectedIds` (it already does).
- SvelteKit reuses the component between `[id]` params — the `$effect` reading a
  reactive `page.params.id` handles this; do not read params once in module scope.

---

## Mobile (Flutter + go_router)

### Routes

```dart
GoRoute(path: '/notes', builder: (_, __) => const NotesPage()),          // root
GoRoute(path: '/notes/:id', builder: (_, s) =>
    NotesPage(rootId: s.pathParameters['id'])),                          // zoomed page
```

Both stay inside the existing `ShellRoute` so the bottom nav remains visible.
`AppShell` route matching (`_routes` contains `/notes`) must treat `/notes/:id` as the
notes tab — match by `startsWith('/notes')`.

### Implementation steps

1. `NotesPage` gets `final String? rootId` constructor param; **delete `rootId` from
   `NotesUiState`** (keep `selectedIds` only). All `visibleRoots`/`breadcrumbs` calls
   use `widget.rootId`.
2. Zoom (tap leaf bullet / "Open as page" menu action) → `context.push('/notes/$id')`.
   `push` (not `go`) so the system/AppBar back pops one zoom level — matches the
   user requirement "opens like a page with a back button".
3. AppBar on zoomed pages: `leading` = `BackButton` (replaces the Locus logo there),
   `title` = zoomed note content (fallback "Untitled"/localized).
4. Breadcrumb bar (`_BreadcrumbBar` already exists): crumb tap →
   `context.go('/notes/${crumb.id}')` *replacing* the stack up to that level — simplest
   correct version: `popUntil`-like loop is overkill; use `context.go` and accept a
   reset stack. Home crumb → `context.go('/notes')`.
5. Deep link / stale id (note deleted while on its page): if `_findNode` misses after
   load → auto-`context.go('/notes')`.
6. Empty zoomed page: keep current empty state + FAB adds a child of `rootId`
   (`addRoot(underRootId:)` already does this).

### Gotchas
- `notesProvider` is an `AsyncNotifier` shared across pages — pushing a second
  `NotesPage` is fine (same data), but selection state must not leak between stacked
  pages: clearing selection on push is acceptable (`notesUiProvider` reset in `initState`-equivalent or keep a per-page local selection — prefer **per-page local state** now that rootId left the provider).
- Recursive nesting depth: each zoom pushes a route; deep trees → deep stacks. Fine —
  Workflowy behaves the same way (back walks out level by level).
