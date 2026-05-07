import 'package:flutter/material.dart';
import '../task.dart';

class TaskLevelBadge extends StatelessWidget {
  final TaskLevel level;

  const TaskLevelBadge({super.key, required this.level});

  static const _colors = {
    TaskLevel.day:   Color(0xFF4BCE97),
    TaskLevel.week:  Color(0xFF579DFF),
    TaskLevel.month: Color(0xFF9F8FEF),
    TaskLevel.year:  Color(0xFFE2B203),
  };

  static const _labels = {
    TaskLevel.day:   'ДЕНЬ',
    TaskLevel.week:  'НЕД',
    TaskLevel.month: 'МЕС',
    TaskLevel.year:  'ГОД',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.35)),
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
