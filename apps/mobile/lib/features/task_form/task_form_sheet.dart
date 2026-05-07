import 'package:flutter/material.dart';
import '../../entities/task/task.dart';

class TaskFormSheet extends StatefulWidget {
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
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskLevel _level;
  String? _scheduledTime;
  String? _targetDate;
  int? _deadlineMonth;
  bool _recurring = false;
  int? _dayOfWeek;
  int? _dayOfMonth;

  bool get _isEdit => widget.existingTask != null;

  static const _dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  static const _monthNames = [
    'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
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
    _dayOfWeek = t?.recurringConfig?.dayOfWeek;
    _dayOfMonth = t?.recurringConfig?.dayOfMonth;
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
      final dow = now.weekday;
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
          if (_dayOfWeek != null) 'dayOfWeek': _dayOfWeek,
          if (_dayOfMonth != null) 'dayOfMonth': _dayOfMonth,
        },
    };

    widget.onSubmit(data);
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2428),
        title: const Text('Удалить задачу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: const Text('Удалить', style: TextStyle(color: Color(0xFFF87168))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
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
                color: const Color(0xFF3A4550),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Text(
                _isEdit ? 'Редактировать' : 'Новая задача',
                style: const TextStyle(
                  color: Color(0xFFE2E8ED), fontSize: 18, fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_isEdit && widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFF87168)),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          _Field(
            controller: _titleCtrl,
            label: 'Название',
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // Description
          _Field(
            controller: _descCtrl,
            label: 'Описание (необязательно)',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Level selector
          const Text('Уровень', style: TextStyle(color: Color(0xFF7A8A97), fontSize: 12)),
          const SizedBox(height: 6),
          _LevelSelector(
            value: _level,
            onChanged: (v) => setState(() {
              _level = v;
              _targetDate = null;
              _deadlineMonth = null;
              _dayOfWeek = null;
              _dayOfMonth = null;
            }),
          ),
          const SizedBox(height: 16),

          // Scheduled time (all levels)
          _TimePicker(
            label: 'Время (необязательно)',
            value: _scheduledTime,
            onChanged: (v) => setState(() => _scheduledTime = v),
          ),
          const SizedBox(height: 12),

          // Week: target day
          if (_level == TaskLevel.week) ...[
            _DropdownField<int?>(
              label: 'Планируемый день',
              value: _dayOfWeek,
              items: [
                const DropdownMenuItem(value: null, child: Text('Не указан')),
                for (int i = 1; i <= 6; i++)
                  DropdownMenuItem(value: i, child: Text(_dayNames[i])),
                DropdownMenuItem(value: 0, child: Text(_dayNames[0])),
              ],
              onChanged: (v) => setState(() => _dayOfWeek = v),
            ),
            const SizedBox(height: 12),
          ],

          // Year: deadline month
          if (_level == TaskLevel.year) ...[
            _DropdownField<int?>(
              label: 'Дедлайн-месяц',
              value: _deadlineMonth,
              items: [
                const DropdownMenuItem(value: null, child: Text('Не указан')),
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
            dayOfWeek: _dayOfWeek,
            dayOfMonth: _dayOfMonth,
            dayNames: _dayNames,
            onToggle: (v) => setState(() {
              _recurring = v;
              if (!v) { _dayOfWeek = null; _dayOfMonth = null; }
            }),
            onDayOfWeek: (v) => setState(() => _dayOfWeek = v),
            onDayOfMonth: (v) => setState(() => _dayOfMonth = v),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _titleCtrl.text.trim().isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF579DFF),
                disabledBackgroundColor: const Color(0xFF2E3740),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isEdit ? 'Сохранить' : 'Создать'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      style: const TextStyle(color: Color(0xFFE2E8ED), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A8A97), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF252C32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E3740)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E3740)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF579DFF)),
        ),
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  final TaskLevel value;
  final ValueChanged<TaskLevel> onChanged;

  static const _labels = {
    TaskLevel.day:   'День',
    TaskLevel.week:  'Неделя',
    TaskLevel.month: 'Месяц',
    TaskLevel.year:  'Год',
  };
  static const _colors = {
    TaskLevel.day:   Color(0xFF4BCE97),
    TaskLevel.week:  Color(0xFF579DFF),
    TaskLevel.month: Color(0xFF9F8FEF),
    TaskLevel.year:  Color(0xFFE2B203),
  };

  const _LevelSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                color: selected ? color.withOpacity(0.15) : const Color(0xFF252C32),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? color.withOpacity(0.6) : const Color(0xFF2E3740),
                ),
              ),
              child: Text(
                _labels[l]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? color : const Color(0xFF7A8A97),
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
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TimePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          color: const Color(0xFF252C32),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2E3740)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Color(0xFF7A8A97)),
            const SizedBox(width: 8),
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? const Color(0xFFE2E8ED) : const Color(0xFF7A8A97),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF7A8A97)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF252C32),
      style: const TextStyle(color: Color(0xFFE2E8ED), fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A8A97), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF252C32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E3740)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E3740)),
        ),
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  final bool enabled;
  final TaskLevel level;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final List<String> dayNames;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int?> onDayOfWeek;
  final ValueChanged<int?> onDayOfMonth;

  const _RecurringRow({
    required this.enabled,
    required this.level,
    required this.dayOfWeek,
    required this.dayOfMonth,
    required this.dayNames,
    required this.onToggle,
    required this.onDayOfWeek,
    required this.onDayOfMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Повторять', style: TextStyle(color: Color(0xFF7A8A97), fontSize: 13)),
            const Spacer(),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeColor: const Color(0xFF579DFF),
            ),
          ],
        ),
        if (enabled && level == TaskLevel.week)
          _DropdownField<int?>(
            label: 'День недели',
            value: dayOfWeek,
            items: [
              const DropdownMenuItem(value: null, child: Text('Начало недели')),
              for (int i = 1; i <= 6; i++)
                DropdownMenuItem(value: i, child: Text(dayNames[i])),
              DropdownMenuItem(value: 0, child: Text(dayNames[0])),
            ],
            onChanged: onDayOfWeek,
          ),
        if (enabled && level == TaskLevel.month)
          _DropdownField<int?>(
            label: 'День месяца',
            value: dayOfMonth,
            items: [
              const DropdownMenuItem(value: null, child: Text('1-й')),
              for (int i = 1; i <= 28; i++)
                DropdownMenuItem(value: i, child: Text('$i-й')),
            ],
            onChanged: onDayOfMonth,
          ),
      ],
    );
  }
}
