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

  // Subtasks (edit mode only)
  List<TaskWithPeriod> _subtasks = [];
  bool _subtasksLoaded = false;

  bool get _isEdit => widget.existingTask != null;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Mon-first, value = JS DOW (Sun=0, Mon=1…Sat=6)
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
    _targetDate = t?.period.targetDate;
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
      final dow = now.weekday; // 1=Mon…7=Sun
      return iso(now.subtract(Duration(days: dow - 1)));
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

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.dangerDark)),
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
      final api = ref.read(tasksApiProvider);
      await api.toggleTask(periodId, newStatus);
    } catch (_) {
      // revert
      if (mounted) setState(() { _subtasks[idx] = sub; });
    }
  }

  Future<void> _deleteSubtask(String taskId) async {
    final backup = [..._subtasks];
    setState(() => _subtasks = _subtasks.where((s) => s.id != taskId).toList());
    try {
      final api = ref.read(tasksApiProvider);
      await api.deleteTask(taskId);
    } catch (_) {
      if (mounted) setState(() => _subtasks = backup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Text(
                  _isEdit ? 'Edit task' : 'New task',
                  style: const TextStyle(
                    color: AppColors.textStrongDark, fontSize: 18, fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isEdit && widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.dangerDark),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            _Field(controller: _titleCtrl, label: 'Title', autofocus: true),
            const SizedBox(height: 12),

            // Description
            _Field(controller: _descCtrl, label: 'Description (optional)', maxLines: 3),
            const SizedBox(height: 16),

            // Level selector
            const Text('Level', style: TextStyle(color: AppColors.mutedDark, fontSize: 12)),
            const SizedBox(height: 6),
            _LevelSelector(
              value: _level,
              onChanged: (v) => setState(() {
                _level = v;
                _targetDate = null;
                _deadlineMonth = null;
                _daysOfWeek = [];
                _dayOfMonth = null;
              }),
            ),
            const SizedBox(height: 16),

            // Scheduled time
            _TimePicker(
              label: 'Time (optional)',
              value: _scheduledTime,
              onChanged: (v) => setState(() => _scheduledTime = v),
            ),
            const SizedBox(height: 12),

            // Year: deadline month
            if (_level == TaskLevel.year) ...[
              _DropdownField<int?>(
                label: 'Deadline month',
                value: _deadlineMonth,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No deadline')),
                  for (int i = 0; i < 12; i++)
                    DropdownMenuItem(value: i + 1, child: Text(_monthNames[i])),
                ],
                onChanged: (v) => setState(() => _deadlineMonth = v),
              ),
              const SizedBox(height: 12),
            ],

            // Recurring toggle
            _RecurringRow(
              enabled: _recurring,
              level: _level,
              daysOfWeek: _daysOfWeek,
              dayOfMonth: _dayOfMonth,
              dowOptions: _dowOptions,
              onToggle: (v) => setState(() {
                _recurring = v;
                if (!v) { _daysOfWeek = []; _dayOfMonth = null; }
              }),
              onToggleDay: _toggleDay,
              onDayOfMonth: (v) => setState(() => _dayOfMonth = v),
            ),

            // Subtasks (edit mode only)
            if (_isEdit) ...[
              const SizedBox(height: 20),
              _SubtasksSection(
                subtasks: _subtasks,
                loaded: _subtasksLoaded,
                parentLevel: _level,
                onAdd: _addSubtask,
                onToggle: _toggleSubtask,
                onDelete: _deleteSubtask,
              ),
            ],

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _titleCtrl.text.trim().isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  disabledBackgroundColor: AppColors.borderDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_isEdit ? 'Save' : 'Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Field ─────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool autofocus;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        autofocus: autofocus,
        style: const TextStyle(color: AppColors.textStrongDark, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedDark, fontSize: 13),
          filled: true,
          fillColor: AppColors.surface2Dark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brandDark),
          ),
        ),
      );
}

// ── Level selector ────────────────────────────────────────────────────────────

class _LevelSelector extends StatelessWidget {
  final TaskLevel value;
  final ValueChanged<TaskLevel> onChanged;

  static const _labels = {
    TaskLevel.day: 'Day', TaskLevel.week: 'Week',
    TaskLevel.month: 'Month', TaskLevel.year: 'Year',
  };
  static const _colors = {
    TaskLevel.day: AppColors.dayDark, TaskLevel.week: AppColors.weekDark,
    TaskLevel.month: AppColors.monthDark, TaskLevel.year: AppColors.yearDark,
  };

  const _LevelSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: TaskLevel.values.map((l) {
          final selected = l == value;
          final color = _colors[l]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(l),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.15) : AppColors.surface2Dark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? color.withOpacity(0.6) : AppColors.borderDark,
                  ),
                ),
                child: Text(
                  _labels[l]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? color : AppColors.mutedDark,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
}

// ── Time picker ───────────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TimePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: value != null
                ? TimeOfDay(
                    hour: int.parse(value!.split(':')[0]),
                    minute: int.parse(value!.split(':')[1]),
                  )
                : TimeOfDay.now(),
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (picked != null) {
            onChanged(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface2Dark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.mutedDark),
              const SizedBox(width: 8),
              Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? AppColors.textStrongDark : AppColors.mutedDark,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (value != null)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: const Icon(Icons.close, size: 16, color: AppColors.mutedDark),
                ),
            ],
          ),
        ),
      );
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: value, items: items, onChanged: onChanged,
        dropdownColor: AppColors.surface2Dark,
        style: const TextStyle(color: AppColors.textStrongDark, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedDark, fontSize: 13),
          filled: true, fillColor: AppColors.surface2Dark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
        ),
      );
}

// ── Recurring row ─────────────────────────────────────────────────────────────

class _RecurringRow extends StatelessWidget {
  final bool enabled;
  final TaskLevel level;
  final List<int> daysOfWeek;
  final int? dayOfMonth;
  final List<({int value, String label})> dowOptions;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onToggleDay;
  final ValueChanged<int?> onDayOfMonth;

  const _RecurringRow({
    required this.enabled, required this.level,
    required this.daysOfWeek, required this.dayOfMonth,
    required this.dowOptions, required this.onToggle,
    required this.onToggleDay, required this.onDayOfMonth,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Repeat', style: TextStyle(color: AppColors.mutedDark, fontSize: 13)),
              const Spacer(),
              Switch(value: enabled, onChanged: onToggle, activeColor: AppColors.brandDark),
            ],
          ),

          // Week: multi-day chip selector
          if (enabled && level == TaskLevel.week) ...[
            const SizedBox(height: 8),
            const Text('Days', style: TextStyle(color: AppColors.muted2Dark, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: dowOptions.map((d) {
                final selected = daysOfWeek.contains(d.value);
                final maxed = !selected && daysOfWeek.length >= 6;
                return GestureDetector(
                  onTap: maxed ? null : () => onToggleDay(d.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.weekSoftDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.weekDark : AppColors.borderDark,
                      ),
                    ),
                    child: Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected
                            ? AppColors.weekDark
                            : maxed ? AppColors.muted2Dark : AppColors.mutedDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Month: day of month
          if (enabled && level == TaskLevel.month) ...[
            const SizedBox(height: 8),
            _DropdownField<int?>(
              label: 'Day of month',
              value: dayOfMonth,
              items: [
                const DropdownMenuItem(value: null, child: Text('1st (default)')),
                for (int i = 1; i <= 28; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: onDayOfMonth,
            ),
          ],
        ],
      );
}

// ── Subtasks section ──────────────────────────────────────────────────────────

class _SubtasksSection extends StatefulWidget {
  final List<TaskWithPeriod> subtasks;
  final bool loaded;
  final TaskLevel parentLevel;
  final Future<void> Function(String title) onAdd;
  final Future<void> Function(String periodId) onToggle;
  final Future<void> Function(String taskId) onDelete;

  const _SubtasksSection({
    required this.subtasks, required this.loaded, required this.parentLevel,
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
    final done = widget.subtasks.where((s) => s.period.status == TaskStatus.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'SUBTASKS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.mutedDark),
            ),
            if (widget.subtasks.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.surface2Dark, borderRadius: BorderRadius.circular(8)),
                child: Text('$done/${widget.subtasks.length}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted2Dark)),
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
        else ...[
          for (final sub in widget.subtasks)
            _SubtaskRow(
              sub: sub,
              onToggle: () => widget.onToggle(sub.period.id),
              onDelete: () => widget.onDelete(sub.id),
            ),
        ],

        if (_adding)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textStrongDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Subtask title…',
                    hintStyle: const TextStyle(color: AppColors.mutedDark, fontSize: 13),
                    filled: true, fillColor: AppColors.surface2Dark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.weekDark)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.weekDark)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.weekDark)),
                  ),
                  onSubmitted: (v) async {
                    if (v.trim().isEmpty) return;
                    await widget.onAdd(v.trim());
                    _ctrl.clear();
                    if (mounted) setState(() => _adding = false);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.mutedDark),
                onPressed: () { _ctrl.clear(); setState(() => _adding = false); },
              ),
            ],
          )
        else
          TextButton.icon(
            onPressed: () => setState(() => _adding = true),
            icon: const Icon(Icons.add, size: 16, color: AppColors.mutedDark),
            label: const Text('Add subtask', style: TextStyle(color: AppColors.mutedDark, fontSize: 13)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: isDone ? AppColors.weekDark : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: isDone ? AppColors.weekDark : AppColors.border2Dark),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sub.title,
              style: TextStyle(
                fontSize: 13,
                color: isDone ? AppColors.mutedDark : AppColors.textDark,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 14, color: AppColors.muted2Dark),
          ),
        ],
      ),
    );
  }
}
