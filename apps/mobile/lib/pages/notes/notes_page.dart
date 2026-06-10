import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/theme.dart';
import '../../shared/api/notes_api.dart';
import '../../pages/app_shell.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class NoteNode {
  final String id;
  String content;
  List<NoteNode> children;
  bool collapsed;

  NoteNode({
    required this.id,
    required this.content,
    List<NoteNode>? children,
    this.collapsed = false,
  }) : children = children ?? [];
}

NoteNode _dtoToNode(NoteDto dto) => NoteNode(
      id: dto.id,
      content: dto.content,
      collapsed: dto.collapsed,
      children: dto.children.map(_dtoToNode).toList(),
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotesNotifier extends AsyncNotifier<List<NoteNode>> {
  late NotesApi _api;
  final Map<String, Timer> _debounceTimers = {};

  @override
  Future<List<NoteNode>> build() async {
    _api = ref.read(notesApiProvider);
    final dtos = await _api.list();
    return dtos.map(_dtoToNode).toList();
  }

  List<NoteNode> get _nodes => state.value ?? [];

  // ── Tree helpers ─────────────────────────────────────────────────────────

  List<NoteNode> _mapNodes(
    List<NoteNode> nodes,
    String id,
    NoteNode Function(NoteNode) fn,
  ) =>
      nodes.map((n) {
        if (n.id == id) return fn(n);
        return NoteNode(
          id: n.id,
          content: n.content,
          collapsed: n.collapsed,
          children: _mapNodes(n.children, id, fn),
        );
      }).toList();

  List<NoteNode> _removeNode(List<NoteNode> nodes, String id) => nodes
      .where((n) => n.id != id)
      .map((n) => NoteNode(
            id: n.id,
            content: n.content,
            collapsed: n.collapsed,
            children: _removeNode(n.children, id),
          ))
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

  // ── Computed views ────────────────────────────────────────────────────────

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

  List<NoteNode> visibleRoots(String? rootId) {
    if (rootId == null) return _nodes;
    return _findNode(_nodes, rootId)?.children ?? [];
  }

  List<({String id, String content})> breadcrumbs(String? rootId) {
    if (rootId == null) return [];
    final path = _findPath(_nodes, rootId);
    return path?.map((n) => (id: n.id, content: n.content)).toList() ?? [];
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void toggleCollapse(String id) {
    final nodes = _nodes;
    NoteNode? target;
    _mapNodes(nodes, id, (n) { target = n; return n; });
    if (target == null) return;
    final collapsed = !target!.collapsed;

    state = AsyncData(_mapNodes(nodes, id, (n) =>
        NoteNode(id: n.id, content: n.content, collapsed: collapsed, children: n.children)));

    _api.update(id, collapsed: collapsed).catchError((_) {});
  }

  void addChild(String parentId) {
    final newId = generateUuid();
    final nodes = _nodes;
    final parentNode = _findNode(nodes, parentId);
    final sortOrder = (parentNode?.children.length ?? 0) * 10;

    state = AsyncData(_mapNodes(nodes, parentId, (n) => NoteNode(
          id: n.id,
          content: n.content,
          collapsed: false,
          children: [...n.children, NoteNode(id: newId, content: '')],
        )));

    _api.create(id: newId, parentId: parentId, content: '', sortOrder: sortOrder)
        .ignore();
  }

  void addRoot({String? underRootId}) {
    final newId = generateUuid();
    if (underRootId == null) {
      final sortOrder = _nodes.length * 10;
      state = AsyncData([..._nodes, NoteNode(id: newId, content: '')]);
      _api.create(id: newId, parentId: null, content: '', sortOrder: sortOrder)
          .ignore();
    } else {
      addChild(underRootId);
    }
  }

  void addAfter(String id) {
    final (found, parentId) = _findParent(_nodes, id);
    if (!found) return;
    final siblings = _siblingsOf(parentId);
    final idx = siblings.indexWhere((n) => n.id == id);
    final fresh = NoteNode(id: generateUuid(), content: '');

    if (parentId == null) {
      state = AsyncData([..._nodes]..insert(idx + 1, fresh));
    } else {
      state = AsyncData(_mapNodes(_nodes, parentId, (n) => NoteNode(
            id: n.id,
            content: n.content,
            collapsed: n.collapsed,
            children: [...n.children]..insert(idx + 1, fresh),
          )));
    }
    _api.create(id: fresh.id, parentId: parentId, content: '', sortOrder: (idx + 1) * 10)
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
    nodes = _mapNodes(nodes, prev.id, (n) => NoteNode(
          id: n.id,
          content: n.content,
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
          .map((n) => NoteNode(
                id: n.id,
                content: n.content,
                collapsed: n.collapsed,
                children: insertAfterParent(n.children),
              ))
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
      state = AsyncData(_mapNodes(_nodes, parentId, (n) => NoteNode(
            id: n.id,
            content: n.content,
            collapsed: n.collapsed,
            children: reordered,
          )));
    }
    for (final i in [idx, target]) {
      _api.update(reordered[i].id, sortOrder: i * 10).catchError((_) {});
    }
  }

  void updateContent(String id, String content) {
    state = AsyncData(_mapNodes(_nodes, id, (n) =>
        NoteNode(id: n.id, content: content, collapsed: n.collapsed, children: n.children)));

    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 600), () {
      _api.update(id, content: content).catchError((_) {});
      _debounceTimers.remove(id);
    });
  }

  Iterable<String> _subtreeIds(NoteNode node) sync* {
    yield node.id;
    for (final child in node.children) {
      yield* _subtreeIds(child);
    }
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
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<NoteNode>>(
  NotesNotifier.new,
);

// ── Page ──────────────────────────────────────────────────────────────────────

class NotesPage extends ConsumerStatefulWidget {
  /// Zoomed note id from the route (`/notes/:id`); null on the root page.
  final String? rootId;

  const NotesPage({super.key, this.rootId});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  // Selection is per-page so it never leaks between stacked zoom pages.
  Set<String> _selectedIds = {};

  void _startSelect(String id) => setState(() => _selectedIds = {id});

  void _toggleSelect(String id) {
    final next = Set<String>.from(_selectedIds);
    if (!next.remove(id)) next.add(id);
    setState(() => _selectedIds = next);
  }

  void _clearSelection() => setState(() => _selectedIds = {});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final notifier = ref.read(notesProvider.notifier);
    final rootId = widget.rootId;
    final isZoomed = rootId != null;
    final crumbs = state.hasValue
        ? notifier.breadcrumbs(rootId)
        : <({String id, String content})>[];

    // Stale deep link: the zoomed note no longer exists → back to the root page.
    if (isZoomed && state.hasValue && crumbs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/notes');
      });
    }

    final zoomedTitle = crumbs.isNotEmpty && crumbs.last.content.isNotEmpty
        ? crumbs.last.content
        : 'Без названия';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: isZoomed ? null : 120,
        leading: isZoomed
            ? BackButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/notes'),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Locus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: context.colorTextStrong)),
                    const SizedBox(width: 5),
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: context.colorBrand)),
                  ],
                ),
              ),
        title: Text(
          isZoomed ? zoomedTitle : 'Заметки',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: AppShell.openDrawer),
          const SizedBox(width: 4),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ошибка загрузки заметок', style: TextStyle(color: context.colorMuted)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (allNodes) {
          final roots = notifier.visibleRoots(rootId);

          return Column(
            children: [
              // Breadcrumbs
              if (isZoomed)
                _BreadcrumbBar(
                  crumbs: crumbs,
                  onHome: () => context.go('/notes'),
                  onCrumb: (id) => context.go('/notes/$id'),
                ),

              // Multi-select toolbar
              if (_selectedIds.isNotEmpty)
                _SelectionBar(
                  count: _selectedIds.length,
                  onDelete: () {
                    notifier.deleteMultiple(_selectedIds);
                    _clearSelection();
                  },
                  onClear: _clearSelection,
                ),

              // Note tree
              Expanded(
                child: roots.isEmpty
                    ? _emptyState(context, canAdd: true,
                        onAdd: () => notifier.addRoot(underRootId: rootId))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                        itemCount: roots.length,
                        itemBuilder: (ctx, i) => _NoteRow(
                          key: ValueKey(roots[i].id),
                          node: roots[i],
                          depth: 0,
                          notifier: notifier,
                          selectedIds: _selectedIds,
                          onSelect: _toggleSelect,
                          onLongPress: _startSelect,
                          onZoom: (id) => context.push('/notes/$id'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(notesProvider.notifier).addRoot(underRootId: rootId),
        backgroundColor: context.colorBrand,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }

  Widget _emptyState(BuildContext context, {required bool canAdd, required VoidCallback onAdd}) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.article_outlined, size: 40, color: context.colorBorder2),
              const SizedBox(height: 12),
              Text('Нет заметок', style: TextStyle(color: context.colorMuted, fontSize: 16)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Breadcrumb bar ────────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  final List<({String id, String content})> crumbs;
  final VoidCallback onHome;
  final void Function(String id) onCrumb;

  const _BreadcrumbBar({required this.crumbs, required this.onHome, required this.onCrumb});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colorBorder, width: 1)),
        color: context.colorSurface,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          GestureDetector(
            onTap: onHome,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 14, color: context.colorMuted),
                const SizedBox(width: 4),
                Text('Notes', style: TextStyle(fontSize: 12, color: context.colorMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ...crumbs.asMap().entries.map((e) {
            final isLast = e.key == crumbs.length - 1;
            final crumb = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('›', style: TextStyle(fontSize: 13, color: context.colorMuted2)),
                ),
                GestureDetector(
                  onTap: isLast ? null : () => onCrumb(crumb.id),
                  child: Text(
                    crumb.content.isEmpty ? 'Без названия' : crumb.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLast ? context.colorTextStrong : context.colorMuted,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Selection toolbar ─────────────────────────────────────────────────────────

class _SelectionBar extends StatefulWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const _SelectionBar({required this.count, required this.onDelete, required this.onClear});

  @override
  State<_SelectionBar> createState() => _SelectionBarState();
}

class _SelectionBarState extends State<_SelectionBar> {
  bool _confirm = false;
  Timer? _resetTimer;

  void _handleDelete() {
    if (_confirm) {
      _resetTimer?.cancel();
      widget.onDelete();
    } else {
      setState(() => _confirm = true);
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _confirm = false);
      });
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colorBrandSoft,
        border: Border(bottom: BorderSide(color: context.colorBrand.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Text('${widget.count} выбрано',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colorBrand)),
          const Spacer(),
          TextButton.icon(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_outline, size: 14),
            label: Text(_confirm ? 'Подтвердить?' : 'Удалить', style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: _confirm ? Colors.red : context.colorMuted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onClear,
            child: Text('✕', style: TextStyle(fontSize: 13, color: context.colorMuted)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── NoteRow ───────────────────────────────────────────────────────────────────

class _NoteRow extends StatefulWidget {
  final NoteNode node;
  final int depth;
  final NotesNotifier notifier;
  final Set<String> selectedIds;
  final void Function(String) onSelect;
  final void Function(String) onLongPress;
  final void Function(String) onZoom;

  const _NoteRow({
    super.key,
    required this.node,
    required this.depth,
    required this.notifier,
    required this.selectedIds,
    required this.onSelect,
    required this.onLongPress,
    required this.onZoom,
  });

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.content);
    _focusNode = FocusNode();
    if (widget.node.content.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startEdit();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _NoteRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If this State ever gets reused for a different node, drop the stale
    // controller text so _commit can't write it onto the new node.
    if (oldWidget.node.id != widget.node.id) {
      _ctrl.text = widget.node.content;
      _editing = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _ctrl.text = widget.node.content;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _commit() {
    if (_ctrl.text != widget.node.content) {
      widget.notifier.updateContent(widget.node.id, _ctrl.text);
    }
    if (mounted) setState(() => _editing = false);
  }

  void _showActions() {
    final node = widget.node;
    final notifier = widget.notifier;
    final info = notifier.siblingInfo(node.id);
    final descendants = notifier.descendantCount(node.id);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        void close() => Navigator.pop(sheetCtx);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.open_in_full, size: 20),
                  title: const Text('Открыть как страницу'),
                  onTap: () { close(); widget.onZoom(node.id); },
                ),
                ListTile(
                  leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                  title: const Text('Добавить вложенную'),
                  onTap: () { close(); notifier.addChild(node.id); },
                ),
                ListTile(
                  leading: const Icon(Icons.add, size: 20),
                  title: const Text('Добавить ниже'),
                  onTap: () { close(); notifier.addAfter(node.id); },
                ),
                ListTile(
                  leading: const Icon(Icons.format_indent_increase, size: 20),
                  title: const Text('Сдвинуть вправо'),
                  enabled: info != null && info.index > 0,
                  onTap: () { close(); notifier.indent(node.id); },
                ),
                ListTile(
                  leading: const Icon(Icons.format_indent_decrease, size: 20),
                  title: const Text('Сдвинуть влево'),
                  enabled: info != null && !info.isRoot,
                  onTap: () { close(); notifier.unindent(node.id); },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward, size: 20),
                  title: const Text('Переместить вверх'),
                  enabled: info != null && info.index > 0,
                  onTap: () { close(); notifier.moveUp(node.id); },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_downward, size: 20),
                  title: const Text('Переместить вниз'),
                  enabled: info != null && info.index < info.count - 1,
                  onTap: () { close(); notifier.moveDown(node.id); },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  title: const Text('Удалить', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    close();
                    if (descendants > 0) {
                      _confirmSubtreeDelete(descendants);
                    } else {
                      notifier.removeNote(node.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSubtreeDelete(int descendants) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text('Будут удалены заметка и вложенные: $descendants шт.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.notifier.removeNote(widget.node.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final hasChildren = node.children.isNotEmpty;
    final indent = widget.depth * 20.0;
    final isSelected = widget.selectedIds.contains(node.id);
    final isSelecting = widget.selectedIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: isSelected ? context.colorBrandSoft : Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isSelecting) {
                widget.onSelect(node.id);
              } else {
                _startEdit();
              }
            },
            onLongPress: () => widget.onLongPress(node.id),
            child: Padding(
              padding: EdgeInsets.only(left: 16 + indent, right: 8, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bullet / collapse toggle
                  GestureDetector(
                    onTap: () {
                      if (hasChildren) {
                        widget.notifier.toggleCollapse(node.id);
                      } else {
                        widget.onZoom(node.id);
                      }
                    },
                    child: SizedBox(
                      width: 20,
                      height: 36,
                      child: Center(
                        child: hasChildren
                            ? AnimatedRotation(
                                turns: node.collapsed ? 0 : 0.25,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(Icons.chevron_right, size: 16, color: context.colorMuted),
                              )
                            : Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.colorMuted,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Content
                  Expanded(
                    child: _editing
                        ? TextField(
                            controller: _ctrl,
                            focusNode: _focusNode,
                            style: TextStyle(fontSize: 14, color: context.colorText, fontFamily: 'Inter'),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: (_) => _commit(),
                            onEditingComplete: _commit,
                            onTapOutside: (_) => _commit(),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Text(
                              node.content.isEmpty ? 'Пустая заметка' : node.content,
                              style: TextStyle(
                                fontSize: 14,
                                color: node.content.isEmpty ? context.colorMuted : context.colorText,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                  ),
                  // Actions menu trigger (hidden in selection mode)
                  if (!isSelecting)
                    GestureDetector(
                      onTap: _showActions,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, right: 10, top: 8, bottom: 8),
                        child: Icon(Icons.more_horiz, size: 18, color: context.colorMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!node.collapsed && hasChildren)
          ...node.children.map((child) => _NoteRow(
                key: ValueKey(child.id),
                node: child,
                depth: widget.depth + 1,
                notifier: widget.notifier,
                selectedIds: widget.selectedIds,
                onSelect: widget.onSelect,
                onLongPress: widget.onLongPress,
                onZoom: widget.onZoom,
              )),
      ],
    );
  }
}
