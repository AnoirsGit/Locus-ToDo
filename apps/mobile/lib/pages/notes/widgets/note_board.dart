import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/note/model/note_node.dart';
import '../../../entities/note/model/notes_notifier.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/theme/theme.dart';

/// Board view: top-level nodes are columns, their children are cards.
/// Mirrors the web NoteBoard MVP (inline edit, add card, add column).
class NotesBoard extends ConsumerStatefulWidget {
  final String? rootId;

  const NotesBoard({super.key, this.rootId});

  @override
  ConsumerState<NotesBoard> createState() => _NotesBoardState();
}

class _NotesBoardState extends ConsumerState<NotesBoard> {
  String? _editingId;
  TextEditingController? _editCtrl;

  void _startEdit(String id, String content) {
    _editCtrl?.dispose();
    setState(() {
      _editingId = id;
      _editCtrl = TextEditingController(text: content);
    });
  }

  void _commitEdit() {
    final id = _editingId;
    final ctrl = _editCtrl;
    if (id != null && ctrl != null) {
      ref.read(notesProvider.notifier).updateContent(id, ctrl.text);
    }
    setState(() => _editingId = null);
  }

  @override
  void dispose() {
    _editCtrl?.dispose();
    super.dispose();
  }

  String _typeLabel(NoteNodeType type) => switch (type) {
        NoteNodeType.text => 'Text',
        NoteNodeType.heading1 => 'H1',
        NoteNodeType.heading2 => 'H2',
        NoteNodeType.bullet => '·',
        NoteNodeType.todo => '☑',
        NoteNodeType.image => 'Img',
        NoteNodeType.link => '↗',
      };

  Widget _editableText(
    BuildContext context,
    NoteNode node, {
    required TextStyle style,
    required String placeholder,
  }) {
    if (_editingId == node.id) {
      return TextField(
        controller: _editCtrl,
        autofocus: true,
        style: style,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (_) => _commitEdit(),
        onTapOutside: (_) => _commitEdit(),
      );
    }
    return GestureDetector(
      onTap: () => _startEdit(node.id, node.content),
      child: Text(
        node.content.isEmpty ? placeholder : node.content,
        style: node.content.isEmpty ? style.copyWith(color: context.colorMuted) : style,
      ),
    );
  }

  Widget _card(BuildContext context, NoteNode card) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colorCard,
        border: Border.all(color: context.colorBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_typeLabel(card.type),
              style: TextStyle(fontSize: 10, color: context.colorMuted2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (card.type == NoteNodeType.image && card.url != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  card.url!,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 50,
                    color: context.colorSurface,
                    child: Icon(Icons.broken_image_outlined, size: 18, color: context.colorMuted),
                  ),
                ),
              ),
            ),
          _editableText(
            context,
            card,
            style: TextStyle(fontSize: 13, color: context.colorText),
            placeholder: S.emptyCard,
          ),
          if (card.type == NoteNodeType.link && card.url != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(card.url!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.colorBrand)),
            ),
          if (card.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(S.nested(card.children.length),
                  style: TextStyle(fontSize: 10, color: context.colorMuted)),
            ),
        ],
      ),
    );
  }

  Widget _column(BuildContext context, NoteNode col, NotesNotifier notifier) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colorSurface,
        border: Border.all(color: context.colorBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _editableText(
                  context,
                  col,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: context.colorTextStrong),
                  placeholder: S.untitled,
                ),
              ),
              Text('${col.children.length}',
                  style: TextStyle(fontSize: 11, color: context.colorMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final card in col.children) _card(context, card),
                TextButton.icon(
                  onPressed: () => notifier.addChild(col.id),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(S.addCard, style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colorMuted,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(notesProvider.notifier);
    // Rebuild when the tree changes.
    ref.watch(notesProvider);
    final columns = notifier.visibleRoots(widget.rootId);

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: [
        for (final col in columns) _column(context, col, notifier),
        SizedBox(
          width: 160,
          child: Align(
            alignment: Alignment.topLeft,
            child: TextButton.icon(
              onPressed: () => notifier.addRoot(underRootId: widget.rootId),
              icon: const Icon(Icons.add, size: 16),
              label: Text(S.addColumn),
              style: TextButton.styleFrom(foregroundColor: context.colorMuted),
            ),
          ),
        ),
      ],
    );
  }
}
