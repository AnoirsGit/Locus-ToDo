# arch/mobile.md

> Load when: Flutter app (apps/mobile) — screens, providers, navigation.

## Stack

Flutter 3 · Riverpod (manual providers, no codegen) · go_router · Dio · Drift (SQLite offline)

---

## FSD Structure

```
apps/mobile/lib/
  pages/
    auth/         # login_page.dart, register_page.dart
    tasks/        # tasks_page.dart (backlog, archive views)
    view_tab/     # view_tab_page.dart (day/week/month/year + kanban)
    stats/        # stats_page.dart
    notes/        # notes_page.dart (hierarchical notes tree)
    settings/     # settings_page.dart
    app_shell.dart  # ShellRoute scaffold (drawer, GlobalKey)
  features/
    auth/         # auth_notifier.dart (login, register, logout)
    task_form/    # task_form_sheet.dart (create + edit bottom sheet)
  entities/
    task/         # task.dart, grouped_tasks_notifier.dart, tasks_notifier.dart
                  #   ui/task_card.dart, ui/task_level_badge.dart
    user/         # user.dart
  widgets/
    app_drawer.dart
  shared/
    api/
      api_client.dart      # Dio + JWT interceptor + token refresh
      auth_api.dart        # login, register, me
      tasks_api.dart       # CRUD + subtasks + toggle
      tags_api.dart        # TagDto, TagsApi (list/CRUD/task assignments)
      notes_api.dart       # NoteDto, NotesApi (hierarchical CRUD)
    providers/
      view_provider.dart   # activeViewProvider (day/week/month/year)
      tag_store.dart       # TagStoreNotifier — loads all tags + task assignments
    db/
      app_database.dart    # Drift schema (tasks, task_periods, outbox_queue)
      local_task_repository.dart
    sync/
      sync_worker.dart     # outbox queue → API sync
    notifications/
      notification_service.dart
      notification_prefs.dart
    core/
      secure_storage.dart
    theme/
      theme.dart
      theme_provider.dart
    ui/
      rich_text_editor.dart
  core/
    router/router.dart     # go_router with ShellRoute + auth guard
  main.dart
```

Import direction: `pages → widgets → features → entities → shared` — downward only.

---

## Routing

```dart
// router.dart
GoRouter routes:
  /login       → LoginPage
  /register    → RegisterPage
  ShellRoute (AppShell):
    /view      → ViewTabPage  (day/week/month/year/kanban)
    /backlog   → TasksPage(view: 'backlog')
    /archive   → TasksPage(view: 'archive')
    /stats     → StatsPage
    /notes     → NotesPage
    /settings  → SettingsPage

Auth guard: unauthenticated → /login  (allows /register too)
           authenticated + auth path → /view
```

---

## State (Riverpod)

| Provider | Type | Purpose |
|----------|------|---------|
| `groupedTasksProvider(view)` | `FamilyAsyncNotifierProvider` | Tasks per view + context sections |
| `tasksNotifierProvider` | `AsyncNotifierProvider` | All tasks (offline-capable) |
| `authNotifierProvider` | `AsyncNotifierProvider<User?>` | Auth state |
| `tagStoreProvider` | `StateNotifierProvider<TagStoreState>` | All tags + task→tag map |
| `notesProvider` | `AsyncNotifierProvider<List<NoteNode>>` | Note tree |
| `activeViewProvider` | `StateNotifierProvider` | Current view tab |

---

## Key Architecture Decisions

| Decision | Reason |
|----------|--------|
| Riverpod (manual) | DI + state; codegen unnecessary for this scale |
| go_router | Declarative, ShellRoute for persistent drawer |
| Drift | Typed SQLite for offline task storage |
| Dio interceptors | JWT injection + silent token refresh |
| `TagStoreNotifier` | Loads all tags + assignments once on startup; provides `getTagsForTask(id)` |
| `TaskCard` as `ConsumerWidget` | Reads `tagStoreProvider` directly — no prop drilling needed |
| Tag picker in `TaskFormSheet` | Edit mode only (create mode lacks task ID until after API call) |

---

## Offline Mode

- `TasksNotifier` writes to Drift (local) first, then queues to `outbox_queue`
- `SyncWorker` processes queue against real API
- `GroupedTasksNotifier` (view-tab) bypasses offline — reads API directly + refresh on mutation

---

## Notes Feature

`NotesPage` + `NotesNotifier (AsyncNotifier)`:
- Hierarchical tree via `NoteNode` (recursive children)
- `generateUuid()` in `notes_api.dart` for client-generated IDs
- Debounced PATCH (600ms) for content, immediate PATCH for collapse state

---

## Build & CI

- `flutter build apk --release --dart-define=API_URL=<url>`
- `API_URL` injected via `String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000/api')`
- GitHub Actions `.github/workflows/flutter.yml`: signs APK (keystore in secrets), creates GitHub Release
- App label: "Locus", package: `com.locus.app`
