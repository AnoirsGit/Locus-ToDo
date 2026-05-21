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

  String? _findParentId(List<NoteNode> nodes, String targetId) {
    for (final n in nodes) {
      if (n.children.any((c) => c.id == targetId)) return n.id;
      final found = _findParentId(n.children, targetId);
      if (found != null) return found;
    }
    return null;
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
        .catchError((_) {});
  }

  void addRoot() {
    final newId = generateUuid();
    final sortOrder = _nodes.length * 10;
    state = AsyncData([..._nodes, NoteNode(id: newId, content: '')]);
    _api.create(id: newId, parentId: null, content: '', sortOrder: sortOrder)
        .catchError((_) {});
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

  NoteNode? _findNode(List<NoteNode> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final found = _findNode(n.children, id);
      if (found != null) return found;
    }
    return null;
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
    final notifier = ref.read(notesProvider.notifier);

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
        title: Text('Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText)),
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
              Text('Failed to load notes', style: TextStyle(color: context.colorMuted)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (nodes) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
          itemCount: nodes.length,
          itemBuilder: (ctx, i) => _NoteRow(
            node: nodes[i],
            depth: 0,
            notifier: notifier,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.hasValue ? notifier.addRoot : null,
        backgroundColor: context.colorBrand,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }
}

// ── NoteRow ───────────────────────────────────────────────────────────────────

class _NoteRow extends StatefulWidget {
  final NoteNode node;
  final int depth;
  final NotesNotifier notifier;

  const _NoteRow({
    required this.node,
    required this.depth,
    required this.notifier,
  });

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.content);
    if (widget.node.content.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editing = true);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren ? () => widget.notifier.toggleCollapse(node.id) : null,
          onLongPress: () => setState(() {
            _editing = true;
            _ctrl.text = node.content;
          }),
          child: Padding(
            padding: EdgeInsets.only(left: 16 + indent, right: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  child: hasChildren
                      ? GestureDetector(
                          onTap: () => widget.notifier.toggleCollapse(node.id),
                          child: AnimatedRotation(
                            turns: node.collapsed ? 0 : 0.25,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(Icons.chevron_right, size: 16, color: context.colorMuted),
                          ),
                        )
                      : Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colorMuted,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: TextStyle(fontSize: 14, color: context.colorText, fontFamily: 'Inter'),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (_) => _commit(),
                          onEditingComplete: _commit,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Text(
                            node.content.isEmpty ? 'Empty note' : node.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: node.content.isEmpty ? context.colorMuted : context.colorText,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () => widget.notifier.addChild(node.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Icon(Icons.add, size: 16, color: context.colorMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!node.collapsed && hasChildren)
          ...node.children.map((child) => _NoteRow(
                node: child,
                depth: widget.depth + 1,
                notifier: widget.notifier,
              )),
      ],
    );
  }
}
