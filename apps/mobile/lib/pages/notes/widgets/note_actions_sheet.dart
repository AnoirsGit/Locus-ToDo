import 'package:flutter/material.dart';
import '../../../entities/note/model/note_node.dart';
import '../../../entities/note/model/notes_notifier.dart';
import '../../../shared/core/strings.dart';

void showNoteActionsSheet(
  BuildContext context, {
  required NoteNode node,
  required NotesNotifier notifier,
  required void Function(String id) onZoom,
}) {
  final info = notifier.siblingInfo(node.id);
  final descendants = notifier.descendantCount(node.id);
  final hasUrlField =
      node.type == NoteNodeType.image || node.type == NoteNodeType.link;

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
                title: Text(S.openAsPage),
                onTap: () { close(); onZoom(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                title: Text(S.addChild),
                onTap: () { close(); notifier.addChild(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.add, size: 20),
                title: Text(S.addBelow),
                onTap: () { close(); notifier.addAfter(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, size: 20),
                title: Text(S.turnInto),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  close();
                  _showTurnIntoSheet(context, node: node, notifier: notifier);
                },
              ),
              if (hasUrlField)
                ListTile(
                  leading: const Icon(Icons.link, size: 20),
                  title: Text(S.setUrl),
                  onTap: () {
                    close();
                    _showSetUrlDialog(context, node: node, notifier: notifier);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.format_indent_increase, size: 20),
                title: Text(S.indent),
                enabled: info != null && info.index > 0,
                onTap: () { close(); notifier.indent(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.format_indent_decrease, size: 20),
                title: Text(S.outdent),
                enabled: info != null && !info.isRoot,
                onTap: () { close(); notifier.unindent(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, size: 20),
                title: Text(S.moveUp),
                enabled: info != null && info.index > 0,
                onTap: () { close(); notifier.moveUp(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward, size: 20),
                title: Text(S.moveDown),
                enabled: info != null && info.index < info.count - 1,
                onTap: () { close(); notifier.moveDown(node.id); },
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_outlined, size: 20),
                title: Text(S.duplicate),
                onTap: () { close(); notifier.duplicate(node.id); },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                title: Text(S.delete, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  close();
                  if (descendants > 0) {
                    _confirmSubtreeDelete(context,
                        node: node, notifier: notifier, descendants: descendants);
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

void _showTurnIntoSheet(
  BuildContext context, {
  required NoteNode node,
  required NotesNotifier notifier,
}) {
  final types = [
    (NoteNodeType.text, S.typeText, Icons.notes),
    (NoteNodeType.heading1, S.typeHeading1, Icons.title),
    (NoteNodeType.heading2, S.typeHeading2, Icons.text_fields),
    (NoteNodeType.bullet, S.typeBullet, Icons.circle, ),
    (NoteNodeType.image, S.typeImage, Icons.image_outlined),
    (NoteNodeType.link, S.typeLink, Icons.link),
  ];

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (type, label, icon) in types)
              ListTile(
                leading: Icon(icon, size: 20),
                title: Text(label),
                selected: node.type == type,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  notifier.updateType(node.id, type);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

void _showSetUrlDialog(
  BuildContext context, {
  required NoteNode node,
  required NotesNotifier notifier,
}) {
  final ctrl = TextEditingController(text: node.url ?? '');
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(S.setUrl),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(hintText: 'https://...'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text(S.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            notifier.updateUrl(node.id, ctrl.text);
          },
          child: Text(S.save),
        ),
      ],
    ),
  );
}

void _confirmSubtreeDelete(
  BuildContext context, {
  required NoteNode node,
  required NotesNotifier notifier,
  required int descendants,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(S.deleteNoteQ),
      content: Text(S.deleteSubtree(descendants)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text(S.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            notifier.removeNote(node.id);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(S.delete),
        ),
      ],
    ),
  );
}
