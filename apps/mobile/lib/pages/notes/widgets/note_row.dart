import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../entities/note/model/note_node.dart';
import '../../../entities/note/model/notes_notifier.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/theme/theme.dart';
import 'note_actions_sheet.dart';

class NoteRow extends StatefulWidget {
  final NoteNode node;
  final int depth;
  final NotesNotifier notifier;
  final Set<String> selectedIds;
  final void Function(String) onSelect;
  final void Function(String) onLongPress;
  final void Function(String) onZoom;

  const NoteRow({
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
  State<NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<NoteRow> {
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
  void didUpdateWidget(covariant NoteRow oldWidget) {
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

  // Enter — commit and add a sibling below (web Enter semantics).
  void _commitAndAddSibling() {
    _commit();
    widget.notifier.addAfter(widget.node.id);
  }

  TextStyle _contentStyle(BuildContext context) {
    final base = TextStyle(fontSize: 14, color: context.colorText, fontFamily: 'Inter');
    return switch (widget.node.type) {
      NoteNodeType.heading1 => base.copyWith(
          fontSize: 18, fontWeight: FontWeight.w700, color: context.colorTextStrong),
      NoteNodeType.heading2 => base.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: context.colorTextStrong),
      _ => base,
    };
  }

  Future<void> _openUrl() async {
    final url = widget.node.url;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _displayContent(BuildContext context) {
    final node = widget.node;
    final style = _contentStyle(context);
    final text = Text(
      node.content.isEmpty ? S.emptyNote : node.content,
      style: node.content.isEmpty
          ? style.copyWith(color: context.colorMuted)
          : style,
    );

    switch (node.type) {
      case NoteNodeType.link:
        return Row(
          children: [
            Flexible(child: text),
            if (node.url != null)
              GestureDetector(
                onTap: _openUrl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.open_in_new, size: 14, color: context.colorBrand),
                ),
              ),
          ],
        );
      case NoteNodeType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (node.url != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    node.url!,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      width: 120,
                      color: context.colorSurface,
                      child: Icon(Icons.broken_image_outlined,
                          size: 20, color: context.colorMuted),
                    ),
                  ),
                ),
              ),
            text,
          ],
        );
      default:
        return text;
    }
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
        GestureDetector(
          // Swipe right = indent, swipe left = outdent (the menu mirrors these).
          // Disabled while editing or selecting so it can't fight text/selection.
          onHorizontalDragEnd: (details) {
            if (_editing || isSelecting) return;
            final v = details.primaryVelocity ?? 0;
            if (v > 250) {
              widget.notifier.indent(node.id);
            } else if (v < -250) {
              widget.notifier.unindent(node.id);
            }
          },
          child: AnimatedContainer(
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
                            style: _contentStyle(context),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _commitAndAddSibling(),
                            onTapOutside: (_) => _commit(),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: _displayContent(context),
                          ),
                  ),
                  // Actions menu trigger (hidden in selection mode)
                  if (!isSelecting)
                    GestureDetector(
                      onTap: () => showNoteActionsSheet(
                        context,
                        node: node,
                        notifier: widget.notifier,
                        onZoom: widget.onZoom,
                      ),
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
        ),
        if (!node.collapsed && hasChildren)
          ...node.children.map((child) => NoteRow(
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
