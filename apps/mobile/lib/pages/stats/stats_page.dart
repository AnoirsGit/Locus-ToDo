import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pages/app_shell.dart';
import '../../shared/api/stats_api.dart';
import '../../shared/theme/theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final statsProvider = FutureProvider.autoDispose<StatsResult>((ref) {
  final today = _isoToday();
  return ref.watch(statsApiProvider).get(today);
});

String _isoToday() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(statsProvider),
          ),
          IconButton(icon: const Icon(Icons.menu), onPressed: AppShell.openDrawer),
          const SizedBox(width: 4),
        ],
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ошибка загрузки', style: TextStyle(color: context.colorMuted)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (data) => _StatsBody(data: data),
      ),
    );
  }
}

// ── Consistency row ─────────────────────────────────────────────────────────────

class _ConsistencyRow extends StatelessWidget {
  final SnapshotStat stat;
  const _ConsistencyRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final pct = (stat.pct * 100).round();
    return Row(
      children: [
        Expanded(
          child: Text('Повторяющиеся задачи',
              style: TextStyle(fontSize: 13, color: context.colorMuted)),
        ),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: stat.pct,
              minHeight: 6,
              backgroundColor: context.colorBorder,
              valueColor: AlwaysStoppedAnimation(context.colorBrand),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$pct%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colorTextStrong)),
        const SizedBox(width: 6),
        Text('${stat.done}/${stat.total}',
            style: TextStyle(fontSize: 11, color: context.colorMuted)),
      ],
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  final StatsResult data;
  const _StatsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'ОБЗОР',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: context.colorMuted),
        ),
        const SizedBox(height: 4),
        Text('Статистика.', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),

        // ── Snapshot grid ───────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _SnapshotCard(label: 'Сегодня', stat: data.today, color: context.colorDay,   softColor: context.colorDaySoft),
            _SnapshotCard(label: 'Неделя',  stat: data.week,  color: context.colorWeek,  softColor: context.colorWeekSoft),
            _SnapshotCard(label: 'Месяц',   stat: data.month, color: context.colorMonth, softColor: context.colorMonthSoft),
            _SnapshotCard(label: 'Год',     stat: data.year,  color: context.colorYear,  softColor: context.colorYearSoft),
          ],
        ),

        const SizedBox(height: 28),

        // ── Consistency (recurring habits) ──────────────────────────────────
        if (data.consistency.total > 0) ...[
          _SectionTitle('Постоянство (привычки)'),
          const SizedBox(height: 8),
          _ConsistencyRow(stat: data.consistency),
          const SizedBox(height: 20),
        ],

        // ── Week trend ──────────────────────────────────────────────────────
        if (data.weekTrend.isNotEmpty) ...[
          _SectionTitle('Тренд недели'),
          const SizedBox(height: 8),
          _TrendChart(periods: data.weekTrend, color: context.colorWeek),
          const SizedBox(height: 20),
        ],

        // ── Month trend ─────────────────────────────────────────────────────
        if (data.monthTrend.isNotEmpty) ...[
          _SectionTitle('Тренд месяца'),
          const SizedBox(height: 8),
          _TrendChart(periods: data.monthTrend, color: context.colorMonth),
          const SizedBox(height: 100),
        ] else
          const SizedBox(height: 100),
      ],
    );
  }
}

// ── Snapshot card ─────────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  final String label;
  final SnapshotStat stat;
  final Color color;
  final Color softColor;

  const _SnapshotCard({
    required this.label,
    required this.stat,
    required this.color,
    required this.softColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: context.colorMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${stat.done} / ${stat.total}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorTextStrong),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.pct,
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
                '${(stat.pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
              if (stat.overdue > 0)
                Text(
                  '${stat.overdue} просроч.',
                  style: TextStyle(fontSize: 11, color: context.colorWarning),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trend chart (horizontal bar list) ────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<PeriodStat> periods;
  final Color color;

  const _TrendChart({required this.periods, required this.color});

  @override
  Widget build(BuildContext context) {
    final displayed = periods.length > 8 ? periods.sublist(periods.length - 8) : periods;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        children: displayed.map((p) {
          final label = p.periodStart.substring(0, 10);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(label, style: TextStyle(fontSize: 10, color: context.colorMuted, fontFamily: 'monospace')),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: p.pct,
                      minHeight: 8,
                      backgroundColor: context.colorSurface2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(p.pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colorTextStrong),
      );
}
