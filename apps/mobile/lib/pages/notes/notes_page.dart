import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ── UI state (zoom + selection) ───────────────────────────────────────────────

class NotesUiState {
  final String? rootId;
  final Set<String> selectedIds;

  const NotesUiState({this.rootId, this.selectedIds = const {}});

  bool get isSelecting => selectedIds.isNotEmpty;

  NotesUiState copyWith({String? rootId, bool clearRoot = false, Set<String>? selectedIds}) =>
      NotesUiState(
        rootId: clearRoot ? null : (rootId ?? this.rootId),
        selectedIds: selectedIds ?? this.selectedIds,
      );
}

class NotesUiNotifier extends StateNotifier<NotesUiState> {
  NotesUiNotifier() : super(const NotesUiState());

  void setRoot(String? id) => state = NotesUiState(
        rootId: id,
        selectedIds: const {},
      );

  void startSelect(String id) => state = state.copyWith(selectedIds: {id});

  void toggleSelect(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  void clearSelection() => state = state.copyWith(selectedIds: const {});
}

final notesUiProvider = StateNotifierProvider<NotesUiNotifier, NotesUiState>(
  (_) => NotesUiNotifier(),
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

  void updateContent(String id, String content) {
    state = AsyncData(_mapNodes(_nodes, id, (n) =>
        NoteNode(id: n.id, content: content, collapsed: n.collapsed, children: n.children)));

    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 600), () {
      _api.update(id, content: content).catchError((_) {});
      _debounceTimers.remove(id);
    });
  }

  void removeNote(String id) {
    state = AsyncData(_removeNode(_nodes, id));
    _api.delete(id).catchError((_) {});
  }

  void deleteMultiple(Set<String> ids) {
    var nodes = _nodes;
    for (final id in ids) {
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

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final uiState = ref.watch(notesUiProvider);
    final notifier = ref.read(notesProvider.notifier);
    final uiNotifier = ref.read(notesUiProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: Padding(
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
        title: Text('Заметки', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText)),
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
          final roots = notifier.visibleRoots(uiState.rootId);
          final crumbs = notifier.breadcrumbs(uiState.rootId);

          return Column(
            children: [
              // Breadcrumbs
              if (uiState.rootId != null)
                _BreadcrumbBar(
                  crumbs: crumbs,
                  onHome: () => uiNotifier.setRoot(null),
                  onCrumb: (id) => uiNotifier.setRoot(id),
                ),

              // Multi-select toolbar
              if (uiState.isSelecting)
                _SelectionBar(
                  count: uiState.selectedIds.length,
                  onDelete: () {
                    notifier.deleteMultiple(uiState.selectedIds);
                    uiNotifier.clearSelection();
                  },
                  onClear: uiNotifier.clearSelection,
                ),

              // Note tree
              Expanded(
                child: roots.isEmpty
                    ? _emptyState(context, canAdd: true,
                        onAdd: () => notifier.addRoot(underRootId: uiState.rootId))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                        itemCount: roots.length,
                        itemBuilder: (ctx, i) => _NoteRow(
                          node: roots[i],
                          depth: 0,
                          notifier: notifier,
                          uiState: uiState,
                          onSelect: uiNotifier.toggleSelect,
                          onLongPress: uiNotifier.startSelect,
                          onZoom: uiNotifier.setRoot,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final uiState = ref.read(notesUiProvider);
          final notifier = ref.read(notesProvider.notifier);
          notifier.addRoot(underRootId: uiState.rootId);
        },
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
  final NotesUiState uiState;
  final void Function(String) onSelect;
  final void Function(String) onLongPress;
  final void Function(String) onZoom;

  const _NoteRow({
    required this.node,
    required this.depth,
    required this.notifier,
    required this.uiState,
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
    widget.notifier.updateContent(widget.node.id, _ctrl.text);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final hasChildren = node.children.isNotEmpty;
    final indent = widget.depth * 20.0;
    final isSelected = widget.uiState.selectedIds.contains(node.id);
    final isSelecting = widget.uiState.isSelecting;

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
                  // Actions (only when not in selection mode)
                  if (!isSelecting) ...[
                    GestureDetector(
                      onTap: () => widget.notifier.addChild(node.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Icon(Icons.add, size: 16, color: context.colorMuted),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.notifier.removeNote(node.id),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2, right: 10, top: 8, bottom: 8),
                        child: Icon(Icons.delete_outline, size: 16, color: context.colorMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!node.collapsed && hasChildren)
          ...node.children.map((child) => _NoteRow(
                node: child,
                depth: widget.depth + 1,
                notifier: widget.notifier,
                uiState: widget.uiState,
                onSelect: widget.onSelect,
                onLongPress: widget.onLongPress,
                onZoom: widget.onZoom,
              )),
      ],
    );
  }
}
