import 'package:flutter/material.dart';
import '../task.dart';

class TaskLevelBadge extends StatelessWidget {
  final TaskLevel level;

  const TaskLevelBadge({super.key, required this.level});

  Color _getColor() {
    switch (level) {
      case TaskLevel.day: return Colors.blue;
      case TaskLevel.week: return Colors.green;
      case TaskLevel.month: return Colors.orange;
      case TaskLevel.year: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getColor().withOpacity(0.5)),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(
          color: _getColor(),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
