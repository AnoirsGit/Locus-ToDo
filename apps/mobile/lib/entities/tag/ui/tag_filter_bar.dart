import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/providers/tag_store.dart';
import '../../../shared/theme/theme.dart';

/// Horizontal tag filter strip backed by the global [tagStoreProvider]. Reads
/// the store directly (no prop drilling) so the same instance can sit on any
/// screen — filter state is shared across every view + backlog/archive.
/// Renders nothing when no tags exist.
class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  static Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagStoreProvider);
    if (tagState.tags.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(tagStoreProvider.notifier);

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
                onSelected: (_) => notifier.toggleFilterTag(tag.id),
                selectedColor: _parseColor(tag.color) ?? context.colorBrand,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          if (tagState.isFiltering)
            TextButton(
              onPressed: notifier.clearFilter,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(S.clearFilter,
                  style: TextStyle(fontSize: 12, color: context.colorMuted)),
            ),
        ],
      ),
    );
  }
}
