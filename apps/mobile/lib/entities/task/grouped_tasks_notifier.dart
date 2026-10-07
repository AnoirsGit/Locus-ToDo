import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/tasks_api.dart';
import '../../shared/core/strings.dart';
import '../../shared/ui/app_toast.dart';
import 'task.dart';

class GroupedTasks {
  final List<TaskWithPeriod> primary;
  final List<TaskWithPeriod> week;
  final List<TaskWithPeriod> month;
  final List<TaskWithPeriod> year;

  const GroupedTasks({
    required this.primary,
    this.week = const [],
    this.month = const [],
    this.year = const [],
  });

  bool get hasContext => week.isNotEmpty || month.isNotEmpty || year.isNotEmpty;
}

/// Context levels to fetch alongside the primary view.
List<String> _contextLevels(String view) {
  switch (view) {
    case 'day':   return ['week', 'month', 'year'];
    case 'week':  return ['month', 'year'];
    case 'month': return ['year'];
    default:      return [];
  }
}

class GroupedTasksNotifier extends FamilyAsyncNotifier<GroupedTasks, String> {
  TasksApi get _api => ref.read(tasksApiProvider);

  @override
  Future<GroupedTasks> build(String arg) async {
    // Backlog / archive: flat list, no context sections.
    if (arg == 'backlog' || arg == 'archive') {
      final primary = await _api.fetchTasks(view: arg);
      return GroupedTasks(primary: primary);
    }

    final ctx = _contextLevels(arg);

    // Fetch primary + context levels concurrently.
    final futures = <Future<List<TaskWithPeriod>>>[
      _api.fetchTasks(view: arg),
      ...ctx.map((l) => _api.fetchTasks(view: l)),
    ];

    final results = await Future.wait(futures);

    List<TaskWithPeriod> _for(String level) {
      final i = ctx.indexOf(level);
      return i >= 0 ? results[i + 1] : [];
    }

    return GroupedTasks(
      primary: results[0],
      week:    _for('week'),
      month:   _for('month'),
      year:    _for('year'),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }

  // B4: this is the notifier the pages mutate through, and they call it
  // fire-and-forget (the form sheet has already closed), so every failure
  // must end here as a toast — otherwise it is an unhandled, invisible error.

  Future<void> createTask(Map<String, dynamic> data) async {
    try {
      await _api.createTask(data);
    } catch (_) {
      _toast(S.taskCreateFailed);
      return;
    }
    await refresh();
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await _api.updateTask(id, data);
    } catch (_) {
      _toast(S.taskSaveFailed);
      return;
    }
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    try {
      await _api.deleteTask(id);
    } catch (e) {
      // 409 = the task has archived periods and can't be deleted (as on web).
      final hasArchive = e is DioException && e.response?.statusCode == 409;
      _toast(hasArchive ? S.taskDeleteArchivedError : S.taskDeleteFailed);
      return;
    }
    await refresh();
  }

  Future<void> replan(String taskId, String periodStart) async {
    try {
      await _api.replanTask(taskId, periodStart);
    } catch (_) {
      _toast(S.replanFailed);
      return;
    }
    await refresh();
  }

  Future<void> toggle(TaskWithPeriod task) async {
    final newStatus = task.period.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;
    final doneAt = newStatus == TaskStatus.done ? DateTime.now() : null;

    // Optimistic update
    _replacePeriod(task.period.id, (p) => p.copyWith(status: newStatus, doneAt: doneAt));

    try {
      await _api.toggleTask(task.period.id, newStatus);
    } catch (_) {
      // Roll back to the period as it was before the tap (the server never
      // saw the change), so the checkbox doesn't lie until the next refetch.
      _replacePeriod(task.period.id, (_) => task.period);
      _toast(S.taskSaveFailed);
    }
  }

  void _replacePeriod(String periodId, TaskPeriod Function(TaskPeriod) update) {
    if (!state.hasValue) return;
    final v = state.value!;
    TaskWithPeriod upd(TaskWithPeriod t) =>
        t.period.id == periodId ? t.copyWithPeriod(update(t.period)) : t;
    state = AsyncData(GroupedTasks(
      primary: v.primary.map(upd).toList(),
      week:    v.week.map(upd).toList(),
      month:   v.month.map(upd).toList(),
      year:    v.year.map(upd).toList(),
    ));
  }

  void _toast(String message) => ref.read(appToastProvider.notifier).show(message);
}

final groupedTasksProvider = AsyncNotifierProviderFamily<GroupedTasksNotifier, GroupedTasks, String>(
  GroupedTasksNotifier.new,
);
