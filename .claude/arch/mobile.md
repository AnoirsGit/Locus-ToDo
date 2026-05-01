# arch/mobile.md

> Load when: Flutter app (apps/mobile) — screens, providers, navigation.

## Architecture: Feature-Sliced Design (FSD) + Riverpod

```
apps/mobile/lib/
├── app/                    # App init
│   └── app.dart            # MaterialApp.router, ProviderScope
│
├── pages/                  # Screens = terminal go_router routes
│   ├── day/
│   │   └── day_page.dart
│   ├── week/
│   │   └── week_page.dart
│   ├── month/
│   │   └── month_page.dart
│   ├── year/
│   │   └── year_page.dart
│   ├── backlog/
│   │   └── backlog_page.dart
│   ├── archive/
│   │   └── archive_page.dart
│   └── auth/
│       ├── login_page.dart
│       └── register_page.dart
│
├── widgets/                # Composite blocks used across multiple features
│   ├── app_shell/
│   │   └── app_shell.dart  # BottomNavigationBar / NavigationDrawer
│   └── task_list/
│       └── task_list.dart
│
├── features/               # User actions
│   ├── create_task/
│   │   ├── create_task_modal.dart
│   │   └── create_task_notifier.dart  # Notifier
│   ├── complete_task/
│   │   └── complete_task_notifier.dart
│   └── replan_task/
│       └── replan_task_notifier.dart
│
├── entities/               # Business objects + their UI
│   └── task/
│       ├── task.dart             # Dart model (freezed or plain)
│       ├── task_card.dart        # Card widget
│       ├── task_level_badge.dart # Level badge widget
│       └── tasks_provider.dart   # AsyncNotifierProvider<List<Task>>
│
├── shared/                 # Reusable with no domain context
│   ├── ui/                 # Base widgets (AppButton, AppModal)
│   ├── theme/
│   │   └── theme.dart
│   ├── api/
│   │   ├── api_client.dart    # Dio + interceptors
│   │   └── tasks_api.dart
│   └── core/
│       ├── router.dart        # go_router config
│       └── secure_storage.dart
│
└── main.dart
```

---

## FSD Rules

### What belongs where

| Layer     | Create when                                        | Has                                   | Must NOT have               |
|-----------|----------------------------------------------------|---------------------------------------|-----------------------------|
| `entity`  | It's a business concept with its own data          | api, provider, types, dumb widgets    | deps on features or widgets |
| `feature` | It's a user action or orchestrates 2+ entities     | ui, optional Notifier                 | own api, own data types     |
| `widget`  | It's a ready-made screen section                   | ui, optional local state              | direct API calls            |

**Quick check:**
- Entity → you own the data (types, provider, API client)
- Feature → user does an action, or Notifier pulls from 2+ entities
- Widget → assembles entity widgets + features into one UI block

### Import direction

`pages → widgets → features → entities → shared` — downward only, never up.  
Slices at the same layer must not import each other — use `@x` instead.  
Each slice exports via a barrel file (`task/index.dart`).

### Cross-imports: `@x`

When entity A genuinely needs something from entity B, A creates an `@x/` file and re-exports **only** the minimum needed. No broad re-exports.

```
entities/task/@x/user.dart   → exports TaskModel so user entity can reference tasks
entities/user/@x/task.dart   → exports userProvider so task can check auth state
```

Same pattern at widget level when a widget reuses an internal component of another widget.  
**Create `@x` only** for a real business need — never speculatively.

---

## State Management: Riverpod

### Pattern for tasks

```dart
// entities/task/tasks_provider.dart

@riverpod
class TasksNotifier extends _$TasksNotifier {
  @override
  Future<List<Task>> build() => ref.read(tasksApiProvider).fetchAll();

  Future<void> complete(String id) async {
    await ref.read(tasksApiProvider).complete(id);
    ref.invalidateSelf();
  }
}
```

### Riverpod Rules

- `@riverpod` (code-gen) — primary way to create providers
- `AsyncNotifierProvider` — for data with loading/error states
- `NotifierProvider` — for synchronous state (UI state, filters)
- **No** `StateProvider` for complex state — use `Notifier` instead
- Providers live in `entities/` or `features/` — never in `pages/`

---

## Navigation: go_router

```dart
// shared/core/router.dart
final routerProvider = Provider<GoRouter>((ref) => GoRouter(
  redirect: (ctx, state) => authGuard(ref, state),
  routes: [
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/week',    builder: ...),
        GoRoute(path: '/month',   builder: ...),
        GoRoute(path: '/year',    builder: ...),
        GoRoute(path: '/backlog', builder: ...),
        GoRoute(path: '/archive', builder: ...),
      ],
    ),
    GoRoute(path: '/login',    builder: ...),
    GoRoute(path: '/register', builder: ...),
  ],
));
```

---

## Decisions

| Date       | Decision                 | Reason                                          |
|------------|--------------------------|-------------------------------------------------|
| 2026-05-01 | Flutter + Riverpod       | DI + state in one package, no InheritedWidget   |
| 2026-05-01 | go_router                | Declarative, deep linking, ShellRoute support   |
| 2026-05-01 | FSD                      | Consistent arch with web — easier to context-switch |
| 2026-05-01 | Dio for HTTP             | Interceptors for auth, retry, error handling    |

---

## Open Questions

- [ ] Push notifications (FCM?) — when a task auto-fails
- [ ] Offline mode — local storage (Hive / SQLite / Isar)?
- [ ] freezed for Task model or plain Dart class?
