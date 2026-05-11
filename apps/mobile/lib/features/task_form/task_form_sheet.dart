import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/task.dart';
import '../../shared/api/tasks_api.dart';
import '../../shared/theme/theme.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  final TaskWithPeriod? existingTask;
  final TaskLevel defaultLevel;
  final String defaultPeriodStart;
  final void Function(Map<String, dynamic> data) onSubmit;
  final VoidCallback? onDelete;

  const TaskFormSheet({
    super.key,
    this.existingTask,
    required this.defaultLevel,
    required this.defaultPeriodStart,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskLevel _level;
  String? _scheduledTime;
  String? _targetDate;
  int? _deadlineMonth;
  bool _recurring = false;
  List<int> _daysOfWeek = [];
  int? _dayOfMonth;

  List<TaskWithPeriod> _subtasks = [];
  bool _subtasksLoaded = false;

  bool get _isEdit => widget.existingTask != null;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _dowOptions = [
    (value: 1, label: 'Mon'), (value: 2, label: 'Tue'),
    (value: 3, label: 'Wed'), (value: 4, label: 'Thu'),
    (value: 5, label: 'Fri'), (value: 6, label: 'Sat'),
    (value: 0, label: 'Sun'),
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl  = TextEditingController(text: t?.description ?? '');
    _level = t?.level ?? widget.defaultLevel;
    _scheduledTime = t?.scheduledTime;
    _targetDate = t?.period.targetDate?.split('T')[0];
    _deadlineMonth = t?.period.deadlineMonth;
    _recurring = t?.recurringConfig != null;
    _daysOfWeek = List<int>.from(t?.recurringConfig?.daysOfWeek ?? []);
    _dayOfMonth = t?.recurringConfig?.dayOfMonth;
    if (_isEdit) _loadSubtasks();
  }

  Future<void> _loadSubtasks() async {
    try {
      final api = ref.read(tasksApiProvider);
      final subs = await api.getSubtasks(widget.existingTask!.id);
      if (mounted) setState(() { _subtasks = subs; _subtasksLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _subtasksLoaded = true);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _periodStart() {
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String().split('T')[0];
    if (_level == TaskLevel.day) return widget.defaultPeriodStart;
    if (_level == TaskLevel.week) {
      return iso(now.subtract(Duration(days: now.weekday - 1)));
    }
    if (_level == TaskLevel.month) return iso(DateTime(now.year, now.month, 1));
    return '${now.year}-01-01';
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final data = <String, dynamic>{
      'title': title,
      'level': _level.name,
      'periodStart': _periodStart(),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      if (_scheduledTime != null) 'scheduledTime': _scheduledTime,
      if (_level == TaskLevel.week && _targetDate != null) 'targetDate': _targetDate,
      if (_level == TaskLevel.year && _deadlineMonth != null) 'deadlineMonth': _deadlineMonth,
      if (_recurring)
        'recurringConfig': {
          'isActive': true,
          if (_level == TaskLevel.week && _daysOfWeek.isNotEmpty) 'daysOfWeek': _daysOfWeek,
          if (_level == TaskLevel.month && _dayOfMonth != null) 'dayOfMonth': _dayOfMonth,
        },
    };
    widget.onSubmit(data);
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete task?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colorTextStrong)),
        content: Text('This cannot be undone.', style: TextStyle(fontSize: 13, color: context.colorMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.colorText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: Text('Delete', style: TextStyle(color: context.colorDanger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _toggleDay(int dow) {
    setState(() {
      if (_daysOfWeek.contains(dow)) {
        _daysOfWeek = _daysOfWeek.where((d) => d != dow).toList();
      } else if (_daysOfWeek.length < 6) {
        _daysOfWeek = [..._daysOfWeek, dow];
      }
    });
  }

  Future<void> _addSubtask(String title) async {
    try {
      final api = ref.read(tasksApiProvider);
      final sub = await api.createTask({
        'title': title,
        'level': _level.name,
        'periodStart': widget.existingTask!.period.periodStart.toIso8601String().split('T')[0],
        'parentTaskId': widget.existingTask!.id,
      });
      if (mounted) setState(() => _subtasks = [..._subtasks, sub]);
    } catch (_) {}
  }

  Future<void> _toggleSubtask(String periodId) async {
    final idx = _subtasks.indexWhere((s) => s.period.id == periodId);
    if (idx < 0) return;
    final sub = _subtasks[idx];
    final newStatus = sub.period.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;
    setState(() {
      _subtasks = [..._subtasks];
      _subtasks[idx] = sub.copyWithPeriod(sub.period.copyWith(status: newStatus));
    });
    try {
      await ref.read(tasksApiProvider).toggleTask(periodId, newStatus);
    } catch (_) {
      if (mounted) setState(() { _subtasks[idx] = sub; });
    }
  }

  Future<void> _deleteSubtask(String taskId) async {
    final backup = [..._subtasks];
    setState(() => _subtasks = _subtasks.where((s) => s.id != taskId).toList());
    try {
      await ref.read(tasksApiProvider).deleteTask(taskId);
    } catch (_) {
      if (mounted) setState(() => _subtasks = backup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isValid = _titleCtrl.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.colorBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                // Status badge for edit mode
                if (_isEdit) ...[
                  _StatusBadge(task: widget.existingTask!, context: context),
                  const SizedBox(width: 8),
                ] else
                  Text(
                    'New task',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.colorMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                const Spacer(),
                if (_isEdit && widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: context.colorDanger),
                    onPressed: _confirmDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: context.colorMuted),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title — large, borderless
                  TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: context.colorTextStrong,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: context.colorBorder2,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                  ),

                  // Description — subtle, borderless
                  TextField(
                    controller: _descCtrl,
                    style: TextStyle(fontSize: 14, color: context.colorText, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Add description…',
                      hintStyle: TextStyle(fontSize: 14, color: context.colorMuted2),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),

                  const SizedBox(height: 20),
                  Divider(color: context.colorBorder, height: 1),
                  const SizedBox(height: 4),

                  // ── Details section label ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: context.colorMuted2,
                      ),
                    ),
                  ),

                  // Level
                  _DetailRow(
                    icon: Icons.layers_outlined,
                    label: 'Level',
                    child: _LevelPills(
                      value: _level,
                      onChanged: (v) => setState(() {
                        _level = v;
                        _targetDate = null;
                        _deadlineMonth = null;
                        _daysOfWeek = [];
                        _dayOfMonth = null;
                      }),
                      context: context,
                    ),
                  ),

                  // Time
                  if (_level == TaskLevel.day || _level == TaskLevel.week)
                    _DetailRow(
                      icon: Icons.access_time_outlined,
                      label: 'Time',
                      child: _TimeButton(
                        value: _scheduledTime,
                        onChanged: (v) => setState(() => _scheduledTime = v),
                        context: context,
                      ),
                    ),

                  // Target day (week only)
                  if (_level == TaskLevel.week)
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Target day',
                      child: _DateButton(
                        value: _targetDate,
                        onChanged: (v) => setState(() => _targetDate = v),
                        context: context,
                      ),
                    ),

                  // Deadline month (year only)
                  if (_level == TaskLevel.year)
                    _DetailRow(
                      icon: Icons.flag_outlined,
                      label: 'Deadline',
                      child: _MonthDropdown(
                        value: _deadlineMonth,
                        monthNames: _monthNames,
                        onChanged: (v) => setState(() => _deadlineMonth = v),
                        context: context,
                      ),
                    ),

                  // Recurring
                  _DetailRow(
                    icon: Icons.repeat_outlined,
                    label: 'Recurring',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_recurring && _level != TaskLevel.week)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _recurringHint(_level),
                              style: TextStyle(fontSize: 12, color: context.colorMuted),
                            ),
                          ),
                        Switch(
                          value: _recurring,
                          onChanged: (v) => setState(() {
                            _recurring = v;
                            if (!v) { _daysOfWeek = []; _dayOfMonth = null; }
                          }),
                          activeColor: context.colorBrand,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),

                  // Week recurring — day chips
                  if (_recurring && _level == TaskLevel.week)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 4),
                      child: _DowChips(
                        selected: _daysOfWeek,
                        options: _dowOptions,
                        onToggle: _toggleDay,
                        context: context,
                      ),
                    ),

                  // Month recurring — day of month
                  if (_recurring && _level == TaskLevel.month)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 4),
                      child: _DayOfMonthRow(
                        value: _dayOfMonth,
                        onChanged: (v) => setState(() => _dayOfMonth = v),
                        context: context,
                      ),
                    ),

                  // Subtasks (edit only)
                  if (_isEdit) ...[
                    const SizedBox(height: 8),
                    Divider(color: context.colorBorder, height: 1),
                    const SizedBox(height: 8),
                    _SubtasksSection(
                      subtasks: _subtasks,
                      loaded: _subtasksLoaded,
                      onAdd: _addSubtask,
                      onToggle: _toggleSubtask,
                      onDelete: _deleteSubtask,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Submit bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: context.colorSurface,
              border: Border(top: BorderSide(color: context.colorBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorBrand,
                  disabledBackgroundColor: context.colorSurface2,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: context.colorMuted2,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _isEdit ? 'Save changes' : 'Create task',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _recurringHint(TaskLevel level) => switch (level) {
    TaskLevel.day   => 'Every day',
    TaskLevel.week  => 'Every week',
    TaskLevel.month => 'Every month',
    TaskLevel.year  => 'Every year',
  };
}

// ── Status badge (edit header) ─────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TaskWithPeriod task;
  final BuildContext context;
  const _StatusBadge({required this.task, required this.context});

  static const _labels = {
    TaskStatus.todo:     'To do',
    TaskStatus.done:     'Done',
    TaskStatus.overdue:  'Overdue',
    TaskStatus.backlog:  'Backlog',
    TaskStatus.archived: 'Archived',
  };

  @override
  Widget build(BuildContext ctx) {
    final levelColor = switch (task.level) {
      TaskLevel.day   => context.colorDay,
      TaskLevel.week  => context.colorWeek,
      TaskLevel.month => context.colorMonth,
      TaskLevel.year  => context.colorYear,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: levelColor.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: levelColor.withAlpha(80)),
          ),
          child: Text(
            task.level.name[0].toUpperCase() + task.level.name.substring(1),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: levelColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _labels[task.period.status] ?? task.period.status.name,
          style: TextStyle(fontSize: 12, color: context.colorMuted),
        ),
      ],
    );
  }
}

// ── Detail row ─────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DetailRow({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: context.colorMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.colorMuted),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Level pills ────────────────────────────────────────────────────────────────

class _LevelPills extends StatelessWidget {
  final TaskLevel value;
  final ValueChanged<TaskLevel> onChanged;
  final BuildContext context;

  static const _labels = {
    TaskLevel.day: 'Day', TaskLevel.week: 'Week',
    TaskLevel.month: 'Month', TaskLevel.year: 'Year',
  };

  const _LevelPills({required this.value, required this.onChanged, required this.context});

  Color _levelColor(TaskLevel l) => switch (l) {
    TaskLevel.day   => context.colorDay,
    TaskLevel.week  => context.colorWeek,
    TaskLevel.month => context.colorMonth,
    TaskLevel.year  => context.colorYear,
  };

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TaskLevel.values.map((l) {
        final selected = l == value;
        final color = _levelColor(l);
        return GestureDetector(
          onTap: () => onChanged(l),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(right: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? color.withAlpha(30) : context.colorSurface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color.withAlpha(160) : context.colorBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              _labels[l]!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : context.colorMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Time button ────────────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final BuildContext context;

  const _TimeButton({required this.value, required this.onChanged, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime: value != null
                  ? TimeOfDay(hour: int.parse(value!.split(':')[0]), minute: int.parse(value!.split(':')[1]))
                  : TimeOfDay.now(),
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (picked != null) {
              onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: value != null ? context.colorBrandSoft : context.colorSurface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value != null ? context.colorBrand.withAlpha(100) : context.colorBorder,
              ),
            ),
            child: Text(
              value ?? 'Set time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value != null ? context.colorBrand2 : context.colorMuted,
              ),
            ),
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onChanged(null),
            child: Icon(Icons.close, size: 14, color: context.colorMuted),
          ),
        ],
      ],
    );
  }
}

// ── Date button ────────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final BuildContext context;

  const _DateButton({required this.value, required this.onChanged, required this.context});

  String _display(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: value != null ? DateTime.tryParse(value!) ?? now : now,
              firstDate: now.subtract(const Duration(days: 30)),
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              onChanged(picked.toIso8601String().split('T')[0]);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: value != null ? context.colorBrandSoft : context.colorSurface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value != null ? context.colorBrand.withAlpha(100) : context.colorBorder,
              ),
            ),
            child: Text(
              value != null ? _display(value!) : 'Set date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value != null ? context.colorBrand2 : context.colorMuted,
              ),
            ),
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onChanged(null),
            child: Icon(Icons.close, size: 14, color: context.colorMuted),
          ),
        ],
      ],
    );
  }
}

// ── Month dropdown ─────────────────────────────────────────────────────────────

class _MonthDropdown extends StatelessWidget {
  final int? value;
  final List<String> monthNames;
  final ValueChanged<int?> onChanged;
  final BuildContext context;

  const _MonthDropdown({
    required this.value, required this.monthNames,
    required this.onChanged, required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int?>(
        value: value,
        isDense: true,
        dropdownColor: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        style: TextStyle(fontSize: 13, color: context.colorText),
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.colorMuted),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('No deadline', style: TextStyle(color: context.colorMuted, fontSize: 13)),
          ),
          for (int i = 0; i < 12; i++)
            DropdownMenuItem(
              value: i + 1,
              child: Text(monthNames[i], style: TextStyle(fontSize: 13, color: context.colorText)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Day-of-week chips ──────────────────────────────────────────────────────────

class _DowChips extends StatelessWidget {
  final List<int> selected;
  final List<({int value, String label})> options;
  final ValueChanged<int> onToggle;
  final BuildContext context;

  const _DowChips({
    required this.selected, required this.options,
    required this.onToggle, required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 6, runSpacing: 6,
        children: options.map((d) {
          final isSelected = selected.contains(d.value);
          final maxed = !isSelected && selected.length >= 6;
          return GestureDetector(
            onTap: maxed ? null : () => onToggle(d.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? context.colorWeek.withAlpha(30) : context.colorSurface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? context.colorWeek.withAlpha(160) : context.colorBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                d.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? context.colorWeek : maxed ? context.colorMuted2 : context.colorMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Day of month row ───────────────────────────────────────────────────────────

class _DayOfMonthRow extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final BuildContext context;

  const _DayOfMonthRow({required this.value, required this.onChanged, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int?>(
        value: value,
        isDense: true,
        dropdownColor: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        hint: Text('Day 1 (default)', style: TextStyle(fontSize: 13, color: context.colorMuted)),
        style: TextStyle(fontSize: 13, color: context.colorText),
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.colorMuted),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('Day 1 (default)', style: TextStyle(color: context.colorMuted, fontSize: 13)),
          ),
          for (int i = 2; i <= 28; i++)
            DropdownMenuItem(
              value: i,
              child: Text('Day $i', style: TextStyle(fontSize: 13, color: context.colorText)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Subtasks section ───────────────────────────────────────────────────────────

class _SubtasksSection extends StatefulWidget {
  final List<TaskWithPeriod> subtasks;
  final bool loaded;
  final Future<void> Function(String title) onAdd;
  final Future<void> Function(String periodId) onToggle;
  final Future<void> Function(String taskId) onDelete;

  const _SubtasksSection({
    required this.subtasks, required this.loaded,
    required this.onAdd, required this.onToggle, required this.onDelete,
  });

  @override
  State<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends State<_SubtasksSection> {
  bool _adding = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final doneCount = widget.subtasks.where((s) => s.period.status == TaskStatus.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SUBTASKS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: context.colorMuted2),
            ),
            if (widget.subtasks.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: context.colorSurface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$doneCount/${widget.subtasks.length}',
                  style: TextStyle(fontSize: 11, color: context.colorMuted),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        if (!widget.loaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else
          for (final sub in widget.subtasks)
            _SubtaskRow(
              sub: sub,
              onToggle: () => widget.onToggle(sub.period.id),
              onDelete: () => widget.onDelete(sub.id),
            ),

        const SizedBox(height: 4),

        if (_adding)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: TextStyle(fontSize: 13, color: context.colorText),
                  decoration: InputDecoration(
                    hintText: 'Subtask title…',
                    hintStyle: TextStyle(fontSize: 13, color: context.colorMuted2),
                    filled: true,
                    fillColor: context.colorSurface2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colorBrand.withAlpha(150)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colorBrand, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colorBorder),
                    ),
                  ),
                  onSubmitted: (v) async {
                    if (v.trim().isEmpty) return;
                    await widget.onAdd(v.trim());
                    _ctrl.clear();
                    if (mounted) setState(() => _adding = false);
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () { _ctrl.clear(); setState(() => _adding = false); },
                child: Icon(Icons.close, size: 18, color: context.colorMuted),
              ),
            ],
          )
        else
          InkWell(
            onTap: () => setState(() => _adding = true),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15, color: context.colorMuted),
                  const SizedBox(width: 6),
                  Text('Add subtask', style: TextStyle(fontSize: 13, color: context.colorMuted)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final TaskWithPeriod sub;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskRow({required this.sub, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDone = sub.period.status == TaskStatus.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 17, height: 17,
              decoration: BoxDecoration(
                color: isDone ? context.colorBrand : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDone ? context.colorBrand : context.colorBorder2,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? Icon(Icons.check, size: 11,
                      color: context.isDark ? AppColors.backgroundDark : Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sub.title,
              style: TextStyle(
                fontSize: 13,
                color: isDone ? context.colorMuted : context.colorText,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: context.colorMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 14, color: context.colorMuted2),
          ),
        ],
      ),
    );
  }
}
