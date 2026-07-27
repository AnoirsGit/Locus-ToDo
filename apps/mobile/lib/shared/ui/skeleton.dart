import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Generic shimmer placeholder block — mirrors web `Skeleton.svelte`
/// (`animate-pulse` over `--color-surface-2`).
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const Skeleton({super.key, this.width, this.height = 14, this.borderRadius = 6});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colorSurface2,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Placeholder task/note rows shown while a list loads — port of web
/// `TaskListSkeleton.svelte`.
class TaskListSkeleton extends StatelessWidget {
  final int count;
  const TaskListSkeleton({super.key, this.count = 5});

  static const _widths = [0.68, 0.54, 0.61, 0.47, 0.72];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(count, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colorCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colorBorder),
              ),
              child: Row(
                children: [
                  const Skeleton(width: 18, height: 18, borderRadius: 9),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: _widths[i % _widths.length],
                          child: const Skeleton(height: 13),
                        ),
                        const SizedBox(height: 6),
                        const FractionallySizedBox(
                          widthFactor: 0.3,
                          child: Skeleton(height: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Placeholder snapshot cards shown while the stats page loads — port of
/// web `StatsSkeleton.svelte`.
class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: List.generate(4, (_) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colorCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FractionallySizedBox(widthFactor: 0.4, child: Skeleton(height: 11)),
                const SizedBox(height: 12),
                const FractionallySizedBox(widthFactor: 0.55, child: Skeleton(height: 22)),
                const SizedBox(height: 12),
                Skeleton(height: 6, borderRadius: 999, width: double.infinity),
              ],
            ),
          );
        }),
      ),
    );
  }
}
