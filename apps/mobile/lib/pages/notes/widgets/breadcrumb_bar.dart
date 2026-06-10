import 'package:flutter/material.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/theme/theme.dart';

class NoteBreadcrumbBar extends StatelessWidget {
  final List<({String id, String content})> crumbs;
  final VoidCallback onHome;
  final void Function(String id) onCrumb;

  const NoteBreadcrumbBar({
    super.key,
    required this.crumbs,
    required this.onHome,
    required this.onCrumb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colorBorder, width: 1)),
        color: context.colorSurface,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          GestureDetector(
            onTap: onHome,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 14, color: context.colorMuted),
                const SizedBox(width: 4),
                Text(S.notes,
                    style: TextStyle(fontSize: 12, color: context.colorMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ...crumbs.asMap().entries.map((e) {
            final isLast = e.key == crumbs.length - 1;
            final crumb = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('›', style: TextStyle(fontSize: 13, color: context.colorMuted2)),
                ),
                GestureDetector(
                  onTap: isLast ? null : () => onCrumb(crumb.id),
                  child: Text(
                    crumb.content.isEmpty ? S.untitled : crumb.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLast ? context.colorTextStrong : context.colorMuted,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
