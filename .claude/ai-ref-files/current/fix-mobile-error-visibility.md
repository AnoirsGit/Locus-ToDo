# B4 — Mobile errors are swallowed silently (fix)

> Branch: `fix/mobile-error-visibility`. Closes `bugs.md` B4. No DB/schema changes.
> Source bug: `tasks_notifier.dart`, `sync_worker.dart`, notes notifier all `catch (_) {}`;
> no `ScaffoldMessenger` anywhere; outbox has zero user visibility.

## Findings (from code audit)

- **Live mutation path = `GroupedTasksNotifier`** (online, direct API). Its callers in
  `view_tab_page.dart` / `tasks_page.dart` are **fire-and-forget** (no await/catch) →
  a failed create/update/delete/replan/toggle vanishes. This is the main toast target.
- `tasksNotifierProvider` (offline, outbox-backed) is **unused** in the UI — the task
  `syncOutbox` is effectively never written today. Notes ARE offline-first via
  `OfflineNotesApi` → `notesOutbox` (queues on failure, never throws).
- Offline-first paths (notes mutations, offline toggle) must surface via the **outbox
  badge**, NOT toasts — a queued op is expected behavior, not an error to nag about.
- `S` (ru/en string table) already exists at `shared/core/strings.dart`.
- No `scaffoldMessengerKey` on `MaterialApp.router` yet.

## Plan

### 1. Global toast service
- [x] `shared/ui/app_toast.dart`: `appMessengerKey` (`GlobalKey<ScaffoldMessengerState>`)
      + `AppToast.error/success/info(msg)` — SnackBar via the key, no `BuildContext`
      needed (callable from notifiers). Color-coded, floating. Mirrors web `toastStore`.
- [x] `main.dart`: `scaffoldMessengerKey: appMessengerKey` on `MaterialApp.router`.

### 2. Strings (ru/en) in `S`
- [x] `errorSaveFailed`, `errorDeleteFailed`, `errorTaskHasArchive` (409 parity w/ web B2),
      `errorGeneric`; `syncTitle`, `syncAllSynced`, `syncPending(n)`, `syncNow`.

### 3. Wire user-facing mutation error paths
- [x] `GroupedTasksNotifier`: try/catch each of createTask/updateTask/deleteTask/replan/
      toggle. On failure → `AppToast.error(...)` + `refresh()` to reconcile. `toggle`
      rolls back the optimistic flip. `deleteTask` 409 → `errorTaskHasArchive`. Skip
      toast on 401 (interceptor already redirects).
- [x] `task_form_sheet.dart`: subtask add/toggle/delete `catch (_) {}` → toast (toggle/
      delete already roll back locally).
- [x] Tags: settings create/delete + form `setTaskTags` + `setNoteTags` → toast on failure.
- [x] Notes: deliberately NOT toasted — `OfflineNotesApi` queues on failure (offline-first),
      surfaced via the sync badge instead.

### 4. Outbox visibility (badge)
- [x] `app_database.dart`: `watchPendingSyncCount()` — reactive count of `sync_outbox` +
      `notes_outbox` via `customSelect` (all rows, ignoring `nextRetryAt`).
- [x] `pendingSyncCountProvider` (StreamProvider<int>).
- [x] `settings_page.dart`: "Sync" section — `syncAllSynced` when 0, else `syncPending(n)`
      + `syncNow` button (flush both workers; stream auto-clears).

## Bonus: B3 mobile half (refetch on app resume)

Deferred `bugs.md` B3 mobile item, done here since it touches the same area.
- [x] `app_shell.dart`: `AppShell` → `ConsumerStatefulWidget` with `WidgetsBindingObserver`
      (shell State persists across tab routes under `ShellRoute`). On
      `AppLifecycleState.resumed`, throttled ≥60 s: `ref.invalidate(groupedTasksProvider)`
      + `ref.invalidate(notesProvider)` (active view refetches, local "today"/week window
      recomputes on rebuild) + flush both outboxes (resume = connectivity likely returns).
- [x] Removed a dead `theme.dart` import while in the file.
- Skipped B1 mobile (`date_utils.dart`): mobile already computes local "today"; pure dedup.

## Verification (Prove It)
- [x] `flutter analyze` clean (no new issues; 3 pre-existing warnings in untouched files).
- [ ] Kill API → create/toggle a task on view-tab → error toast appears; UI reconciles. (needs emulator + API)
- [ ] Kill API → edit a note → Settings shows "N changes pending sync"; restart API +
      "Sync now" → count clears. (needs emulator + API)
- [ ] Background the app across an hourly scheduler tick → resume → statuses/today refresh. (needs emulator + API)
