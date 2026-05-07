import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/tasks_api.dart';
import 'task.dart';

class TasksNotifier extends AsyncNotifier<List<TaskWithPeriod>> {
  final String? view;

  TasksNotifier({this.view});

  @override
  Future<List<TaskWithPeriod>> build() async {
    return ref.read(tasksApiProvider).fetchTasks(view: view);
  }

  Future<void> toggle(TaskWithPeriod task) async {
    final newStatus =
        task.period.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;

    // Optimistic update
    final prev = state;
    if (state.hasValue) {
      state = AsyncData(state.value!.map((t) {
        if (t.period.id != task.period.id) return t;
        return t.copyWithPeriod(t.period.copyWith(
          status: newStatus,
          doneAt: newStatus == TaskStatus.done ? DateTime.now() : null,
        ));
      }).toList());
    }

    try {
      await ref.read(tasksApiProvider).toggleTask(task.period.id, newStatus);
    } catch (_) {
      state = prev;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksApiProvider).fetchTasks(view: view),
    );
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    await ref.read(tasksApiProvider).createTask(data);
    await refresh();
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await ref.read(tasksApiProvider).updateTask(id, data);
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    await ref.read(tasksApiProvider).deleteTask(id);
    if (state.hasValue) {
      state = AsyncData(state.value!.where((t) => t.id != id).toList());
    }
  }
}

// Family provider — один на каждый view (day/week/month/year/backlog/archive)
final tasksNotifierProvider = AsyncNotifierProviderFamily<TasksNotifier,
    List<TaskWithPeriod>, String?>(() => TasksNotifier());
