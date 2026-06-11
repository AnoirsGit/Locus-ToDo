import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/notes_api.dart';
import 'note_node.dart';

class NotesNotifier extends AsyncNotifier<List<NoteNode>> {
  late NotesApi _api;
  final Map<String, Timer> _debounceTimers = {};

  @override
  Future<List<NoteNode>> build() async {
    _api = ref.read(notesApiProvider);
    final dtos = await _api.list();
    return dtos.map(NoteNode.fromDto).toList();
  }

  List<NoteNode> get _nodes => state.value ?? [];

  // ── Tree helpers ─────────────────────────────────────────────────────────

  List<NoteNode> _mapNodes(
    List<NoteNode> nodes,
    String id,
    NoteNode Function(NoteNode) fn,
  ) =>
      nodes
          .map((n) => n.id == id
              ? fn(n)
              : n.copyWith(children: _mapNodes(n.children, id, fn)))
          .toList();

  List<NoteNode> _removeNode(List<NoteNode> nodes, String id) => nodes
      .where((n) => n.id != id)
      .map((n) => n.copyWith(children: _removeNode(n.children, id)))
      .toList();

  NoteNode? _findNode(List<NoteNode> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final found = _findNode(n.children, id);
      if (found != null) return found;
    }
    return null;
  }

  List<NoteNode>? _findPath(List<NoteNode> nodes, String targetId) {
    for (final n in nodes) {
      if (n.id == targetId) return [n];
      final sub = _findPath(n.children, targetId);
      if (sub != null) return [n, ...sub];
    }
    return null;
  }

  /// (found, parentId) — parentId is null for root-level nodes.
  (bool, String?) _findParent(List<NoteNode> nodes, String id, [String? parent]) {
    for (final n in nodes) {
      if (n.id == id) return (true, parent);
      final sub = _findParent(n.children, id, n.id);
      if (sub.$1) return sub;
    }
    return (false, null);
  }

  List<NoteNode> _siblingsOf(String? parentId) =>
      parentId == null ? _nodes : (_findNode(_nodes, parentId)?.children ?? []);

  Iterable<String> _subtreeIds(NoteNode node) sync* {
    yield node.id;
    for (final child in node.children) {
      yield* _subtreeIds(child);
    }
  }

  // ── Computed views ────────────────────────────────────────────────────────

  List<NoteNode> visibleRoots(String? rootId) {
    if (rootId == null) return _nodes;
    return _findNode(_nodes, rootId)?.children ?? [];
  }

  List<({String id, String content})> breadcrumbs(String? rootId) {
    if (rootId == null) return [];
    final path = _findPath(_nodes, rootId);
    return path?.map((n) => (id: n.id, content: n.content)).toList() ?? [];
  }

  ({int index, int count, bool isRoot})? siblingInfo(String id) {
    final (found, parentId) = _findParent(_nodes, id);
    if (!found) return null;
    final siblings = _siblingsOf(parentId);
    return (
      index: siblings.indexWhere((n) => n.id == id),
      count: siblings.length,
      isRoot: parentId == null,
    );
  }

  int descendantCount(String id) {
    final node = _findNode(_nodes, id);
    return node == null ? 0 : _subtreeIds(node).length - 1;
  }

  /// Case-insensitive content search over the whole tree, with breadcrumb paths.
  List<({String id, String content, String path})> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <({String id, String content, String path})>[];
    void walk(List<NoteNode> nodes, List<String> ancestors) {
      for (final n in nodes) {
        if (n.content.toLowerCase().contains(q)) {
          results.add((id: n.id, content: n.content, path: ancestors.join(' › ')));
        }
        if (n.children.isNotEmpty) {
          walk(n.children, [...ancestors, n.content.isEmpty ? 'Untitled' : n.content]);
        }
      }
    }
    walk(_nodes, const []);
    return results;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void toggleCollapse(String id) {
    final target = _findNode(_nodes, id);
    if (target == null) return;
    final collapsed = !target.collapsed;
    state = AsyncData(_mapNodes(_nodes, id, (n) => n.copyWith(collapsed: collapsed)));
    _api.update(id, collapsed: collapsed).catchError((_) {});
  }

  void addChild(String parentId) {
    final fresh = NoteNode(id: generateUuid(), type: NoteNodeType.bullet);
    final parentNode = _findNode(_nodes, parentId);
    final sortOrder = (parentNode?.children.length ?? 0) * 10;

    state = AsyncData(_mapNodes(_nodes, parentId, (n) => n.copyWith(
          collapsed: false,
          children: [...n.children, fresh],
        )));

    _api
        .create(id: fresh.id, parentId: parentId, nodeType: fresh.type.api, content: '', sortOrder: sortOrder)
        .ignore();
  }

  void addRoot({String? underRootId}) {
    if (underRootId != null) {
      addChild(underRootId);
      return;
    }
    final fresh = NoteNode(id: generateUuid());
    final sortOrder = _nodes.length * 10;
    state = AsyncData([..._nodes, fresh]);
    _api
        .create(id: fresh.id, parentId: null, nodeType: fresh.type.api, content: '', sortOrder: sortOrder)
        .ignore();
  }

  void addAfter(String id) {
    final (found, parentId) = _findParent(_nodes, id);
    if (!found) return;
    final siblings = _siblingsOf(parentId);
    final idx = siblings.indexWhere((n) => n.id == id);
    final fresh = NoteNode(id: generateUuid(), type: NoteNodeType.bullet);

    if (parentId == null) {
      state = AsyncData([..._nodes]..insert(idx + 1, fresh));
    } else {
      state = AsyncData(_mapNodes(_nodes, parentId, (n) => n.copyWith(
            children: [...n.children]..insert(idx + 1, fresh),
          )));
    }
    _api
        .create(id: fresh.id, parentId: parentId, nodeType: fresh.type.api, content: '', sortOrder: (idx + 1) * 10)
        .ignore();
  }

  void indent(String id) {
    final (found, parentId) = _findParent(_nodes, id);
    if (!found) return;
    final siblings = _siblingsOf(parentId);
    final idx = siblings.indexWhere((n) => n.id == id);
    if (idx < 1) return;

    final node = siblings[idx];
    final prev = siblings[idx - 1];
    final sortOrder = prev.children.length * 10;

    var nodes = _removeNode(_nodes, id);
    nodes = _mapNodes(nodes, prev.id, (n) => n.copyWith(
          collapsed: false,
          children: [...n.children, node],
        ));
    state = AsyncData(nodes);

    _api.update(id, parentId: prev.id, sortOrder: sortOrder).catchError((_) {});
  }

  void unindent(String id) {
    final (found, parentId) = _findParent(_nodes, id);
    if (!found || parentId == null) return;
    final (_, grandParentId) = _findParent(_nodes, parentId);
    final node = _findNode(_nodes, id);
    if (node == null) return;

    var nodes = _removeNode(_nodes, id);
    List<NoteNode> insertAfterParent(List<NoteNode> list) {
      final i = list.indexWhere((n) => n.id == parentId);
      if (i != -1) return [...list]..insert(i + 1, node);
      return list
          .map((n) => n.copyWith(children: insertAfterParent(n.children)))
          .toList();
    }

    nodes = insertAfterParent(nodes);
    state = AsyncData(nodes);

    final gpList = grandParentId == null ? nodes : (_findNode(nodes, grandParentId)?.children ?? []);
    final parentIdx = gpList.indexWhere((n) => n.id == parentId);
    _api.update(id, parentId: grandParentId, sortOrder: (parentIdx + 1) * 10).catchError((_) {});
  }

  void moveUp(String id) => _moveSibling(id, -1);
  void moveDown(String id) => _moveSibling(id, 1);

  /// Flattened move targets, excluding the node's own subtree.
  List<({String id, String label})> moveCandidates(String excludeId) {
    final node = _findNode(_nodes, excludeId);
    final exclude = node == null ? {excludeId} : _subtreeIds(node).toSet();
    final out = <({String id, String label})>[];
    void walk(List<NoteNode> nodes, String prefix) {
      for (final n in nodes) {
        if (exclude.contains(n.id)) continue;
        out.add((id: n.id, label: prefix + (n.content.isEmpty ? 'Untitled' : n.content)));
        walk(n.children, '$prefix· ');
      }
    }
    walk(_nodes, '');
    return out;
  }

  /// Reparent a node to [newParentId] (null = root), appended last.
  void moveToParent(String id, String? newParentId) {
    final node = _findNode(_nodes, id);
    if (node == null) return;
    final exclude = _subtreeIds(node).toSet();
    if (newParentId != null && exclude.contains(newParentId)) return;

    final removed = _removeNode(_nodes, id);
    int sortOrder;
    if (newParentId == null) {
      sortOrder = removed.length * 10;
      state = AsyncData([...removed, node]);
    } else {
      final parent = _findNode(removed, newParentId);
      sortOrder = (parent?.children.length ?? 0) * 10;
      state = AsyncData(_mapNodes(removed, newParentId, (n) => n.copyWith(
            collapsed: false,
            children: [...n.children, node],
          )));
    }
    _api.update(id, parentId: newParentId, sortOrder: sortOrder).catchError((_) {});
  }

  void _moveSibling(String id, int delta) {
    final (found, parentId) = _findParent(_nodes, id);
    if (!found) return;
    final siblings = _siblingsOf(parentId);
    final idx = siblings.indexWhere((n) => n.id == id);
    final target = idx + delta;
    if (idx < 0 || target < 0 || target >= siblings.length) return;

    final reordered = [...siblings];
    final tmp = reordered[idx];
    reordered[idx] = reordered[target];
    reordered[target] = tmp;

    if (parentId == null) {
      state = AsyncData(reordered);
    } else {
      state = AsyncData(_mapNodes(_nodes, parentId, (n) => n.copyWith(children: reordered)));
    }
    for (final i in [idx, target]) {
      _api.update(reordered[i].id, sortOrder: i * 10).catchError((_) {});
    }
  }

  /// Deep-copy a subtree with fresh UUIDs, inserting it right after the source.
  void duplicate(String id) {
    final source = _findNode(_nodes, id);
    final (found, parentId) = _findParent(_nodes, id);
    if (source == null || !found) return;
    final siblings = _siblingsOf(parentId);
    final idx = siblings.indexWhere((n) => n.id == id);

    // Collected parent-first so each child POSTs after its new parent exists.
    final creates = <({String id, String? parentId, String nodeType, String content, String? url, int sortOrder})>[];

    NoteNode cloneSubtree(NoteNode node, String? parent, int sortOrder) {
      final newId = generateUuid();
      creates.add((
        id: newId,
        parentId: parent,
        nodeType: node.type.api,
        content: node.content,
        url: node.url,
        sortOrder: sortOrder,
      ));
      final children = <NoteNode>[];
      for (var i = 0; i < node.children.length; i++) {
        children.add(cloneSubtree(node.children[i], newId, i * 10));
      }
      return NoteNode(
        id: newId,
        type: node.type,
        content: node.content,
        url: node.url,
        collapsed: node.collapsed,
        children: children,
      );
    }

    final clone = cloneSubtree(source, parentId, (idx + 1) * 10);

    if (parentId == null) {
      state = AsyncData([..._nodes]..insert(idx + 1, clone));
    } else {
      state = AsyncData(_mapNodes(_nodes, parentId, (n) => n.copyWith(
            children: [...n.children]..insert(idx + 1, clone),
          )));
    }

    () async {
      for (final c in creates) {
        await _api.create(
          id: c.id,
          parentId: c.parentId,
          nodeType: c.nodeType,
          content: c.content,
          url: c.url,
          sortOrder: c.sortOrder,
        );
      }
    }()
        .catchError((_) {
      state = AsyncData(_removeNode(_nodes, clone.id));
    });
  }

  void updateContent(String id, String content) {
    state = AsyncData(_mapNodes(_nodes, id, (n) => n.copyWith(content: content)));

    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 600), () {
      _api.update(id, content: content).catchError((_) {});
      _debounceTimers.remove(id);
    });
  }

  void updateType(String id, NoteNodeType type) {
    state = AsyncData(_mapNodes(_nodes, id, (n) => n.copyWith(type: type)));
    _api.update(id, nodeType: type.api).catchError((_) {});
  }

  void toggleDone(String id, bool done) {
    state = AsyncData(_mapNodes(_nodes, id, (n) => n.copyWith(done: done)));
    _api.update(id, done: done).catchError((_) {});
  }

  void updateUrl(String id, String? url) {
    final normalized = (url == null || url.trim().isEmpty) ? null : url.trim();
    state = AsyncData(_mapNodes(_nodes, id, (n) => n.copyWith(url: normalized)));
    _api.update(id, url: normalized).catchError((_) {});
  }

  // Cancel pending content saves for the node and all its descendants,
  // otherwise a debounced PATCH can fire after the DELETE and 404.
  void _cancelDebounce(String id) {
    final node = _findNode(_nodes, id);
    final ids = node == null ? [id] : _subtreeIds(node);
    for (final nodeId in ids) {
      _debounceTimers.remove(nodeId)?.cancel();
    }
  }

  void removeNote(String id) {
    _cancelDebounce(id);
    state = AsyncData(_removeNode(_nodes, id));
    _api.delete(id).catchError((_) {});
  }

  void deleteMultiple(Set<String> ids) {
    var nodes = _nodes;
    for (final id in ids) {
      _cancelDebounce(id);
      nodes = _removeNode(nodes, id);
    }
    state = AsyncData(nodes);
    for (final id in ids) {
      _api.delete(id).catchError((_) {});
    }
  }

  // ── Undo for deletes ────────────────────────────────────────────────────────

  ({NoteNode node, String? parentId, int index})? _capture(String id) {
    final node = _findNode(_nodes, id);
    final (found, parentId) = _findParent(_nodes, id);
    if (node == null || !found) return null;
    final siblings = _siblingsOf(parentId);
    return (node: node, parentId: parentId, index: siblings.indexWhere((n) => n.id == id));
  }

  void _restore(List<({NoteNode node, String? parentId, int index})> entries) {
    var nodes = _nodes;
    for (final e in entries) {
      if (e.parentId == null) {
        final arr = [...nodes];
        arr.insert(e.index.clamp(0, arr.length), e.node);
        nodes = arr;
      } else {
        nodes = _mapNodes(nodes, e.parentId!, (n) {
          final ch = [...n.children];
          ch.insert(e.index.clamp(0, ch.length), e.node);
          return n.copyWith(children: ch);
        });
      }
    }
    state = AsyncData(nodes);

    final creates = <({String id, String? parentId, String nodeType, String content, String? url, int sortOrder})>[];
    void collect(NoteNode node, String? parentId, int sortOrder) {
      creates.add((
        id: node.id, parentId: parentId, nodeType: node.type.api,
        content: node.content, url: node.url, sortOrder: sortOrder,
      ));
      for (var i = 0; i < node.children.length; i++) {
        collect(node.children[i], node.id, i * 10);
      }
    }
    for (final e in entries) {
      collect(e.node, e.parentId, e.index * 10);
    }
    () async {
      for (final c in creates) {
        await _api.create(
          id: c.id, parentId: c.parentId, nodeType: c.nodeType,
          content: c.content, url: c.url, sortOrder: c.sortOrder,
        );
      }
    }()
        .catchError((_) {});
  }

  /// Delete a note and return an undo callback (null if capture failed).
  void Function()? removeNoteWithUndo(String id) {
    final entry = _capture(id);
    _cancelDebounce(id);
    state = AsyncData(_removeNode(_nodes, id));
    _api.delete(id).catchError((_) {});
    if (entry == null) return null;
    return () => _restore([entry]);
  }

  /// Delete a selection and return an undo callback (null if nothing captured).
  void Function()? deleteMultipleWithUndo(Set<String> ids) {
    bool hasSelectedAncestor(String id) {
      var (_, p) = _findParent(_nodes, id);
      while (p != null) {
        if (ids.contains(p)) return true;
        p = _findParent(_nodes, p).$2;
      }
      return false;
    }

    final entries = ids
        .where((id) => !hasSelectedAncestor(id))
        .map(_capture)
        .whereType<({NoteNode node, String? parentId, int index})>()
        .toList();

    var nodes = _nodes;
    for (final id in ids) {
      _cancelDebounce(id);
      nodes = _removeNode(nodes, id);
    }
    state = AsyncData(nodes);
    for (final id in ids) {
      _api.delete(id).catchError((_) {});
    }
    if (entries.isEmpty) return null;
    return () => _restore(entries);
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<NoteNode>>(
  NotesNotifier.new,
);
