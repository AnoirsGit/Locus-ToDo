import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../task.dart';
import 'task_level_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskWithPeriod task;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final bool showLevel;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onEdit,
    this.showLevel = true,
  });

  // ── Meta helpers ────────────────────────────────────────────────────────

  static const _dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  static const _monthNames = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  String? _recurringLabel() {
    final r = task.recurringConfig;
    if (r == null) return null;
    final parts = <String>[];
    if (task.level == TaskLevel.week && r.dayOfWeek != null)
      parts.add(_dayNames[r.dayOfWeek!]);
    else if (task.level == TaskLevel.month && r.dayOfMonth != null)
      parts.add('${r.dayOfMonth}-го');
    if (task.scheduledTime != null) parts.add(task.scheduledTime!);
    return parts.isEmpty ? '↻' : '↻ ${parts.join(' · ')}';
  }

  String? _targetDayLabel() {
    if (task.level != TaskLevel.week || task.period.targetDate == null) return null;
    final d = DateTime.parse('${task.period.targetDate}T00:00:00Z');
    return '→ ${_dayNames[d.weekday % 7]}';
  }

  String? _deadlineLabel() {
    final m = task.period.deadlineMonth;
    if (task.level != TaskLevel.year || m == null) return null;
    return 'до ${_monthNames[m]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.period.status == TaskStatus.done;
    final isOverdue = task.period.status == TaskStatus.overdue;
    final colors = Theme.of(context).colorScheme;

    final recurringLabel = _recurringLabel();
    final targetDayLabel = _targetDayLabel();
    final deadlineLabel = _deadlineLabel();

    final card = InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: isDone ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDone ? colors.primary : const Color(0xFF3A4550),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),

            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDone ? const Color(0xFF5D6E7A) : const Color(0xFFE2E8ED),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF5D6E7A),
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7A8A97)),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Meta chips row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (showLevel) TaskLevelBadge(level: task.level),
                      if (recurringLabel != null)
                        _MetaChip(recurringLabel)
                      else ...[
                        if (task.scheduledTime != null)
                          _MetaChip('⏱ ${task.scheduledTime}'),
                        if (targetDayLabel != null) _MetaChip(targetDayLabel),
                      ],
                      if (deadlineLabel != null) _MetaChip(deadlineLabel),
                      if (isOverdue)
                        const _MetaChip('просрочено', color: Color(0xFFF87168)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('${task.period.id}_swipe'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onToggle();
        return false; // не удаляем из списка, просто тогл
      },
      background: Container(
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0x387A8A97)
              : const Color(0x387EE2B8),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        child: Icon(
          isDone ? Icons.close : Icons.check,
          color: isDone ? const Color(0xFF7A8A97) : const Color(0xFF7EE2B8),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2428),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? const Color(0x60F87168)
                : const Color(0xFF2E3740),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _MetaChip(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10.5,
        color: color ?? const Color(0xFF7A8A97),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
