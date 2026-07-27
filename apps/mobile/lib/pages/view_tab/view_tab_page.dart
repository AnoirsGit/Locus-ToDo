import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../entities/task/grouped_tasks_notifier.dart';
import '../../entities/task/task.dart';
import '../../entities/task/ui/tag_filter_bar.dart';
import '../../entities/task/ui/task_card.dart';
import '../../features/task_form/task_form_sheet.dart';
import '../../pages/app_shell.dart';
import '../../shared/providers/tag_store.dart';
import '../../shared/providers/view_provider.dart';
import '../../shared/theme/theme.dart';

// ── View tab page ──────────────────────────────────────────────────────────────

class ViewTabPage extends ConsumerStatefulWidget {
  const ViewTabPage({super.key});

  @override
  ConsumerState<ViewTabPage> createState() => _ViewTabPageState();
}

class _ViewTabPageState extends ConsumerState<ViewTabPage> {
  int _weekOffset = 0;

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _periodStart(String view) {
    final now = DateTime.now();
    if (view == 'day') return _iso(now);
    if (view == 'week') {
      final mon = now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: 7 * _weekOffset));
      return _iso(mon);
    }
    if (view == 'month') return _iso(DateTime(now.year, now.month, 1));
    return '${now.year}-01-01';
  }

  TaskLevel _defaultLevel(String view) => switch (view) {
        'month' => TaskLevel.month,
        'year'  => TaskLevel.year,
        'week'  => TaskLevel.week,
        _       => TaskLevel.day,
      };

  void _openCreate(String view) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => TaskFormSheet(
        defaultLevel: _defaultLevel(view),
        defaultPeriodStart: _periodStart(view),
        onSubmit: (data) =>
            ref.read(groupedTasksProvider(view).notifier).createTask(data),
      ),
    );
  }

  void _openCreateForDate(String dateStr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => TaskFormSheet(
        defaultLevel: TaskLevel.day,
        defaultPeriodStart: dateStr,
        onSubmit: (data) =>
            ref.read(groupedTasksProvider('week').notifier).createTask(data),
      ),
    );
  }

  void _openEdit(String view, TaskWithPeriod task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => TaskFormSheet(
        existingTask: task,
        defaultLevel: task.level,
        defaultPeriodStart: task.period.periodStart.toIso8601String().split('T')[0],
        onSubmit: (data) =>
            ref.read(groupedTasksProvider(view).notifier).updateTask(task.id, data),
        onDelete: () =>
            ref.read(groupedTasksProvider(view).notifier).deleteTask(task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(activeViewProvider);
    final provider = groupedTasksProvider(view);
    final grouped = ref.watch(provider);

    return Scaffold(
      appBar: _buildAppBar(context, view),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(view),
        child: const Icon(Icons.add),
      ),
      body: grouped.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ошибка: $err', style: TextStyle(color: context.colorMuted)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(provider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (data) {
          // For week kanban: also load day-level tasks so they appear in columns
          final dayTasks = view == 'week'
              ? ref.watch(groupedTasksProvider('day')).valueOrNull?.primary ?? []
              : <TaskWithPeriod>[];

          return RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(),
            color: context.colorBrand,
            backgroundColor: context.colorSurface,
            child: switch (view) {
              'day'  => _TodayBody(data: data, onToggle: (t) => ref.read(provider.notifier).toggle(t), onEdit: (t) => _openEdit(view, t), onCreate: () => _openCreate(view)),
              'week' => _WeekKanban(data: data, dayTasks: dayTasks, weekOffset: _weekOffset, onOffsetChanged: (o) => setState(() => _weekOffset = o), onToggle: (t) => ref.read(provider.notifier).toggle(t), onEdit: (t) => _openEdit(view, t), onCreate: () => _openCreate(view), onCreateDay: _openCreateForDate),
              _      => _GenericBody(view: view, data: data, onToggle: (t) => ref.read(provider.notifier).toggle(t), onEdit: (t) => _openEdit(view, t), onCreate: () => _openCreate(view)),
            },
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String view) {
    return AppBar(
      leadingWidth: 120,
      // Brand "Locus ·" on the left — matches web mobile header
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Locus',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: context.colorTextStrong,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorBrand,
              ),
            ),
          ],
        ),
      ),
      // View dropdown + hamburger on the right
      actions: [
        _ViewDropdown(
          view: view,
          onChanged: (v) {
            ref.read(activeViewProvider.notifier).setView(v);
            if (v != 'week') setState(() => _weekOffset = 0);
          },
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── View dropdown button ───────────────────────────────────────────────────────

class _ViewDropdown extends StatelessWidget {
  final String view;
  final void Function(String) onChanged;

  static const _labels = {
    'day':   'День',
    'week':  'Неделя',
    'month': 'Месяц',
    'year':  'Год',
  };

  const _ViewDropdown({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: view,
      onSelected: onChanged,
      color: context.colorCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.colorBorder),
      ),
      itemBuilder: (_) => _labels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: e.key == view ? FontWeight.w600 : FontWeight.w400,
                    color: e.key == view ? context.colorBrand : context.colorText,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: context.colorSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labels[view] ?? view,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colorText,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down, size: 15, color: context.colorMuted),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TODAY BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _TodayBody extends ConsumerWidget {
  final GroupedTasks data;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod) onEdit;
  final VoidCallback onCreate;

  const _TodayBody({
    required this.data,
    required this.onToggle,
    required this.onEdit,
    required this.onCreate,
  });

  static const _quietWords = [
    'quietly', 'focused', 'steady', 'present', 'clear', 'sharp', 'grounded',
  ];

  static const _monthNamesRu = [
    '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static const _dayNamesRu = [
    '', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
  ];

  String get _eyebrow {
    final now = DateTime.now();
    final weekNum = _weekNumber(now);
    return '${_dayNamesRu[now.weekday]} · ${now.day} ${_monthNamesRu[now.month]} ${now.year} г. · Неделя $weekNum';
  }

  String get _quietWord =>
      _quietWords[DateTime.now().weekday % _quietWords.length];

  int _weekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    return ((date.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagStoreProvider);
    final filtered = tagState.filterTasks(data.primary, (t) => t.id);
    final filteredWeek = tagState.filterTasks(data.week, (t) => t.id);
    final filteredMonth = tagState.filterTasks(data.month, (t) => t.id);
    final filteredYear = tagState.filterTasks(data.year, (t) => t.id);
    final total = filtered.length;
    final done = filtered.where((t) => t.period.status == TaskStatus.done).length;
    final overdue = filtered.where((t) => t.period.status == TaskStatus.overdue).length;
    final pct = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _eyebrow.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: context.colorMuted,
                ),
              ),
              const SizedBox(height: 8),
              // "Сегодня, focused." — serif italic to match web
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Сегодня, ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Georgia',
                        color: context.colorTextStrong,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: _quietWord,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Georgia',
                        color: context.colorBrand,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: '.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Georgia',
                        color: context.colorTextStrong,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(color: context.colorBorder, indent: 20, endIndent: 20),
        const SizedBox(height: 4),

        // ── Progress card ────────────────────────────────────────────────
        if (total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colorCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colorBorder),
                boxShadow: context.isDark
                    ? null
                    : [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 0, offset: const Offset(2, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$done / $total',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorTextStrong),
                            ),
                            Text(
                              'ВЫПОЛНЕНО',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: context.colorMuted),
                            ),
                          ],
                        ),
                      ),
                      if (overdue > 0) ...[
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$overdue',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorWarning),
                            ),
                            Text(
                              'ШТРАФЫ',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: context.colorWarning),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colorDay),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: context.colorDaySoft,
                                valueColor: AlwaysStoppedAnimation<Color>(context.colorDay),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // ── Tag filter ───────────────────────────────────────────────────
        if (tagState.tags.isNotEmpty)
          TagFilterBar(
            tagState: tagState,
            onToggle: (id) => ref.read(tagStoreProvider.notifier).toggleFilterTag(id),
            onClear: () => ref.read(tagStoreProvider.notifier).clearFilter(),
          ),

        // ── Day tasks ────────────────────────────────────────────────────
        if (filtered.isEmpty && tagState.isFiltering)
          _emptyFiltered(context, ref)
        else
          ...filtered.map((task) => TaskCard(
                task: task,
                onToggle: () => onToggle(task),
                onEdit: () => onEdit(task),
              )),

        // Inline create button — always visible like web
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: InkWell(
            onTap: onCreate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.colorCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colorBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: context.colorMuted),
                  const SizedBox(width: 8),
                  Text(
                    '+ Добавить задачу на сегодня',
                    style: TextStyle(fontSize: 13, color: context.colorMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Context sections ─────────────────────────────────────────────
        if (filteredWeek.isNotEmpty)
          _CollapsibleSection(
            title: 'Цели недели · контекст',
            tasks: filteredWeek,
            storageKey: 'today:week',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
        if (filteredMonth.isNotEmpty)
          _CollapsibleSection(
            title: 'Цели месяца · контекст',
            tasks: filteredMonth,
            storageKey: 'today:month',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
        if (filteredYear.isNotEmpty)
          _CollapsibleSection(
            title: 'Цели года · контекст',
            tasks: filteredYear,
            storageKey: 'today:year',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
      ],
    );
  }
}

/// Shown instead of the plain "no tasks" state when the empty list is caused
/// by an active tag filter — offers "clear filter" instead of "create task",
/// matching web's `tagStore.isFiltering` branch (TaskList/today +page).
Widget _emptyFiltered(BuildContext context, WidgetRef ref) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Text('Нет задач по фильтру', style: TextStyle(color: context.colorMuted)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(tagStoreProvider.notifier).clearFilter(),
            child: const Text('Очистить фильтр'),
          ),
        ],
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// WEEK KANBAN
// ═══════════════════════════════════════════════════════════════════════════════

class _WeekKanban extends ConsumerWidget {
  final GroupedTasks data;
  final List<TaskWithPeriod> dayTasks;
  final int weekOffset;
  final void Function(int) onOffsetChanged;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod) onEdit;
  final VoidCallback onCreate;
  final void Function(String dateStr) onCreateDay;

  const _WeekKanban({
    required this.data,
    required this.dayTasks,
    required this.weekOffset,
    required this.onOffsetChanged,
    required this.onToggle,
    required this.onEdit,
    required this.onCreate,
    required this.onCreateDay,
  });

  static const _dayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _monthShort = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  DateTime get _monday {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: 7 * weekOffset));
  }

  String get _weekLabel {
    final mon = _monday;
    final sun = mon.add(const Duration(days: 6));
    if (mon.month == sun.month) {
      return '${mon.day}–${sun.day} ${_monthShort[mon.month]} ${mon.year}';
    }
    return '${mon.day} ${_monthShort[mon.month]} – ${sun.day} ${_monthShort[sun.month]} ${mon.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagStoreProvider);
    final filteredWeek = tagState.filterTasks(data.primary, (t) => t.id);
    final filteredDay = tagState.filterTasks(dayTasks, (t) => t.id);
    final filteredMonth = tagState.filterTasks(data.month, (t) => t.id);
    final filteredYear = tagState.filterTasks(data.year, (t) => t.id);
    final now = DateTime.now();
    final monday = _monday;
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    // Group week tasks by targetDate (normalize ISO string to date-only)
    final Map<String, List<TaskWithPeriod>> byDay = {};
    final List<TaskWithPeriod> unassigned = [];

    for (final task in filteredWeek) {
      final td = task.period.targetDate?.split('T')[0];
      if (td != null) {
        byDay[td] = [...(byDay[td] ?? []), task];
      } else {
        unassigned.add(task);
      }
    }

    // Add day-level tasks into columns by their periodStart date
    for (final task in filteredDay) {
      final dateStr = task.period.periodStart.toIso8601String().split('T')[0];
      byDay[dateStr] = [...(byDay[dateStr] ?? []), task];
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // ── Week header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ГОРИЗОНТ · НЕДЕЛЯ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: context.colorMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Неделя.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Georgia',
                  color: context.colorTextStrong,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              // Navigation row: [<] 11–17 май 2026 [>]
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left,
                    onTap: () => onOffsetChanged(weekOffset - 1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _weekLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: context.colorText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NavArrow(
                    icon: Icons.chevron_right,
                    onTap: () => onOffsetChanged(weekOffset + 1),
                  ),
                  if (weekOffset != 0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onOffsetChanged(0),
                      child: Text(
                        'Сегодня',
                        style: TextStyle(fontSize: 12, color: context.colorBrand, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        Divider(color: context.colorBorder, indent: 20, endIndent: 20),
        const SizedBox(height: 16),

        // ── "По дням" section label ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Text(
                'По дням',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  color: context.colorTextStrong,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Divider(color: context.colorBorder, indent: 20, endIndent: 20),
        const SizedBox(height: 8),

        // ── Kanban columns ───────────────────────────────────────────────
        SizedBox(
          height: 460,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            itemBuilder: (ctx, i) {
              final colWidth = MediaQuery.of(ctx).size.width * 0.85;
              final day = days[i];
              final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final columnTasks = byDay[dateStr] ?? [];
              final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
              return _DayColumn(
                width: colWidth,
                dayName: _dayShort[i],
                dayNumber: day.day,
                tasks: columnTasks,
                isToday: isToday,
                onToggle: onToggle,
                onEdit: onEdit,
                onCreate: () => onCreateDay(dateStr),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Week tasks (always shown) ─────────────────────────────────────
        _CollapsibleSection(
          title: 'Задачи недели',
          tasks: unassigned,
          storageKey: 'week:goals',
          onToggle: onToggle,
          onEdit: onEdit,
          addButton: onCreate,
        ),

        // ── Tag filter ───────────────────────────────────────────────────
        if (tagState.tags.isNotEmpty)
          TagFilterBar(
            tagState: tagState,
            onToggle: (id) => ref.read(tagStoreProvider.notifier).toggleFilterTag(id),
            onClear: () => ref.read(tagStoreProvider.notifier).clearFilter(),
          ),

        // ── Context sections ─────────────────────────────────────────────
        if (filteredMonth.isNotEmpty)
          _CollapsibleSection(
            title: 'Задачи месяца · контекст',
            tasks: filteredMonth,
            storageKey: 'week:month',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
        if (filteredYear.isNotEmpty)
          _CollapsibleSection(
            title: 'Задачи года · контекст',
            tasks: filteredYear,
            storageKey: 'week:year',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.colorSurface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.colorBorder),
        ),
        child: Icon(icon, size: 16, color: context.colorMuted),
      ),
    );
  }
}

// ── Day column (kanban) ────────────────────────────────────────────────────────

class _DayColumn extends StatelessWidget {
  final double width;
  final String dayName;
  final int dayNumber;
  final List<TaskWithPeriod> tasks;
  final bool isToday;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod) onEdit;
  final VoidCallback onCreate;

  const _DayColumn({
    required this.width,
    required this.dayName,
    required this.dayNumber,
    required this.tasks,
    required this.isToday,
    required this.onToggle,
    required this.onEdit,
    required this.onCreate,
  });

  // Today header bg: day-tint (light) / brand-soft (dark) — matches web
  Color _headerBg(BuildContext context) =>
      isToday ? (context.isDark ? context.colorBrandSoft : context.colorDayTint) : Colors.transparent;

  // Today circle bg: day (light) / brand (dark) — matches web
  Color _circleBg(BuildContext context) =>
      context.isDark ? context.colorBrand : context.colorDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Column header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _headerBg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Row(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: isToday ? _circleBg(context) : context.colorMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday ? _circleBg(context) : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isToday ? Colors.white : context.colorText2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: context.colorBorder, height: 1),

          // ── Tasks ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              children: [
                ...tasks.map((task) => _MiniTaskCard(
                      task: task,
                      onToggle: () => onToggle(task),
                      onEdit: () => onEdit(task),
                    )),

                // ── "+ Add task" dashed button ─────────────────────────
                GestureDetector(
                  onTap: onCreate,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: context.colorBorder2,
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '+',
                          style: TextStyle(fontSize: 15, color: context.colorMuted2, height: 1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add task',
                          style: TextStyle(fontSize: 13, color: context.colorMuted2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini task card — flat row style matching web ───────────────────────────────

class _MiniTaskCard extends StatelessWidget {
  final TaskWithPeriod task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  static const _dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];

  const _MiniTaskCard({required this.task, required this.onToggle, required this.onEdit});

  Color _checkboxColor(BuildContext context, bool isDone) {
    if (!isDone) return Colors.transparent;
    // Level-colored checkbox when checked — matches web .task.level-X .checkbox.checked
    return switch (task.level) {
      TaskLevel.day   => context.colorDay,
      TaskLevel.week  => context.colorWeek,
      TaskLevel.month => context.colorMonth,
      TaskLevel.year  => context.colorYear,
    };
  }

  Color _checkboxBorder(BuildContext context, bool isDone) {
    if (isDone) return _checkboxColor(context, true);
    final isOverdue = task.period.status == TaskStatus.overdue;
    return isOverdue ? context.colorWarning : context.colorBorder2;
  }

  String _metaLabel() {
    final r = task.recurringConfig;
    final parts = <String>[];

    if (r != null) {
      String rec = '↻';
      if (task.level == TaskLevel.week && r.daysOfWeek != null && r.daysOfWeek!.isNotEmpty) {
        final sorted = [...r.daysOfWeek!]..sort();
        final mf = [...sorted.where((d) => d != 0), ...sorted.where((d) => d == 0)];
        rec = '↻ ${mf.map((d) => _dayNames[d]).join(' ')}';
      } else if (task.level == TaskLevel.month && r.dayOfMonth != null) {
        rec = '↻ ${r.dayOfMonth}-го';
      }
      if (task.scheduledTime != null) {
        parts.add('$rec · ${task.scheduledTime!}');
      } else {
        parts.add(rec);
      }
    } else {
      if (task.scheduledTime != null) parts.add('⏱ ${task.scheduledTime!}');
      if (task.level == TaskLevel.week && task.period.targetDate != null) {
        try {
          final d = DateTime.parse('${task.period.targetDate!.split('T')[0]}T00:00:00Z');
          parts.add('→ ${_dayNames[d.weekday % 7]}');
        } catch (_) {}
      }
    }
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final isDone    = task.period.status == TaskStatus.done;
    final isOverdue = task.period.status == TaskStatus.overdue;
    final meta      = _metaLabel();
    final checkBg   = _checkboxColor(context, isDone);
    final checkBorder = _checkboxBorder(context, isDone);

    return Container(
      // Overdue: warning-tint bg + 3px left bar (matches web ::before pseudo)
      decoration: BoxDecoration(
        color: isOverdue ? context.colorWarningTint : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: isOverdue ? context.colorWarningSoft : context.colorBorder),
          left: isOverdue ? BorderSide(color: context.colorWarning, width: 3) : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: EdgeInsets.fromLTRB(isOverdue ? 9 : 12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1, right: 10),
                  decoration: BoxDecoration(
                    color: checkBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: checkBorder,
                      width: isOverdue && !isDone ? 2 : 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ),

              // Body: title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: -0.005,
                        color: isDone
                            ? context.colorMuted
                            : isOverdue
                                ? context.colorWarningInk
                                : context.colorText,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationThickness: 1,
                        decorationColor: context.colorMuted,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: context.colorMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Edit pencil button
              GestureDetector(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Icon(Icons.edit_outlined, size: 14, color: context.colorMuted2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENERIC BODY (Month / Year)
// ═══════════════════════════════════════════════════════════════════════════════

class _GenericBody extends ConsumerWidget {
  final String view;
  final GroupedTasks data;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod) onEdit;
  final VoidCallback onCreate;

  static const _headers = {
    'month': ('ГОРИЗОНТ · МЕСЯЦ', 'Месяц.'),
    'year':  ('ГОРИЗОНТ · ГОД',   'Год.'),
  };

  const _GenericBody({
    required this.view,
    required this.data,
    required this.onToggle,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagStoreProvider);
    final filtered = tagState.filterTasks(data.primary, (t) => t.id);
    final filteredWeek = tagState.filterTasks(data.week, (t) => t.id);
    final filteredMonth = tagState.filterTasks(data.month, (t) => t.id);
    final filteredYear = tagState.filterTasks(data.year, (t) => t.id);
    final (eyebrow, title) = _headers[view] ?? ('', view);

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: context.colorMuted)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Georgia',
                  color: context.colorTextStrong,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        Divider(color: context.colorBorder, indent: 20, endIndent: 20),
        const SizedBox(height: 8),

        if (tagState.tags.isNotEmpty)
          TagFilterBar(
            tagState: tagState,
            onToggle: (id) => ref.read(tagStoreProvider.notifier).toggleFilterTag(id),
            onClear: () => ref.read(tagStoreProvider.notifier).clearFilter(),
          ),

        if (filtered.isEmpty && tagState.isFiltering)
          _emptyFiltered(context, ref)
        else
          ...filtered.map((task) => TaskCard(
                task: task,
                onToggle: () => onToggle(task),
                onEdit: () => onEdit(task),
              )),

        if (filtered.isEmpty && !tagState.isFiltering)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Text('—', style: TextStyle(fontSize: 40, color: context.colorBorder2)),
                const SizedBox(height: 8),
                Text('Нет задач', style: TextStyle(color: context.colorMuted)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Добавить'),
                ),
              ],
            ),
          ),

        if (filteredWeek.isNotEmpty)
          _CollapsibleSection(
            title: 'Задачи недели',
            tasks: filteredWeek,
            storageKey: '$view:week',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
        if (filteredMonth.isNotEmpty)
          _CollapsibleSection(
            title: 'Задачи месяца',
            tasks: filteredMonth,
            storageKey: '$view:month',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
        if (filteredYear.isNotEmpty)
          _CollapsibleSection(
            title: 'Задачи года',
            tasks: filteredYear,
            storageKey: '$view:year',
            onToggle: onToggle,
            onEdit: onEdit,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COLLAPSIBLE SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final List<TaskWithPeriod> tasks;
  final String storageKey;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod) onEdit;
  final VoidCallback? addButton;

  const _CollapsibleSection({
    required this.title,
    required this.tasks,
    required this.storageKey,
    required this.onToggle,
    required this.onEdit,
    this.addButton,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _isOpen = true;
  String get _prefKey => 'section_${widget.storageKey.replaceAll(':', '_')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey);
    if (saved != null && saved != _isOpen) setState(() => _isOpen = saved);
  }

  Future<void> _toggle() async {
    final next = !_isOpen;
    setState(() => _isOpen = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                    color: context.colorText,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.tasks.length}',
                  style: TextStyle(fontSize: 12, color: context.colorMuted),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isOpen ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 18, color: context.colorMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.tasks.map((task) => TaskCard(
                          task: task,
                          onToggle: () => widget.onToggle(task),
                          onEdit: () => widget.onEdit(task),
                        )),
                    if (widget.addButton != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: InkWell(
                          onTap: widget.addButton,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.colorCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.colorBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 14, color: context.colorMuted),
                                const SizedBox(width: 6),
                                Text('Добавить задачу',
                                    style: TextStyle(fontSize: 13, color: context.colorMuted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
