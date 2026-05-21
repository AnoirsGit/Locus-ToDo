import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/tags_api.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class TagStoreState {
  final List<TagDto> tags;
  final Map<String, List<String>> taskTagsMap; // taskId -> [tagId, ...]
  final bool loaded;

  const TagStoreState({
    this.tags = const [],
    this.taskTagsMap = const {},
    this.loaded = false,
  });

  TagStoreState copyWith({
    List<TagDto>? tags,
    Map<String, List<String>>? taskTagsMap,
    bool? loaded,
  }) =>
      TagStoreState(
        tags: tags ?? this.tags,
        taskTagsMap: taskTagsMap ?? this.taskTagsMap,
        loaded: loaded ?? this.loaded,
      );

  List<TagDto> getTagsForTask(String taskId) {
    final ids = taskTagsMap[taskId] ?? [];
    if (ids.isEmpty) return const [];
    final tagMap = {for (final t in tags) t.id: t};
    return ids.map((id) => tagMap[id]).whereType<TagDto>().toList();
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class TagStoreNotifier extends StateNotifier<TagStoreState> {
  final TagsApi _api;

  TagStoreNotifier(this._api) : super(const TagStoreState()) {
    load();
  }

  Future<void> load() async {
    if (state.loaded) return;
    try {
      final tags = await _api.list();
      final assignments = await _api.getAllTaskAssignments();

      final taskTagsMap = <String, List<String>>{};
      final tagMap = {for (final t in tags) t.id: t};

      for (final a in assignments) {
        taskTagsMap[a.taskId] = a.tags.map((t) => t.id).toList();
        for (final t in a.tags) {
          tagMap[t.id] = t;
        }
      }

      state = TagStoreState(
        tags: tagMap.values.toList(),
        taskTagsMap: taskTagsMap,
        loaded: true,
      );
    } catch (_) {
      // Fail silently — tags are non-critical
    }
  }

  void setTaskTagsLocal(String taskId, List<String> tagIds) {
    state = state.copyWith(
      taskTagsMap: {...state.taskTagsMap, taskId: tagIds},
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final tagStoreProvider =
    StateNotifierProvider<TagStoreNotifier, TagStoreState>((ref) {
  return TagStoreNotifier(ref.watch(tagsApiProvider));
});
