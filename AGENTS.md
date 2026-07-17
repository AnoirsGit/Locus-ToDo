# Locus-ToDo — Agent Memory

## Project structure

Monorepo: `apps/api` (Fastify/TypeScript), `apps/web` (SvelteKit), `apps/mobile` (Flutter/Riverpod).

## Key plan files

All open work lives in `.claude/ai-ref-files/current/`:
- `bugs.md` — canonical bug list with priority (B1–B4)
- `mobile-tasks-parity.md` — Gap 1–6 (web vs mobile features)
- `qol-polish.md` — B–G sections (feedback, interaction, i18n)
- `web-i18n-task-surface.md` — web locale batches (all done)

## What's done (this session, commit 30d4955)

- **B4** Mobile errors swallowed → `shared/ui/app_toast.dart` + AppShell toast listener + sync outbox banner
- **B3** Mobile stale data → AppShell `WidgetsBindingObserver` (60 s throttle)
- **Gap 1** Tag filter bar → extracted `TagFilterBar` widget, applied to all `view_tab_page` bodies

## What remains (priority order)

### Mobile (highest value)
- **B4** remainder: `shared/providers/tag_store.dart` tags reload on resume
- **Gap 2** Subtasks card in `task_card.dart` (lazy expand + inline add)
- **Gap 3** Stats parity — year history + current trend prepend
- **Gap 4** Kanban column create date-bound (`_DayColumn` → `onCreate(dateStr)`)
- **Gap 5 / E1** i18n sweep (mobile strings.dart + locale provider)

### Web
- Minor i18n: date format `'en'` locale in TaskCard → `i18n.locale`
- `web-on-phone` pass: TaskModal at 360 px, tap targets ≥40 px

### QoL polish
- Mobile skeleton loaders (CircularProgressIndicator → Skeleton)
- Pull-to-refresh on notes page
- List animations (AnimatedList on task complete/delete)

## Mobile architecture patterns

- **State**: Riverpod (StateNotifierProvider, AsyncNotifierProviderFamily)
- **Offline-first tasks**: `local_task_repository` + `SyncOutbox` (Drift DB)
- **Offline-first notes**: `OfflineNotesApi` + `NotesOutbox`
- **Toast**: `appToastProvider` (StateNotifierProvider) — listen in AppShell, call `.show()` from any notifier
- **Outbox count**: `outboxCountProvider` (StreamProvider) watches `watchPendingOutboxCount()` Drift stream
- **Tag filter**: `tagStoreProvider` (StateNotifierProvider), `filterTasks()` helper
- `TagFilterBar` shared widget: `entities/task/ui/tag_filter_bar.dart`

## Build commands

```bash
# Web
cd apps/web && pnpm typecheck    # must be clean

# Mobile  
cd apps/mobile && flutter analyze   # must be clean (flutter not in this container)

# API
cd apps/api && pnpm build
```
