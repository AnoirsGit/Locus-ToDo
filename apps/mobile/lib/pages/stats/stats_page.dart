import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pages/app_shell.dart';
import '../../shared/api/stats_api.dart';
import '../../shared/theme/theme.dart';
import '../../shared/ui/skeleton.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final statsProvider = FutureProvider.autoDispose<StatsResult>((ref) {
  final today = _isoToday();
  return ref.watch(statsApiProvider).get(today);
});

String _isoToday() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _weekStartIso() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

String _monthStartIso() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
}

const _kMonthAbbr = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

String _weekLabel(String isoStart) {
  final s = DateTime.parse('${isoStart}T00:00:00Z');
  final e = s.add(const Duration(days: 6));
  final sm = _kMonthAbbr[s.month];
  final em = _kMonthAbbr[e.month];
  return s.month == e.month ? '${s.day} – ${e.day} $sm' : '${s.day} $sm – ${e.day} $em';
}

String _monthLabel(String isoStart) {
  final d = DateTime.parse('${isoStart}T00:00:00Z');
  final abbr = _kMonthAbbr[d.month];
  return d.year == DateTime.now().year ? abbr : '$abbr ${d.year}';
}

// Trend row with optional "current period" marker and human-readable label.
class _TrendRow {
  final String periodStart;
  final String label;
  final int done;
  final int total;
  final bool current;

  const _TrendRow({
    required this.periodStart,
    required this.label,
    required this.done,
    required this.total,
    this.current = false,
  });

  double get pct => total == 0 ? 0 : done / total;
}

List<_TrendRow> _buildWeekRows(StatsResult data) {
  final start = _weekStartIso();
  final cur = _TrendRow(
    periodStart: start, label: _weekLabel(start),
    done: data.week.done, total: data.week.total, current: true,
  );
  return [cur, ...data.weekTrend.map((p) => _TrendRow(
    periodStart: p.periodStart, label: _weekLabel(p.periodStart),
    done: p.done, total: p.total,
  ))];
}

List<_TrendRow> _buildMonthRows(StatsResult data) {
  final start = _monthStartIso();
  final cur = _TrendRow(
    periodStart: start, label: _monthLabel(start),
    done: data.month.done, total: data.month.total, current: true,
  );
  return [cur, ...data.monthTrend.map((p) => _TrendRow(
    periodStart: p.periodStart, label: _monthLabel(p.periodStart),
    done: p.done, total: p.total,
  ))];
}

List<_TrendRow> _buildYearRows(StatsResult data) {
  return data.yearHistory.map((p) => _TrendRow(
    periodStart: p.periodStart,
    label: p.periodStart.substring(0, 4),
    done: p.done, total: p.total,
  )).toList();
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
        loading: () => const StatsSkeleton(),
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
        _SectionTitle('По неделям'),
        const SizedBox(height: 8),
        _TrendChart(rows: _buildWeekRows(data), accentColor: context.colorWeek),
        const SizedBox(height: 20),

        // ── Month trend ─────────────────────────────────────────────────────
        _SectionTitle('По месяцам'),
        const SizedBox(height: 8),
        _TrendChart(rows: _buildMonthRows(data), accentColor: context.colorMonth),
        const SizedBox(height: 20),

        // ── Year history ─────────────────────────────────────────────────────
        if (data.yearHistory.isNotEmpty) ...[
          _SectionTitle('По годам'),
          const SizedBox(height: 8),
          _TrendChart(rows: _buildYearRows(data), accentColor: context.colorYear),
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

Color _barColor(BuildContext context, double pct) {
  if (pct >= 0.8) return context.colorSuccess;
  if (pct >= 0.5) return context.colorWarning;
  if (pct > 0)    return context.colorDanger;
  return context.colorBorder2;
}

class _TrendChart extends StatelessWidget {
  final List<_TrendRow> rows;
  /// Fallback accent used only when total == 0 (empty bar placeholder).
  final Color accentColor;

  const _TrendChart({required this.rows, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final displayed = rows.length > 10 ? rows.sublist(0, 10) : rows;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        children: displayed.map((row) {
          final barColor = row.total > 0 ? _barColor(context, row.pct) : context.colorBorder2;
          final pctInt = (row.pct * 100).round();
          final isCurrent = row.current;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrent ? context.colorTextStrong : context.colorMuted,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.colorBrandSoft,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'сейчас',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: context.colorBrand),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: row.pct,
                      minHeight: 7,
                      backgroundColor: context.colorSurface2,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pctInt%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: barColor),
                      ),
                      Text(
                        '${row.done}/${row.total}',
                        style: TextStyle(fontSize: 9, color: context.colorMuted),
                      ),
                    ],
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
