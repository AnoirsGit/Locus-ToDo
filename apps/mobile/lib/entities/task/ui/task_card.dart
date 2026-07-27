import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/theme.dart';
import '../../../shared/providers/tag_store.dart';
import '../task.dart';
import 'task_level_badge.dart';
import 'subtask_checklist.dart';

class TaskCard extends ConsumerWidget {
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

  static const _monthNamesFull = [
    '', 'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
    'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь',
  ];

  /// Period label shown on backlog/archive cards — mirrors web's
  /// `fmt`/`fmtMonth`/`fmtYear` (TaskCard.svelte).
  String _periodLabel() {
    final start = task.period.periodStart;
    final end = task.period.periodEnd;
    switch (task.level) {
      case TaskLevel.day:
        return '${start.day} ${_monthNames[start.month]}';
      case TaskLevel.week:
        return '${start.day} ${_monthNames[start.month]} – ${end.day} ${_monthNames[end.month]}';
      case TaskLevel.month:
        return '${_monthNamesFull[start.month]} ${start.year}';
      case TaskLevel.year:
        return '${start.year}';
    }
  }

  String? _doneAtLabel() {
    if (task.period.status != TaskStatus.archived) return null;
    final d = task.period.doneAt;
    if (d == null) return null;
    return '${d.day} ${_monthNames[d.month]} ${d.year}';
  }

  String? _backlogAge() {
    if (task.period.status != TaskStatus.backlog) return null;
    final backlogAt = task.period.backlogAt;
    if (backlogAt == null) return null;
    final days = DateTime.now().difference(backlogAt).inDays;
    if (days <= 0) return 'сегодня';
    if (days == 1) return 'день назад';
    if (days < 30) return '$days дней назад';
    final months = (days / 30).floor();
    return '$months мес. назад';
  }

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
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagStoreProvider).getTagsForTask(task.id);
    final isDone = task.period.status == TaskStatus.done;
    final isOverdue = task.period.status == TaskStatus.overdue;
    final isArchived = task.period.status == TaskStatus.archived;
    final isBacklog = task.period.status == TaskStatus.backlog;
    final archiveOutcome = _archiveOutcome();
    final doneAtLabel = _doneAtLabel();
    final backlogAge = _backlogAge();

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
                      // Strip HTML tags so the card shows plain-text preview
                      task.description!
                          .replaceAll(RegExp(r'<[^>]*>'), ' ')
                          .replaceAll(RegExp(r'\s+'), ' ')
                          .trim(),
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
                        _MetaChip(_periodLabel(), color: context.colorMuted),
                        if (archiveOutcome == 'ontime')
                          _MetaChip('✓ выполнено', color: context.colorSuccess),
                        if (archiveOutcome == 'late')
                          _MetaChip('✓ с опозданием', color: context.colorYear),
                        if (archiveOutcome == 'failed')
                          _MetaChip('✗ не выполнено', color: context.colorDanger),
                        if (doneAtLabel != null)
                          _MetaChip('· $doneAtLabel', color: context.colorMuted),
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
                        if (isBacklog) ...[
                          _MetaChip(_periodLabel(), color: context.colorMuted),
                          if (backlogAge != null)
                            _MetaChip('· $backlogAge', color: context.colorMuted),
                        ],
                      ],
                    ],
                  ),

                  // Tag chips
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: tags.map((tag) {
                        final color = tag.color != null
                            ? _parseHexColor(tag.color!)
                            : context.colorMuted;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(28),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: color.withAlpha(90)),
                          ),
                          child: Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Subtask expander — hidden for archived and backlog cards
                  if (!isArchived && task.period.status != TaskStatus.backlog)
                    _SubtaskSection(task: task),
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

Color _parseHexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  final value = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return value != null ? Color(value) : const Color(0xFF888888);
}

// ── Subtask expander ─────────────────────────────────────────────────────────

class _SubtaskSection extends ConsumerStatefulWidget {
  final TaskWithPeriod task;
  const _SubtaskSection({required this.task});

  @override
  ConsumerState<_SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends ConsumerState<_SubtaskSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: context.colorMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  'Подзадачи',
                  style: TextStyle(fontSize: 11, color: context.colorMuted),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          SubtaskChecklist(
            parentTaskId: widget.task.id,
            parentLevel: widget.task.level,
            parentPeriodStart: widget.task.period.periodStart,
          ),
      ],
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
