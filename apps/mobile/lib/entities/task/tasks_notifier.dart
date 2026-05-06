import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../shared/api/tasks_api.dart';
import 'task.dart';

part 'tasks_notifier.g.dart';

@riverpod
class TasksNotifier extends _$TasksNotifier {
  @override
  Future<List<TaskWithPeriod>> build({String? view}) async {
    return ref.read(tasksApiProvider).fetchTasks(view: view);
  }

  Future<void> toggle(TaskWithPeriod task) async {
    final newStatus = task.period.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;
    
    // Optimistic update
    final previousState = state;
    if (state.hasValue) {
      final updatedTasks = state.value!.map((t) {
        if (t.period.id == task.period.id) {
          // We can't easily mutate because it's final, but for demonstration:
          // In a real app we'd use copyWith
          return task; // This is a placeholder for optimistic UI
        }
        return t;
      }).toList();
      // state = AsyncValue.data(updatedTasks);
    }

    try {
      await ref.read(tasksApiProvider).toggleTask(task.period.id, newStatus);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
