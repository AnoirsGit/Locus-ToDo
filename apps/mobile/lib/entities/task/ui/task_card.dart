import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/theme.dart';
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
    if (task.level == TaskLevel.week && r.daysOfWeek != null && r.daysOfWeek!.isNotEmpty) {
      final sorted = [...r.daysOfWeek!]..sort();
      final monFirst = [...sorted.where((d) => d != 0), ...sorted.where((d) => d == 0)];
      parts.add(monFirst.map((d) => _dayNames[d]).join(' '));
    } else if (task.level == TaskLevel.month && r.dayOfMonth != null) {
      parts.add('${r.dayOfMonth}-го');
    }
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

  String? _archiveOutcome() {
    if (task.period.status != TaskStatus.archived) return null;
    final done = task.period.doneAt;
    if (done == null) return 'failed';
    final deadline = DateTime.utc(
      task.period.periodEnd.year,
      task.period.periodEnd.month,
      task.period.periodEnd.day,
      23, 59, 59,
    );
    return done.isAfter(deadline) ? 'late' : 'ontime';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.period.status == TaskStatus.done;
    final isOverdue = task.period.status == TaskStatus.overdue;
    final isArchived = task.period.status == TaskStatus.archived;
    final archiveOutcome = _archiveOutcome();

    final recurringLabel = _recurringLabel();
    final targetDayLabel = _targetDayLabel();
    final deadlineLabel = _deadlineLabel();

    // Archive outcome colors — semantic, same across themes
    Color _outcomeColor(String? outcome) => switch (outcome) {
      'ontime' => context.colorSuccess,
      'late'   => context.colorYear,
      _        => context.colorDanger,
    };

    final card = InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox / outcome icon
            if (isArchived)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: _outcomeColor(archiveOutcome).withAlpha(56),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _outcomeColor(archiveOutcome), width: 1.5),
                ),
                child: Icon(
                  archiveOutcome == 'failed' ? Icons.close : Icons.check,
                  size: 13,
                  color: _outcomeColor(archiveOutcome),
                ),
              )
            else
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
                    color: isDone ? context.colorBrand : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDone ? context.colorBrand : context.colorBorder2,
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(Icons.check, size: 13, color: context.isDark ? AppColors.backgroundDark : Colors.white)
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
                      color: (isDone || isArchived) ? context.colorMuted2 : context.colorTextStrong,
                      decoration: (isDone || isArchived) ? TextDecoration.lineThrough : null,
                      decorationColor: context.colorMuted2,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.colorMuted),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Meta chips row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (showLevel) TaskLevelBadge(level: task.level),
                      if (isArchived) ...[
                        if (archiveOutcome == 'ontime')
                          _MetaChip('✓ выполнено', color: context.colorSuccess),
                        if (archiveOutcome == 'late')
                          _MetaChip('✓ с опозданием', color: context.colorYear),
                        if (archiveOutcome == 'failed')
                          _MetaChip('✗ не выполнено', color: context.colorDanger),
                      ] else ...[
                        if (recurringLabel != null)
                          _MetaChip(recurringLabel, color: context.colorMuted)
                        else ...[
                          if (task.scheduledTime != null)
                            _MetaChip('⏱ ${task.scheduledTime}', color: context.colorMuted),
                          if (targetDayLabel != null)
                            _MetaChip(targetDayLabel, color: context.colorMuted),
                        ],
                        if (deadlineLabel != null)
                          _MetaChip(deadlineLabel, color: context.colorMuted),
                        if (isOverdue)
                          _MetaChip('просрочено', color: context.colorWarning),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final container = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? context.colorWarning.withAlpha(96)
              : isArchived
                  ? context.colorBorder
                  : context.colorBorder,
        ),
        // Subtle offset shadow in light mode (matches web card style)
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 0,
                  offset: const Offset(2, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );

    if (isArchived) return container;

    return Dismissible(
      key: ValueKey('${task.period.id}_swipe'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onToggle();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: isDone
              ? context.colorMuted.withAlpha(56)
              : context.colorSuccess.withAlpha(56),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        child: Icon(
          isDone ? Icons.close : Icons.check,
          color: isDone ? context.colorMuted : context.colorSuccess,
        ),
      ),
      child: container,
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
        color: color ?? context.colorMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
