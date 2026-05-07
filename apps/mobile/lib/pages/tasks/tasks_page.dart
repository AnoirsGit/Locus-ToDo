import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/task.dart';
import '../../entities/task/tasks_notifier.dart';
import '../../entities/task/ui/task_card.dart';
import '../../features/task_form/task_form_sheet.dart';

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

  bool get _canCreate => view != 'backlog' && view != 'archive';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = tasksNotifierProvider(view);
    final tasksAsync = ref.watch(notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[view] ?? view),
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () => _openCreate(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: tasksAsync.when(
        data: (tasks) => RefreshIndicator(
          onRefresh: () => ref.read(notifier.notifier).refresh(),
          color: const Color(0xFF579DFF),
          backgroundColor: const Color(0xFF1E2428),
          child: tasks.isEmpty
              ? _Empty(canCreate: _canCreate, onCreate: () => _openCreate(context, ref))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return TaskCard(
                      task: task,
                      showLevel: view == 'backlog' || view == 'archive',
                      onToggle: () => ref.read(notifier.notifier).toggle(task),
                      onEdit: view != 'archive'
                          ? () => _openEdit(context, ref, task)
                          : null,
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ошибка: $err', style: const TextStyle(color: Color(0xFF7A8A97))),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(notifier.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodStartFor(String v) {
    final now = DateTime.now();
    if (v == 'day') return _iso(now);
    if (v == 'week') {
      final dow = now.weekday; // 1=Mon
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
      default:      return TaskLevel.week;
    }
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2428),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(
        defaultLevel: view == 'day' ? TaskLevel.day : _levelFor(view),
        defaultPeriodStart: _periodStartFor(view),
        onSubmit: (data) {
          ref.read(tasksNotifierProvider(view).notifier).createTask(data);
        },
      ),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref, TaskWithPeriod task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2428),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(
        existingTask: task,
        defaultLevel: task.level,
        defaultPeriodStart: task.period.periodStart.toIso8601String().split('T')[0],
        onSubmit: (data) {
          ref.read(tasksNotifierProvider(view).notifier).updateTask(task.id, data);
        },
        onDelete: () {
          ref.read(tasksNotifierProvider(view).notifier).deleteTask(task.id);
        },
      ),
    );
  }
}

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
              const Text('—', style: TextStyle(fontSize: 48, color: Color(0xFF3A4550))),
              const SizedBox(height: 12),
              const Text('Нет задач', style: TextStyle(color: Color(0xFF7A8A97), fontSize: 16)),
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
