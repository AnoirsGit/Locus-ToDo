import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/tasks_api.dart';
import '../../shared/db/app_database.dart';
import '../../shared/db/local_task_repository.dart';
import '../../shared/sync/sync_worker.dart';
import '../../shared/notifications/notification_service.dart';
import '../../shared/notifications/notification_prefs.dart';
import 'task.dart';

class TasksNotifier extends AsyncNotifier<List<TaskWithPeriod>> {
  final String? view;
  TasksNotifier({this.view});

  AppDatabase       get _db     => ref.read(appDatabaseProvider);
  LocalTaskRepository get _local => ref.read(localTaskRepositoryProvider);
  TasksApi          get _api    => ref.read(tasksApiProvider);
  SyncWorker        get _sync   => ref.read(syncWorkerProvider);

  @override
  Future<List<TaskWithPeriod>> build() async {
    // 1. Show local data immediately (no spinner if cached)
    final cached = await _local.getActiveTasks();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    // 2. Flush any pending outbox items
    await _sync.flush();

    // 3. Fetch from API and refresh local cache
    try {
      final fresh = await _api.fetchTasks(view: view);
      await _local.saveTasksWithPeriods(fresh);

      // 4. Reschedule notifications with fresh data
      final prefs = await ref.read(notificationPrefsProvider.future);
      NotificationService.rescheduleAll(fresh, prefs);

      return fresh;
    } catch (_) {
      // Network unavailable — return cached data (already set above)
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Toggle done/todo — offline-first with outbox
  Future<void> toggle(TaskWithPeriod task) async {
    final newStatus = task.period.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;
    final doneAt = newStatus == TaskStatus.done ? DateTime.now() : null;

    // 1. Optimistic update in memory
    _applyOptimistic(task.period.id, newStatus, doneAt);

    // 2. Persist to local DB immediately
    await _local.updatePeriodStatus(task.period.id, newStatus, doneAt);

    // 3. Enqueue in outbox
    final outboxId = '${task.period.id}_${DateTime.now().millisecondsSinceEpoch}';
    await _db.enqueueToggle(
      id: outboxId,
      periodId: task.period.id,
      status: newStatus.name,
      doneAt: doneAt,
    );

    // 4. Try to flush immediately (fire-and-forget)
    _sync.flush();
  }

  void _applyOptimistic(String periodId, TaskStatus status, DateTime? doneAt) {
    if (!state.hasValue) return;
    state = AsyncData(state.value!.map((t) {
      if (t.period.id != periodId) return t;
      return t.copyWithPeriod(t.period.copyWith(status: status, doneAt: doneAt));
    }).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    await _api.createTask(data);
    await refresh();
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _api.updateTask(id, data);
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    await _api.deleteTask(id);
    if (state.hasValue) {
      state = AsyncData(state.value!.where((t) => t.id != id).toList());
    }
  }
}

final tasksNotifierProvider = AsyncNotifierProviderFamily<TasksNotifier,
    List<TaskWithPeriod>, String?>(() => TasksNotifier());
