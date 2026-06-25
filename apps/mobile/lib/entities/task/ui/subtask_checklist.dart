import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/tasks_api.dart';
import '../../../shared/core/strings.dart';
import '../../../shared/theme/theme.dart';
import '../task.dart';

/// Inline subtask checklist embedded in a [TaskCard], mirroring the web
/// SubtaskChecklist: a lazy expander (fetch only on first open), optimistic
/// toggle by period id, and an inline add field. Delete stays in the edit
/// sheet, as on web. Errors revert the optimistic change silently.
class SubtaskChecklist extends ConsumerStatefulWidget {
  final TaskWithPeriod parent;
  const SubtaskChecklist({super.key, required this.parent});

  @override
  ConsumerState<SubtaskChecklist> createState() => _SubtaskChecklistState();
}

class _SubtaskChecklistState extends ConsumerState<SubtaskChecklist> {
  bool _expanded = false;
  bool _loaded = false;
  bool _loading = false;
  bool _adding = false;
  List<TaskWithPeriod> _items = [];
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleExpand() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_loaded) await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(tasksApiProvider).getSubtasks(widget.parent.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(TaskWithPeriod item) async {
    final idx = _items.indexWhere((t) => t.period.id == item.period.id);
    if (idx < 0) return;
    final next = item.period.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;

    setState(() {
      _items = [..._items];
      _items[idx] = item.copyWithPeriod(item.period.copyWith(
        status: next,
        doneAt: next == TaskStatus.done ? DateTime.now() : null,
      ));
    });
    HapticFeedback.lightImpact();

    try {
      await ref.read(tasksApiProvider).toggleTask(item.period.id, next);
    } catch (_) {
      if (mounted) setState(() => _items[idx] = item); // revert
    }
  }

  Future<void> _add() async {
    final title = _addCtrl.text.trim();
    if (title.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final created = await ref.read(tasksApiProvider).createTask({
        'title': title,
        'level': widget.parent.level.name,
        'periodStart':
            widget.parent.period.periodStart.toIso8601String().split('T')[0],
        'parentTaskId': widget.parent.id,
      });
      if (!mounted) return;
      setState(() {
        _items = [..._items, created];
        _addCtrl.clear();
      });
    } catch (_) {
      // Keep the typed text so the user can retry.
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount =
        _items.where((t) => t.period.status == TaskStatus.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row
        InkWell(
          onTap: _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.chevron_right,
                      size: 16, color: context.colorMuted2),
                ),
                const SizedBox(width: 4),
                Text(
                  S.subtasks,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: context.colorMuted,
                  ),
                ),
                if (_loaded && _items.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('$doneCount/${_items.length}',
                      style:
                          TextStyle(fontSize: 11, color: context.colorMuted2)),
                ],
              ],
            ),
          ),
        ),

        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 12, 8),
            child: _loading
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text('…',
                        style: TextStyle(color: context.colorMuted2)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._items.map(_buildRow),
                      _buildAddRow(context),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _buildRow(TaskWithPeriod item) {
    final done = item.period.status == TaskStatus.done;
    return InkWell(
      onTap: () => _toggle(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _checkbox(context, done),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  color: done ? context.colorMuted2 : context.colorText,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: context.colorMuted2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRow(BuildContext context) {
    return Row(
      children: [
        _checkbox(context, false, faded: true),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _addCtrl,
            enabled: !_adding,
            style: TextStyle(fontSize: 13, color: context.colorText),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: InputBorder.none,
              hintText: S.addSubtask,
              hintStyle: TextStyle(fontSize: 13, color: context.colorMuted2),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
          ),
        ),
      ],
    );
  }

  Widget _checkbox(BuildContext context, bool done, {bool faded = false}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: done ? context.colorBrand : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: faded
              ? context.colorBorder
              : (done ? context.colorBrand : context.colorBorder2),
          width: 1.5,
        ),
      ),
      child: done
          ? Icon(Icons.check,
              size: 11,
              color: context.isDark ? AppColors.backgroundDark : Colors.white)
          : null,
    );
  }
}
