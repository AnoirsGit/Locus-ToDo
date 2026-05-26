import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/task.dart';
import 'api_client.dart';

class TasksApi {
  final ApiClient _client;

  TasksApi(this._client);

  Future<List<TaskWithPeriod>> fetchTasks({String? view}) async {
    final res = await _client.get(
      '/tasks',
      queryParameters: view != null ? {'view': view} : null,
    );
    return (res.data as List).map((j) => TaskWithPeriod.fromJson(j)).toList();
  }

  Future<void> toggleTask(String periodId, TaskStatus status) async {
    await _client.patch('/task-periods/$periodId', data: {'status': status.name});
  }

  Future<TaskWithPeriod> createTask(Map<String, dynamic> data) async {
    final res = await _client.post('/tasks', data: data);
    return TaskWithPeriod.fromJson(res.data);
  }

  Future<List<TaskWithPeriod>> getSubtasks(String taskId) async {
    final res = await _client.get('/tasks/$taskId/subtasks');
    return (res.data as List).map((j) => TaskWithPeriod.fromJson(j)).toList();
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _client.patch('/tasks/$id', data: data);
  }

  Future<void> deleteTask(String id) async {
    await _client.delete('/tasks/$id');
  }

  Future<TaskWithPeriod> replanTask(String taskId, String periodStart) async {
    final res = await _client.post('/tasks/$taskId/replan', data: {'periodStart': periodStart});
    return TaskWithPeriod.fromJson(res.data);
  }
}

final tasksApiProvider =
    Provider((ref) => TasksApi(ref.watch(apiClientProvider)));
