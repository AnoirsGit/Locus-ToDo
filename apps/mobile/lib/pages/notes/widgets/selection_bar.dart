import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/theme/theme.dart';

class NotesSelectionBar extends StatefulWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const NotesSelectionBar({
    super.key,
    required this.count,
    required this.onDelete,
    required this.onClear,
  });

  @override
  State<NotesSelectionBar> createState() => _NotesSelectionBarState();
}

class _NotesSelectionBarState extends State<NotesSelectionBar> {
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
          Text(S.selected(widget.count),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colorBrand)),
          const Spacer(),
          TextButton.icon(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_outline, size: 14),
            label: Text(_confirm ? S.confirmQ : S.delete, style: const TextStyle(fontSize: 12)),
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
