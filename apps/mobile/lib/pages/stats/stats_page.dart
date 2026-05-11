import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/grouped_tasks_notifier.dart';
import '../../entities/task/task.dart';
import '../../pages/app_shell.dart';
import '../../shared/theme/theme.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayData   = ref.watch(groupedTasksProvider('day'));
    final weekData  = ref.watch(groupedTasksProvider('week'));
    final monthData = ref.watch(groupedTasksProvider('month'));
    final yearData  = ref.watch(groupedTasksProvider('year'));

    return Scaffold(
      appBar: AppBar(
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
        title: Text('Статистика', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText)),
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: AppShell.openDrawer),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ────────────────────────────────────────────────────
          Text(
            'ОБЗОР',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: context.colorMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Статистика.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // ── Snapshot grid ────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _SnapshotCard(
                label: 'Сегодня',
                color: context.colorDay,
                softColor: context.colorDaySoft,
                asyncData: dayData,
              ),
              _SnapshotCard(
                label: 'Неделя',
                color: context.colorWeek,
                softColor: context.colorWeekSoft,
                asyncData: weekData,
              ),
              _SnapshotCard(
                label: 'Месяц',
                color: context.colorMonth,
                softColor: context.colorMonthSoft,
                asyncData: monthData,
              ),
              _SnapshotCard(
                label: 'Год',
                color: context.colorYear,
                softColor: context.colorYearSoft,
                asyncData: yearData,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Weekly breakdown ─────────────────────────────────────────
          _SectionTitle('Детали недели'),
          const SizedBox(height: 8),
          weekData.when(
            loading: () => const _LoadingRow(),
            error: (e, _) => _ErrorRow('$e'),
            data: (data) => _DetailBreakdown(data: data, view: 'week', context: context),
          ),

          const SizedBox(height: 20),

          // ── Monthly breakdown ────────────────────────────────────────
          _SectionTitle('Детали месяца'),
          const SizedBox(height: 8),
          monthData.when(
            loading: () => const _LoadingRow(),
            error: (e, _) => _ErrorRow('$e'),
            data: (data) => _DetailBreakdown(data: data, view: 'month', context: context),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Snapshot card ──────────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  final String label;
  final Color color;
  final Color softColor;
  final AsyncValue<GroupedTasks> asyncData;

  const _SnapshotCard({
    required this.label,
    required this.color,
    required this.softColor,
    required this.asyncData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
        boxShadow: context.isDark
            ? null
            : [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 0, offset: const Offset(2, 2))],
      ),
      child: asyncData.when(
        loading: () => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
        ),
        error: (e, _) => Text('—', style: TextStyle(color: context.colorMuted)),
        data: (data) {
          final total = data.primary.length;
          final done = data.primary.where((t) => t.period.status == TaskStatus.done).length;
          final overdue = data.primary.where((t) => t.period.status == TaskStatus.overdue).length;
          final pct = total == 0 ? 0.0 : done / total;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: context.colorMuted,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$done / $total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colorTextStrong,
                ),
              ),
              const SizedBox(height: 6),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: softColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  ),
                  if (overdue > 0)
                    Text(
                      '$overdue просроч.',
                      style: TextStyle(fontSize: 11, color: context.colorWarning),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Detail breakdown ───────────────────────────────────────────────────────────

class _DetailBreakdown extends StatelessWidget {
  final GroupedTasks data;
  final String view;
  final BuildContext context;

  const _DetailBreakdown({required this.data, required this.view, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final tasks = data.primary;
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Нет данных', style: TextStyle(color: context.colorMuted)),
      );
    }

    final done = tasks.where((t) => t.period.status == TaskStatus.done).length;
    final total = tasks.length;
    final overdue = tasks.where((t) => t.period.status == TaskStatus.overdue).length;
    final pct = total == 0 ? 0.0 : done / total;

    final barColor = pct >= 0.8
        ? context.colorSuccess
        : pct >= 0.5
            ? context.colorYear
            : context.colorDanger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Выполнено', style: TextStyle(fontSize: 13, color: context.colorText)),
              Text(
                '$done / $total',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colorTextStrong),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: context.colorSurface2,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: barColor, fontWeight: FontWeight.w600),
              ),
              if (overdue > 0)
                Text(
                  '$overdue просрочено',
                  style: TextStyle(fontSize: 12, color: context.colorWarning),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colorTextStrong,
        ),
      );
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow(this.message);
  @override
  Widget build(BuildContext context) => Text(message,
      style: TextStyle(color: context.colorDanger, fontSize: 12));
}
