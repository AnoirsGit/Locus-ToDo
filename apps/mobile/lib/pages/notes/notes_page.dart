import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../entities/note/model/note_node.dart';
import '../../entities/note/model/notes_notifier.dart';
import '../../shared/core/strings.dart';
import '../../shared/providers/tag_store.dart';
import '../../shared/theme/theme.dart';
import '../app_shell.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/note_actions_sheet.dart';
import 'widgets/note_board.dart';
import 'widgets/note_row.dart';
import 'widgets/note_tags.dart';
import 'widgets/selection_bar.dart';

enum _NotesView { outline, board }

class NotesPage extends ConsumerStatefulWidget {
  /// Zoomed note id from the route (`/notes/:id`); null on the root page.
  final String? rootId;

  const NotesPage({super.key, this.rootId});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  _NotesView _view = _NotesView.outline;

  // Selection is per-page so it never leaks between stacked zoom pages.
  Set<String> _selectedIds = {};

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final tags = ref.read(tagStoreProvider.notifier);
      await tags.load();
      await tags.loadNoteAssignments();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Prune the tree to branches containing a tag-match, force-expanding along
  // the way (mirrors the web outline filter).
  List<NoteNode> _pruneByTag(List<NoteNode> nodes, TagStoreState tagState) => nodes
      .map((n) => n.copyWith(collapsed: false, children: _pruneByTag(n.children, tagState)))
      .where((n) => tagState.noteMatchesFilter(n.id) || n.children.isNotEmpty)
      .toList();

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
    final tagState = ref.watch(tagStoreProvider);
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
        : S.untitled;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: isZoomed ? null : 120,
        leading: isZoomed
            ? BackButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/notes'),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Locus',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            color: context.colorTextStrong)),
                    const SizedBox(width: 5),
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: context.colorBrand)),
                  ],
                ),
              ),
        title: Text(
          isZoomed ? zoomedTitle : S.notes,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(_view == _NotesView.outline
                ? Icons.view_kanban_outlined
                : Icons.format_list_bulleted),
            tooltip: _view == _NotesView.outline ? S.board : S.outline,
            onPressed: () => setState(() => _view = _view == _NotesView.outline
                ? _NotesView.board
                : _NotesView.outline),
          ),
          const IconButton(icon: Icon(Icons.menu), onPressed: AppShell.openDrawer),
          const SizedBox(width: 4),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.notesLoadError, style: TextStyle(color: context.colorMuted)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: Text(S.retry),
              ),
            ],
          ),
        ),
        data: (allNodes) {
          var roots = notifier.visibleRoots(rootId);
          if (tagState.isFilteringNotes) {
            roots = _pruneByTag(roots, tagState);
          }

          return RefreshIndicator(
            onRefresh: () => notifier.refresh(),
            color: context.colorBrand,
            backgroundColor: context.colorSurface,
            child: Column(
            children: [
              // Breadcrumbs
              if (isZoomed)
                NoteBreadcrumbBar(
                  crumbs: crumbs,
                  onHome: () => context.go('/notes'),
                  onCrumb: (id) => context.go('/notes/$id'),
                ),

              // Search (outline only)
              if (_view == _NotesView.outline)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search notes…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() { _searchCtrl.clear(); _searchQuery = ''; }),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),

              // Tag filter (outline only, hidden while searching)
              if (_view == _NotesView.outline && _searchQuery.trim().isEmpty && tagState.tags.isNotEmpty)
                _NoteTagFilterBar(tagState: tagState, ref: ref),

              // Multi-select toolbar (outline only)
              if (_view == _NotesView.outline && _selectedIds.isNotEmpty)
                NotesSelectionBar(
                  count: _selectedIds.length,
                  onDelete: () {
                    showNoteUndoSnack(context, notifier.deleteMultipleWithUndo(_selectedIds));
                    _clearSelection();
                  },
                  onClear: _clearSelection,
                ),

              Expanded(
                child: _view == _NotesView.board
                    ? NotesBoard(rootId: rootId)
                    : _searchQuery.trim().isNotEmpty
                        ? _searchResults(context, notifier)
                        : roots.isEmpty
                            ? _emptyState(context,
                                onAdd: () => notifier.addRoot(underRootId: rootId))
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                                itemCount: roots.length,
                                itemBuilder: (ctx, i) => NoteRow(
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
            ),
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

  Widget _searchResults(BuildContext context, NotesNotifier notifier) {
    final results = notifier.search(_searchQuery);
    if (results.isEmpty) {
      return Center(
        child: Text('No matches', style: TextStyle(color: context.colorMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final r = results[i];
        return ListTile(
          dense: true,
          title: Text(
            r.content.isEmpty ? S.untitled : r.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: r.path.isEmpty
              ? null
              : Text(r.path, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.colorMuted)),
          onTap: () {
            setState(() { _searchCtrl.clear(); _searchQuery = ''; });
            context.push('/notes/${r.id}');
          },
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, {required VoidCallback onAdd}) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.article_outlined, size: 40, color: context.colorBorder2),
              const SizedBox(height: 12),
              Text(S.noNotes, style: TextStyle(color: context.colorMuted, fontSize: 16)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(S.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteTagFilterBar extends StatelessWidget {
  final TagStoreState tagState;
  final WidgetRef ref;

  const _NoteTagFilterBar({required this.tagState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(tagStoreProvider.notifier);
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          for (final tag in tagState.tags)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: () {
                final active = tagState.noteFilterTagIds.contains(tag.id);
                final color = noteTagColor(context, tag);
                return GestureDetector(
                  onTap: () => notifier.toggleNoteFilterTag(tag.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? color.withAlpha(35) : context.colorSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? color.withAlpha(160) : context.colorBorder,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? color : context.colorMuted,
                      ),
                    ),
                  ),
                );
              }(),
            ),
          if (tagState.isFilteringNotes)
            TextButton(
              onPressed: notifier.clearNoteFilter,
              child: Text(S.clearFilter, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
