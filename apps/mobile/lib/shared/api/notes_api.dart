import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ── UUID helper ───────────────────────────────────────────────────────────────

String generateUuid() {
  final r = Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int n) => n.toRadixString(16).padLeft(2, '0');
  return '${b.sublist(0, 4).map(hex).join()}-'
      '${b.sublist(4, 6).map(hex).join()}-'
      '${b.sublist(6, 8).map(hex).join()}-'
      '${b.sublist(8, 10).map(hex).join()}-'
      '${b.sublist(10, 16).map(hex).join()}';
}

// ── DTO ───────────────────────────────────────────────────────────────────────

class NoteDto {
  final String id;
  final String? parentId;
  final String content;
  final bool collapsed;
  final int sortOrder;
  final List<NoteDto> children;

  const NoteDto({
    required this.id,
    this.parentId,
    required this.content,
    required this.collapsed,
    required this.sortOrder,
    required this.children,
  });

  factory NoteDto.fromJson(Map<String, dynamic> j) => NoteDto(
        id: j['id'] as String,
        parentId: j['parentId'] as String?,
        content: j['content'] as String? ?? '',
        collapsed: j['collapsed'] as bool? ?? false,
        sortOrder: j['sortOrder'] as int? ?? 0,
        children: (j['children'] as List<dynamic>? ?? [])
            .map((c) => NoteDto.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

// ── API ───────────────────────────────────────────────────────────────────────

class NotesApi {
  final ApiClient _client;
  const NotesApi(this._client);

  Future<List<NoteDto>> list() async {
    final res = await _client.get<List<dynamic>>('/notes');
    return (res.data ?? [])
        .map((e) => NoteDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoteDto> create({
    required String id,
    String? parentId,
    required String content,
    required int sortOrder,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/notes', data: {
      'id': id,
      'parentId': parentId,
      'content': content,
      'sortOrder': sortOrder,
    });
    return NoteDto.fromJson(res.data!);
  }

  Future<void> update(
    String id, {
    String? content,
    bool? collapsed,
    String? parentId,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (collapsed != null) body['collapsed'] = collapsed;
    if (parentId != null) body['parentId'] = parentId;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    await _client.patch<void>('/notes/$id', data: body);
  }

  Future<void> delete(String id) => _client.delete<void>('/notes/$id');
}

final notesApiProvider = Provider((ref) => NotesApi(ref.watch(apiClientProvider)));
