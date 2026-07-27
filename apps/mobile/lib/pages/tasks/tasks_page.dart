import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../entities/task/task.dart';
import '../../entities/task/grouped_tasks_notifier.dart';
import '../../entities/task/ui/tag_filter_bar.dart';
import '../../entities/task/ui/task_card.dart';
import '../../features/task_form/task_form_sheet.dart';
import '../../pages/app_shell.dart';
import '../../shared/providers/tag_store.dart';
import '../../shared/theme/theme.dart';

class TasksPage extends ConsumerWidget {
  final String view;

  const TasksPage({super.key, required this.view});

  static const _titles = {
    'day':     'Сегодня',
    'week':    'Неделя',
    'month':   'Месяц',
    'year':    'Год',
    'backlog': 'Бэклог',
    'archive': 'Архив',
  };

  static const _contextTitles = {
    'week':  'Задачи недели',
    'month': 'Задачи месяца',
    'year':  'Задачи года',
  };

  bool get _canCreate => view != 'backlog' && view != 'archive';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = groupedTasksProvider(view);
    final grouped = ref.watch(provider);

    return Scaffold(
      appBar: _buildAppBar(context, view),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () => _openCreate(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: grouped.when(
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(provider.notifier).refresh(),
          color: context.colorBrand,
          backgroundColor: context.colorSurface,
          child: _Body(
            view: view,
            data: data,
            canCreate: _canCreate,
            onToggle: (task) => ref.read(provider.notifier).toggle(task),
            onEdit: (task) => _openEdit(context, ref, task),
            onCreate: () => _openCreate(context, ref),
          ),
        ),
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
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String view) {
    final isHorizon = _canCreate;
    return AppBar(
      leadingWidth: 120,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Locus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: context.colorTextStrong)),
            const SizedBox(width: 5),
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: context.colorBrand)),
          ],
        ),
      ),
      title: Text(_titles[view] ?? view,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText)),
      actions: [
        if (isHorizon) ...[
          _AppBarChip(
            icon: Icons.inbox_outlined,
            label: 'Бэклог',
            onTap: () => context.go('/backlog'),
          ),
          const SizedBox(width: 6),
          _AppBarChip(
            icon: Icons.archive_outlined,
            label: 'Архив',
            onTap: () => context.go('/archive'),
          ),
          const SizedBox(width: 4),
        ],
        IconButton(icon: const Icon(Icons.menu), onPressed: AppShell.openDrawer),
        const SizedBox(width: 4),
      ],
    );
  }

  String _periodStartFor(String v) {
    final now = DateTime.now();
    if (v == 'day') return _iso(now);
    if (v == 'week') {
      final dow = now.weekday;
      return _iso(now.subtract(Duration(days: dow - 1)));
    }
    if (v == 'month') return _iso(DateTime(now.year, now.month, 1));
    return '${now.year}-01-01';
  }

  String _iso(DateTime d) => d.toIso8601String().split('T')[0];

  TaskLevel _levelFor(String v) {
    switch (v) {
      case 'month': return TaskLevel.month;
      case 'year':  return TaskLevel.year;
      case 'day':   return TaskLevel.day;
      default:      return TaskLevel.week;
    }
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => TaskFormSheet(
        defaultLevel: _levelFor(view),
        defaultPeriodStart: _periodStartFor(view),
        onSubmit: (data) {
          ref.read(groupedTasksProvider(view).notifier).createTask(data);
        },
      ),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref, TaskWithPeriod task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFormSheet(
        existingTask: task,
        defaultLevel: task.level,
        defaultPeriodStart: task.period.periodStart.toIso8601String().split('T')[0],
        onSubmit: (data) {
          ref.read(groupedTasksProvider(view).notifier).updateTask(task.id, data);
        },
        onDelete: () {
          ref.read(groupedTasksProvider(view).notifier).deleteTask(task.id);
        },
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final String view;
  final GroupedTasks data;
  final bool canCreate;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod) onEdit;
  final VoidCallback onCreate;

  const _Body({
    required this.view,
    required this.data,
    required this.canCreate,
    required this.onToggle,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagStoreProvider);
    final filteredPrimary = tagState.filterTasks(data.primary, (t) => t.id);

    if (filteredPrimary.isEmpty && !data.hasContext && !tagState.isFiltering) {
      return _Empty(canCreate: canCreate, onCreate: onCreate);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        if (tagState.tags.isNotEmpty)
          TagFilterBar(tagState: tagState, onToggle: (id) => ref.read(tagStoreProvider.notifier).toggleFilterTag(id), onClear: () => ref.read(tagStoreProvider.notifier).clearFilter()),
        if (filteredPrimary.isEmpty && canCreate)
          _emptyPrimary(context)
        else
          ...filteredPrimary.map((task) => TaskCard(
                task: task,
                showLevel: view == 'backlog' || view == 'archive',
                onToggle: () => onToggle(task),
                onEdit: view != 'archive' ? () => onEdit(task) : null,
              )),

        if (data.week.isNotEmpty)
          _CollapsibleSection(
            title: TasksPage._contextTitles['week']!,
            tasks: data.week,
            storageKey: '$view:week',
            onToggle: onToggle,
            onEdit: view != 'archive' ? onEdit : null,
          ),
        if (data.month.isNotEmpty)
          _CollapsibleSection(
            title: TasksPage._contextTitles['month']!,
            tasks: data.month,
            storageKey: '$view:month',
            onToggle: onToggle,
            onEdit: view != 'archive' ? onEdit : null,
          ),
        if (data.year.isNotEmpty)
          _CollapsibleSection(
            title: TasksPage._contextTitles['year']!,
            tasks: data.year,
            storageKey: '$view:year',
            onToggle: onToggle,
            onEdit: view != 'archive' ? onEdit : null,
          ),
      ],
    );
  }

  Widget _emptyPrimary(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Column(
      children: [
        Text('—', style: TextStyle(fontSize: 36, color: context.colorBorder2)),
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
  );
}

// ── Collapsible section ────────────────────────────────────────────────────────

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final List<TaskWithPeriod> tasks;
  final String storageKey;
  final void Function(TaskWithPeriod) onToggle;
  final void Function(TaskWithPeriod)? onEdit;

  const _CollapsibleSection({
    required this.title,
    required this.tasks,
    required this.storageKey,
    required this.onToggle,
    this.onEdit,
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
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey);
    if (saved != null && saved != _isOpen) {
      setState(() => _isOpen = saved);
    }
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: context.colorMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.tasks.length}',
                  style: TextStyle(fontSize: 11, color: context.colorMuted2),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isOpen ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: context.colorMuted2,
                  ),
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
                  children: widget.tasks
                      .map((task) => TaskCard(
                            task: task,
                            onToggle: () => widget.onToggle(task),
                            onEdit: widget.onEdit != null ? () => widget.onEdit!(task) : null,
                          ))
                      .toList(),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ── AppBar chip button ─────────────────────────────────────────────────────────

class _AppBarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppBarChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: context.colorSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: context.colorMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: context.colorMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final bool canCreate;
  final VoidCallback onCreate;

  const _Empty({required this.canCreate, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.35),
        Center(
          child: Column(
            children: [
              Text('—', style: TextStyle(fontSize: 48, color: context.colorBorder2)),
              const SizedBox(height: 12),
              Text('Нет задач', style: TextStyle(color: context.colorMuted, fontSize: 16)),
              if (canCreate) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
