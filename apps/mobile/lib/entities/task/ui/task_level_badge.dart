import 'package:flutter/material.dart';
import '../../../shared/theme/theme.dart';
import '../task.dart';

class TaskLevelBadge extends StatelessWidget {
  final TaskLevel level;

  const TaskLevelBadge({super.key, required this.level});

  static const _labels = {
    TaskLevel.day:   'ДЕНЬ',
    TaskLevel.week:  'НЕД',
    TaskLevel.month: 'МЕС',
    TaskLevel.year:  'ГОД',
  };

  Color _color(BuildContext context) => switch (level) {
    TaskLevel.day   => context.colorDay,
    TaskLevel.week  => context.colorWeek,
    TaskLevel.month => context.colorMonth,
    TaskLevel.year  => context.colorYear,
  };

  Color _tint(BuildContext context) => switch (level) {
    TaskLevel.day   => context.colorDayTint,
    TaskLevel.week  => context.colorWeekTint,
    TaskLevel.month => context.colorMonthTint,
    TaskLevel.year  => context.colorYearTint,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final tint  = _tint(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        _labels[level]!,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06,
        ),
      ),
    );
  }
}
