# arch/mobile.md

> Load when: Flutter app (apps/mobile) — screens, providers, navigation.

## Stack

Flutter 3 · Riverpod (code-gen) · go_router · Dio

---

## FSD Structure

```
apps/mobile/lib/
  pages/      # Screens: day, week, month, year, backlog, archive, login, register
  widgets/    # app_shell (BottomNavBar/Drawer), task_list
  features/   # create_task, complete_task, replan_task (Notifier pattern)
  entities/
    task/     # task.dart, TaskCard, TaskLevelBadge, AsyncNotifierProvider
  shared/
    ui/       # AppButton, AppModal
    api/      # api_client.dart (Dio + interceptors), tasks_api.dart
    core/     # router.dart (go_router), secure_storage.dart
    theme/
  main.dart
```

Import direction: `pages → widgets → features → entities → shared` — downward only.
Cross-imports via `@x/` files when truly needed.

---

## State (Riverpod)

```dart
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

- `AsyncNotifierProvider` for data with loading/error
- `NotifierProvider` for UI state / filters
- Providers live in `entities/` or `features/` — never in `pages/`

---

## Navigation

go_router with `ShellRoute(builder: AppShell)` wrapping authenticated routes.
Auth guard redirects to `/login` if not authenticated.

---

## Key Decisions

| Decision | Reason |
|----------|--------|
| Riverpod | DI + state in one package |
| go_router | Declarative, deep linking, ShellRoute |
| FSD | Consistent with web — easier to context-switch |
| Dio | Interceptors for auth token injection |

---

## Open Questions

- [ ] Push notifications (FCM) — when task auto-fails
- [ ] Offline mode (Hive / SQLite / Isar)
- [ ] freezed for Task model or plain Dart class?
