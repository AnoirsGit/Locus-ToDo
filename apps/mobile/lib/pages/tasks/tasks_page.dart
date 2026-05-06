import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/tasks_notifier.dart';
import '../../entities/task/ui/task_card.dart';

class TasksPage extends ConsumerWidget {
  final String view;

  const TasksPage({super.key, required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider(view: view));

    return Scaffold(
      appBar: AppBar(
        title: Text(view.toUpperCase()),
        centerTitle: true,
      ),
      body: tasksAsync.when(
        data: (tasks) => tasks.isEmpty
            ? const Center(
                child: Text(
                  'No tasks for this period',
                  style: TextStyle(color: Colors.white38),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
                    task: task,
                    onToggle: () => ref.read(tasksNotifierProvider(view: view).notifier).toggle(task),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
