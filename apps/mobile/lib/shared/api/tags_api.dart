import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ── DTO ───────────────────────────────────────────────────────────────────────

class TagDto {
  final String id;
  final String name;
  final String? color;

  const TagDto({required this.id, required this.name, this.color});

  factory TagDto.fromJson(Map<String, dynamic> j) => TagDto(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as String?,
      );
}

class TaskTagAssignment {
  final String taskId;
  final List<TagDto> tags;

  const TaskTagAssignment({required this.taskId, required this.tags});

  factory TaskTagAssignment.fromJson(Map<String, dynamic> j) => TaskTagAssignment(
        taskId: j['taskId'] as String,
        tags: (j['tags'] as List<dynamic>)
            .map((t) => TagDto.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

// ── API ───────────────────────────────────────────────────────────────────────

class TagsApi {
  final ApiClient _client;
  const TagsApi(this._client);

  Future<List<TagDto>> list() async {
    final res = await _client.get<List<dynamic>>('/tags');
    return (res.data ?? [])
        .map((e) => TagDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TaskTagAssignment>> getAllTaskAssignments() async {
    final res = await _client.get<List<dynamic>>('/tags/task-assignments');
    return (res.data ?? [])
        .map((e) => TaskTagAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TagDto>> getTaskTags(String taskId) async {
    final res = await _client.get<List<dynamic>>('/tags/tasks/$taskId');
    return (res.data ?? [])
        .map((e) => TagDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setTaskTags(String taskId, List<String> tagIds) async {
    await _client.put<void>('/tags/tasks/$taskId', data: {'tagIds': tagIds});
  }

  Future<TagDto> create(String name, {String? color}) async {
    final res = await _client.post<Map<String, dynamic>>('/tags', data: {
      'name': name,
      if (color != null) 'color': color,
    });
    return TagDto.fromJson(res.data!);
  }

  Future<void> delete(String id) => _client.delete<void>('/tags/$id');
}

final tagsApiProvider = Provider((ref) => TagsApi(ref.watch(apiClientProvider)));
