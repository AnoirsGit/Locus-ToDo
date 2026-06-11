import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/tags_api.dart';
import '../../../shared/providers/tag_store.dart';
import '../../../shared/theme/theme.dart';

Color noteTagColor(BuildContext context, TagDto tag) {
  if (tag.color == null) return context.colorMuted;
  final h = tag.color!.replaceFirst('#', '');
  final value = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return value != null ? Color(value) : context.colorMuted;
}

/// Inline read-only tag chips shown under a note row.
class NoteTagChips extends StatelessWidget {
  final List<TagDto> tags;

  const NoteTagChips({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Wrap(
        spacing: 5,
        runSpacing: 4,
        children: tags.map((tag) {
          final color = noteTagColor(context, tag);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Text(
              tag.name,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bottom-sheet picker that toggles tags on a note (optimistic via tagStore).
void showNoteTagPicker(BuildContext context, WidgetRef ref, String noteId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _NoteTagPickerSheet(ref: ref, noteId: noteId),
  );
}

class _NoteTagPickerSheet extends StatefulWidget {
  final WidgetRef ref;
  final String noteId;

  const _NoteTagPickerSheet({required this.ref, required this.noteId});

  @override
  State<_NoteTagPickerSheet> createState() => _NoteTagPickerSheetState();
}

class _NoteTagPickerSheetState extends State<_NoteTagPickerSheet> {
  late List<String> _ids;

  @override
  void initState() {
    super.initState();
    _ids = List.from(widget.ref.read(tagStoreProvider).tagIdsForNote(widget.noteId));
  }

  void _toggle(String id) {
    setState(() {
      if (_ids.contains(id)) {
        _ids = _ids.where((i) => i != id).toList();
      } else {
        _ids = [..._ids, id];
      }
    });
    widget.ref.read(tagStoreProvider.notifier).setNoteTags(widget.noteId, _ids);
  }

  @override
  Widget build(BuildContext context) {
    final allTags = widget.ref.read(tagStoreProvider).tags;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colorTextStrong),
          ),
          const SizedBox(height: 12),
          if (allTags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No tags yet. Create tags in Settings.',
                  style: TextStyle(fontSize: 13, color: context.colorMuted)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final isSelected = _ids.contains(tag.id);
                final color = noteTagColor(context, tag);
                return GestureDetector(
                  onTap: () => _toggle(tag.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(35) : context.colorSurface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color.withAlpha(160) : context.colorBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? color : context.colorMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
