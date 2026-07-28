import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/tags_api.dart';
import '../ui/app_toast.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class TagStoreState {
  final List<TagDto> tags;
  final Map<String, List<String>> taskTagsMap; // taskId -> [tagId, ...]
  final Map<String, List<String>> noteTagsMap; // noteId -> [tagId, ...]
  final bool loaded;
  final bool noteTagsLoaded;
  final Set<String> filterTagIds;
  final Set<String> noteFilterTagIds;

  const TagStoreState({
    this.tags = const [],
    this.taskTagsMap = const {},
    this.noteTagsMap = const {},
    this.loaded = false,
    this.noteTagsLoaded = false,
    this.filterTagIds = const {},
    this.noteFilterTagIds = const {},
  });

  TagStoreState copyWith({
    List<TagDto>? tags,
    Map<String, List<String>>? taskTagsMap,
    Map<String, List<String>>? noteTagsMap,
    bool? loaded,
    bool? noteTagsLoaded,
    Set<String>? filterTagIds,
    Set<String>? noteFilterTagIds,
  }) =>
      TagStoreState(
        tags: tags ?? this.tags,
        taskTagsMap: taskTagsMap ?? this.taskTagsMap,
        noteTagsMap: noteTagsMap ?? this.noteTagsMap,
        loaded: loaded ?? this.loaded,
        noteTagsLoaded: noteTagsLoaded ?? this.noteTagsLoaded,
        filterTagIds: filterTagIds ?? this.filterTagIds,
        noteFilterTagIds: noteFilterTagIds ?? this.noteFilterTagIds,
      );

  List<TagDto> getTagsForTask(String taskId) {
    final ids = taskTagsMap[taskId] ?? [];
    if (ids.isEmpty) return const [];
    final tagMap = {for (final t in tags) t.id: t};
    return ids.map((id) => tagMap[id]).whereType<TagDto>().toList();
  }

  List<TagDto> getTagsForNote(String noteId) {
    final ids = noteTagsMap[noteId] ?? [];
    if (ids.isEmpty) return const [];
    final tagMap = {for (final t in tags) t.id: t};
    return ids.map((id) => tagMap[id]).whereType<TagDto>().toList();
  }

  List<String> tagIdsForNote(String noteId) => noteTagsMap[noteId] ?? const [];

  bool get isFiltering => filterTagIds.isNotEmpty;
  bool get isFilteringNotes => noteFilterTagIds.isNotEmpty;

  bool noteMatchesFilter(String noteId) {
    if (noteFilterTagIds.isEmpty) return true;
    final noteTags = noteTagsMap[noteId] ?? const [];
    return noteFilterTagIds.every((fid) => noteTags.contains(fid));
  }

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
  final Ref _ref;

  TagStoreNotifier(this._api, this._ref) : super(const TagStoreState()) {
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

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<void> loadNoteAssignments() async {
    if (state.noteTagsLoaded) return;
    try {
      final assignments = await _api.getAllNoteAssignments();
      final noteTagsMap = <String, List<String>>{};
      final tagMap = {for (final t in state.tags) t.id: t};
      for (final a in assignments) {
        noteTagsMap[a.noteId] = a.tags.map((t) => t.id).toList();
        for (final t in a.tags) {
          tagMap[t.id] = t;
        }
      }
      state = state.copyWith(
        tags: tagMap.values.toList(),
        noteTagsMap: noteTagsMap,
        noteTagsLoaded: true,
      );
    } catch (_) {
      // Non-critical — tags just won't show on rows
    }
  }

  /// Optimistic local update + PUT.
  void setNoteTags(String noteId, List<String> tagIds) {
    state = state.copyWith(
      noteTagsMap: {...state.noteTagsMap, noteId: tagIds},
    );
    _api.setNoteTags(noteId, tagIds).catchError((_) {
      _ref.read(appToastProvider.notifier).show('Не удалось сохранить теги заметки');
    });
  }

  void toggleNoteFilterTag(String id) {
    final next = Set<String>.from(state.noteFilterTagIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(noteFilterTagIds: next);
  }

  void clearNoteFilter() {
    state = state.copyWith(noteFilterTagIds: const {});
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final tagStoreProvider =
    StateNotifierProvider<TagStoreNotifier, TagStoreState>((ref) {
  return TagStoreNotifier(ref.watch(tagsApiProvider), ref);
});
