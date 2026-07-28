import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import 'notes_api.dart';

// Sentinel so nullable fields (parentId, url) can be set to null explicitly,
// mirroring NotesApi.update.
const Object _absent = Object();

/// Local mirror used by [OfflineNotesApi]. Abstracted so tests can inject an
/// in-memory store instead of the Drift-backed [LocalNoteRepository].
abstract interface class NoteLocalStore {
  Future<void> cacheTree(List<NoteDto> tree);
  Future<List<NoteDto>> loadTree();
  Future<void> upsertFromDto(NoteDto n);
  Future<void> upsertCreate(Map<String, dynamic> body);
  Future<void> applyUpdate(String id, Map<String, dynamic> body);
  Future<void> deleteLocal(String id);
  Future<void> enqueue(String op, String noteId, Map<String, dynamic>? payload);
}

/// Local mirror of the notes tree + a pending-op outbox (Drift-backed).
class LocalNoteRepository implements NoteLocalStore {
  final AppDatabase _db;
  const LocalNoteRepository(this._db);

  NotesCompanion _companion(NoteDto n) => NotesCompanion(
        id: Value(n.id),
        parentId: Value(n.parentId),
        nodeType: Value(n.nodeType),
        content: Value(n.content),
        url: Value(n.url),
        sortOrder: Value(n.sortOrder),
        collapsed: Value(n.collapsed),
        done: Value(n.done),
        updatedAt: Value(DateTime.now()),
      );

  /// Replace the whole local cache with a freshly-fetched tree.
  @override
  Future<void> cacheTree(List<NoteDto> tree) async {
    final rows = <NotesCompanion>[];
    void walk(List<NoteDto> nodes) {
      for (final n in nodes) {
        rows.add(_companion(n));
        walk(n.children);
      }
    }
    walk(tree);
    await _db.replaceAllNotes(rows);
  }

  /// Rebuild the nested tree from the flat local rows.
  @override
  Future<List<NoteDto>> loadTree() async {
    final rows = await _db.getAllNotes();
    final byParent = <String?, List<Note>>{};
    for (final r in rows) {
      (byParent[r.parentId] ??= []).add(r);
    }
    List<NoteDto> build(String? parentId) {
      final children = [...?byParent[parentId]]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return children
          .map((r) => NoteDto(
                id: r.id,
                parentId: r.parentId,
                nodeType: r.nodeType,
                content: r.content,
                url: r.url,
                collapsed: r.collapsed,
                done: r.done,
                sortOrder: r.sortOrder,
                children: build(r.id),
              ))
          .toList();
    }

    return build(null);
  }

  @override
  Future<void> upsertFromDto(NoteDto n) => _db.upsertNote(_companion(n));

  @override
  Future<void> upsertCreate(Map<String, dynamic> body) => _db.upsertNote(NotesCompanion(
        id: Value(body['id'] as String),
        parentId: Value(body['parentId'] as String?),
        nodeType: Value(body['nodeType'] as String? ?? 'bullet'),
        content: Value(body['content'] as String? ?? ''),
        url: Value(body['url'] as String?),
        sortOrder: Value(body['sortOrder'] as int? ?? 0),
        collapsed: const Value(false),
        done: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  @override
  Future<void> applyUpdate(String id, Map<String, dynamic> body) {
    bool has(String k) => body.containsKey(k);
    final c = NotesCompanion(
      nodeType: has('nodeType') ? Value(body['nodeType'] as String) : const Value.absent(),
      content: has('content') ? Value(body['content'] as String) : const Value.absent(),
      url: has('url') ? Value(body['url'] as String?) : const Value.absent(),
      sortOrder: has('sortOrder') ? Value(body['sortOrder'] as int) : const Value.absent(),
      collapsed: has('collapsed') ? Value(body['collapsed'] as bool) : const Value.absent(),
      done: has('done') ? Value(body['done'] as bool) : const Value.absent(),
      parentId: has('parentId') ? Value(body['parentId'] as String?) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(c);
  }

  @override
  Future<void> deleteLocal(String id) => _db.deleteNoteLocal(id);

  @override
  Future<void> enqueue(String op, String noteId, Map<String, dynamic>? payload) =>
      _db.enqueueNoteOp(NotesOutboxCompanion(
        id: Value(generateUuid()),
        op: Value(op),
        noteId: Value(noteId),
        payloadJson: Value(payload != null ? jsonEncode(payload) : null),
        createdAt: Value(DateTime.now()),
        attempts: const Value(0),
        nextRetryAt: Value(DateTime.now()),
      ));
}

/// Network-first notes API with a local cache + outbox fallback. Same public
/// surface as [NotesApi] so [NotesNotifier] uses it unchanged.
///
/// [create]/[update]/[delete] never rethrow network failures — they queue
/// the op into [NoteLocalStore.enqueue] and return normally, so callers'
/// `.catchError(...)` only fires for local (Drift) write failures, not for
/// being offline. Pending/stuck syncs are surfaced separately via
/// `noteOutboxCountProvider`/`failedNoteOutboxCountProvider` (see
/// `shared/sync/notes_sync_worker.dart`), not as a per-action error toast —
/// offline queuing is expected behavior, not a failure.
class OfflineNotesApi {
  final NotesApi _api;
  final NoteLocalStore _local;

  const OfflineNotesApi(this._api, this._local);

  Future<List<NoteDto>> list() async {
    try {
      final remote = await _api.list();
      await _local.cacheTree(remote);
      return remote;
    } catch (_) {
      return _local.loadTree(); // offline: serve last-known tree
    }
  }

  Future<NoteDto> create({
    required String id,
    String? parentId,
    String nodeType = 'text',
    required String content,
    String? url,
    required int sortOrder,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'parentId': parentId,
      'nodeType': nodeType,
      'content': content,
      if (url != null) 'url': url,
      'sortOrder': sortOrder,
    };
    await _local.upsertCreate(body);
    try {
      final res = await _api.create(
        id: id, parentId: parentId, nodeType: nodeType,
        content: content, url: url, sortOrder: sortOrder,
      );
      await _local.upsertFromDto(res);
      return res;
    } catch (_) {
      await _local.enqueue('create', id, body);
      return NoteDto(
        id: id, parentId: parentId, nodeType: nodeType, content: content,
        url: url, collapsed: false, done: false, sortOrder: sortOrder, children: const [],
      );
    }
  }

  Future<void> update(
    String id, {
    String? nodeType,
    String? content,
    bool? collapsed,
    bool? done,
    Object? parentId = _absent,
    Object? url = _absent,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (nodeType != null) body['nodeType'] = nodeType;
    if (content != null) body['content'] = content;
    if (collapsed != null) body['collapsed'] = collapsed;
    if (done != null) body['done'] = done;
    if (!identical(parentId, _absent)) body['parentId'] = parentId as String?;
    if (!identical(url, _absent)) body['url'] = url as String?;
    if (sortOrder != null) body['sortOrder'] = sortOrder;

    await _local.applyUpdate(id, body);
    try {
      await _api.patchRaw(id, body);
    } catch (_) {
      await _local.enqueue('update', id, body);
    }
  }

  Future<void> delete(String id) async {
    await _local.deleteLocal(id);
    try {
      await _api.delete(id);
    } catch (_) {
      await _local.enqueue('delete', id, null);
    }
  }
}

final localNoteRepositoryProvider =
    Provider((ref) => LocalNoteRepository(ref.watch(appDatabaseProvider)));

final offlineNotesApiProvider = Provider(
  (ref) => OfflineNotesApi(
    ref.watch(notesApiProvider),
    ref.watch(localNoteRepositoryProvider),
  ),
);
