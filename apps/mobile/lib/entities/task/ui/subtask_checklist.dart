import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/tasks_api.dart';
import '../../../shared/core/date_utils.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/theme/theme.dart';
import '../../../shared/ui/app_toast.dart';
import '../task.dart';

/// Auto-dispose so subtasks are freed when the card scrolls out of view.
final subtasksProvider =
    FutureProvider.autoDispose.family<List<TaskWithPeriod>, String>(
  (ref, taskId) => ref.watch(tasksApiProvider).getSubtasks(taskId),
);

/// Lazy-loaded subtask checklist with inline add.
/// Shown inside [TaskCard] when the user expands the subtasks row.
class SubtaskChecklist extends ConsumerStatefulWidget {
  final String parentTaskId;
  final TaskLevel parentLevel;
  final DateTime parentPeriodStart;

  const SubtaskChecklist({
    super.key,
    required this.parentTaskId,
    required this.parentLevel,
    required this.parentPeriodStart,
  });

  @override
  ConsumerState<SubtaskChecklist> createState() => _SubtaskChecklistState();
}

class _SubtaskChecklistState extends ConsumerState<SubtaskChecklist> {
  // Optimistic overlay — null means "use remote data as-is"
  List<TaskWithPeriod>? _local;
  final _controller = TextEditingController();
  bool _adding = false;
  bool _showInput = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TaskWithPeriod> _items(List<TaskWithPeriod> remote) => _local ?? remote;

  Future<void> _toggle(TaskWithPeriod item, List<TaskWithPeriod> current) async {
    final newStatus = item.period.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;
    final doneAt = newStatus == TaskStatus.done ? DateTime.now() : null;

    setState(() {
      _local = current.map((t) {
        if (t.period.id != item.period.id) return t;
        return t.copyWithPeriod(t.period.copyWith(status: newStatus, doneAt: doneAt));
      }).toList();
    });

    try {
      await ref.read(tasksApiProvider).toggleTask(item.period.id, newStatus);
    } catch (_) {
      setState(() => _local = current);
      ref.invalidate(subtasksProvider(widget.parentTaskId));
      if (mounted) {
        ref.read(appToastProvider.notifier).show(S.subtaskUpdateFailed);
      }
    }
  }

  Future<void> _add(List<TaskWithPeriod> current) async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _adding = true);
    try {
      final periodStart = localIso(widget.parentPeriodStart);
      final created = await ref.read(tasksApiProvider).createTask({
        'title': title,
        'level': widget.parentLevel.name,
        'periodStart': periodStart,
        'parentTaskId': widget.parentTaskId,
      });
      _controller.clear();
      setState(() {
        _local = [...current, created];
        _showInput = false;
      });
    } catch (_) {
      // Calls tasksApiProvider directly (not the tasks_notifier wrapper),
      // so it needs its own toast on failure.
      if (mounted) {
        ref.read(appToastProvider.notifier).show(S.subtaskAddFailed);
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subtasksProvider(widget.parentTaskId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8, left: 32),
        child: SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (remote) {
        final items = _items(remote);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ...items.map((item) => _SubtaskRow(
                  item: item,
                  onToggle: () => _toggle(item, items),
                )),
            if (_showInput)
              _AddRow(
                controller: _controller,
                adding: _adding,
                onSubmit: () => _add(items),
                onCancel: () => setState(() {
                  _showInput = false;
                  _controller.clear();
                }),
              )
            else
              GestureDetector(
                onTap: () => setState(() => _showInput = true),
                child: Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 2),
                  child: Text(
                    S.addSubtask,
                    style: TextStyle(fontSize: 11, color: context.colorMuted),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final TaskWithPeriod item;
  final VoidCallback onToggle;

  const _SubtaskRow({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDone = item.period.status == TaskStatus.done;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 4, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 15,
              height: 15,
              margin: const EdgeInsets.only(top: 1, right: 8),
              decoration: BoxDecoration(
                color: isDone ? context.colorBrand : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isDone ? context.colorBrand : context.colorBorder2,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? Icon(Icons.check, size: 9,
                      color: context.isDark
                          ? AppColors.backgroundDark
                          : Colors.white)
                  : null,
            ),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDone ? context.colorMuted : context.colorText,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: context.colorMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final TextEditingController controller;
  final bool adding;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _AddRow({
    required this.controller,
    required this.adding,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 4, top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: context.colorBorder2, width: 1.5),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              enabled: !adding,
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: 12.5, color: context.colorText),
              decoration: InputDecoration(
                hintText: S.addSubtaskHint,
                hintStyle: TextStyle(fontSize: 12.5, color: context.colorMuted),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          if (adding)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          else ...[
            GestureDetector(
              onTap: onSubmit,
              child: Icon(Icons.check, size: 16, color: context.colorBrand),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onCancel,
              child: Icon(Icons.close, size: 16, color: context.colorMuted),
            ),
          ],
        ],
      ),
    );
  }
}
