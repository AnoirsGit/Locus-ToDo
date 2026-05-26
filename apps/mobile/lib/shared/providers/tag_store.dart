import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/tags_api.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class TagStoreState {
  final List<TagDto> tags;
  final Map<String, List<String>> taskTagsMap; // taskId -> [tagId, ...]
  final bool loaded;
  final Set<String> filterTagIds;

  const TagStoreState({
    this.tags = const [],
    this.taskTagsMap = const {},
    this.loaded = false,
    this.filterTagIds = const {},
  });

  TagStoreState copyWith({
    List<TagDto>? tags,
    Map<String, List<String>>? taskTagsMap,
    bool? loaded,
    Set<String>? filterTagIds,
  }) =>
      TagStoreState(
        tags: tags ?? this.tags,
        taskTagsMap: taskTagsMap ?? this.taskTagsMap,
        loaded: loaded ?? this.loaded,
        filterTagIds: filterTagIds ?? this.filterTagIds,
      );

  List<TagDto> getTagsForTask(String taskId) {
    final ids = taskTagsMap[taskId] ?? [];
    if (ids.isEmpty) return const [];
    final tagMap = {for (final t in tags) t.id: t};
    return ids.map((id) => tagMap[id]).whereType<TagDto>().toList();
  }

  bool get isFiltering => filterTagIds.isNotEmpty;

  List<T> filterTasks<T extends Object>(
    List<T> tasks,
    String Function(T) getId,
  ) {
    if (filterTagIds.isEmpty) return tasks;
    return tasks.where((t) {
      final taskTags = taskTagsMap[getId(t)] ?? [];
      return filterTagIds.every((fid) => taskTags.contains(fid));
    }).toList();
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
    await _fetchAll();
  }

  Future<void> reload() async {
    state = state.copyWith(loaded: false);
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
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

      state = state.copyWith(
        tags: tagMap.values.toList(),
        taskTagsMap: taskTagsMap,
        loaded: true,
      );
    } catch (_) {
      // Non-critical
    }
  }

  void setTaskTagsLocal(String taskId, List<String> tagIds) {
    state = state.copyWith(
      taskTagsMap: {...state.taskTagsMap, taskId: tagIds},
    );
  }

  void toggleFilterTag(String id) {
    final next = Set<String>.from(state.filterTagIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(filterTagIds: next);
  }

  void clearFilter() {
    state = state.copyWith(filterTagIds: const {});
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final tagStoreProvider =
    StateNotifierProvider<TagStoreNotifier, TagStoreState>((ref) {
  return TagStoreNotifier(ref.watch(tagsApiProvider));
});
