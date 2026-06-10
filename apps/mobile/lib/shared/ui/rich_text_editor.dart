import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Plain-text description editor.
/// Exposes the same public API as before so callers need no changes.
class RichTextEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final double minHeight;

  const RichTextEditor({
    super.key,
    required this.onChanged,
    this.initialValue = '',
    this.placeholder = 'Add a description…',
    this.minHeight = 120,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _ctrl.addListener(() => widget.onChanged(_ctrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorBorder),
        borderRadius: BorderRadius.circular(6),
        color: context.colorCard,
      ),
      child: TextField(
        controller: _ctrl,
        maxLines: null,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.65,
          color: context.colorText,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(color: context.colorMuted, fontFamily: 'Inter'),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
        ),
      ),
    );
  }
}
