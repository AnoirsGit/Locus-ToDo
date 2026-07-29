import 'package:flutter/material.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/providers/tag_store.dart';
import '../../../shared/theme/theme.dart';

/// Horizontal scrollable tag filter chip bar.
/// Shared between [TasksPage] (backlog/archive) and [ViewTabPage] (all views).
class TagFilterBar extends StatelessWidget {
  final TagStoreState tagState;
  final void Function(String tagId) onToggle;
  final VoidCallback onClear;

  const TagFilterBar({
    super.key,
    required this.tagState,
    required this.onToggle,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...tagState.tags.map((tag) {
            final active = tagState.filterTagIds.contains(tag.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                selected: active,
                onSelected: (_) => onToggle(tag.id),
                selectedColor: tag.color != null
                    ? Color(int.parse(tag.color!.replaceFirst('#', '0xFF')))
                    : context.colorBrand,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          if (tagState.isFiltering)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                S.reset,
                style: TextStyle(fontSize: 12, color: context.colorMuted),
              ),
            ),
        ],
      ),
    );
  }
}
