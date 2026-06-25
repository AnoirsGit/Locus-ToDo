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
  return _isoLocal(now);
}

String _isoLocal(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Trend row model + label/colour helpers ───────────────────────────────────────

/// One row in a trend list (current snapshot or a historical period).
class _TrendRow {
  final String label;
  final int done;
  final int total;
  final bool current;
  const _TrendRow({
    required this.label,
    required this.done,
    required this.total,
    this.current = false,
  });
  double get pct => total == 0 ? 0 : done / total;
}

const _monthShort = [
  '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];

DateTime _parseUtc(String iso) => DateTime.parse('${iso.substring(0, 10)}T00:00:00Z');

String _weekLabel(String start) {
  final s = _parseUtc(start);
  final e = s.add(const Duration(days: 6));
  return '${s.day} ${_monthShort[s.month]} – ${e.day} ${_monthShort[e.month]}';
}

String _monthLabel(String iso) {
  final d = _parseUtc(iso);
  final sameYear = d.year == DateTime.now().year;
  return sameYear ? _monthShort[d.month] : '${_monthShort[d.month]} ${d.year}';
}

String _yearLabel(String iso) => '${_parseUtc(iso).year}';

String _currentWeekStart() {
  final now = DateTime.now();
  return _isoLocal(now.subtract(Duration(days: now.weekday - 1)));
}

String _currentMonthStart() {
  final now = DateTime.now();
  return _isoLocal(DateTime(now.year, now.month, 1));
}

/// Bar/text colour by completion threshold — mirrors web `pctColor`.
Color _trendColor(BuildContext context, double pct) {
  final p = pct * 100;
  if (p >= 80) return context.colorSuccess;
  if (p >= 50) return context.colorWarning;
  if (p > 0) return context.colorDanger;
  return context.colorMuted2;
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
    final color = _trendColor(context, stat.pct);
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
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$pct%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
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
          const _SectionTitle('Постоянство (привычки)'),
          const SizedBox(height: 8),
          _ConsistencyRow(stat: data.consistency),
          const SizedBox(height: 20),
        ],

        // ── Week trend (current week prepended) ─────────────────────────────
        if (_weekRows.any((r) => r.total > 0)) ...[
          const _SectionTitle('Тренд недели'),
          const SizedBox(height: 8),
          _TrendChart(rows: _weekRows),
          const SizedBox(height: 20),
        ],

        // ── Month trend (current month prepended) ───────────────────────────
        if (_monthRows.any((r) => r.total > 0)) ...[
          const _SectionTitle('Тренд месяца'),
          const SizedBox(height: 8),
          _TrendChart(rows: _monthRows),
          const SizedBox(height: 20),
        ],

        // ── Year history ────────────────────────────────────────────────────
        if (_yearRows.isNotEmpty) ...[
          const _SectionTitle('По годам'),
          const SizedBox(height: 8),
          _TrendChart(rows: _yearRows),
          const SizedBox(height: 100),
        ] else
          const SizedBox(height: 100),
      ],
    );
  }

  // Current snapshot prepended as the first (highlighted) row, then history —
  // mirrors web `weekTrendRows`/`monthTrendRows`. Year history has no current row.
  List<_TrendRow> get _weekRows => [
        _TrendRow(label: _weekLabel(_currentWeekStart()), done: data.week.done, total: data.week.total, current: true),
        ...data.weekTrend.map((s) => _TrendRow(label: _weekLabel(s.periodStart), done: s.done, total: s.total)),
      ].where((r) => r.total > 0 || r.current).toList();

  List<_TrendRow> get _monthRows => [
        _TrendRow(label: _monthLabel(_currentMonthStart()), done: data.month.done, total: data.month.total, current: true),
        ...data.monthTrend.map((s) => _TrendRow(label: _monthLabel(s.periodStart), done: s.done, total: s.total)),
      ].where((r) => r.total > 0 || r.current).toList();

  List<_TrendRow> get _yearRows => data.yearHistory
      .map((s) => _TrendRow(label: _yearLabel(s.periodStart), done: s.done, total: s.total))
      .toList();
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
  final List<_TrendRow> rows;

  const _TrendChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        children: rows.map((r) {
          final color = _trendColor(context, r.pct);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: r.current ? context.colorTextStrong : context.colorMuted,
                            fontWeight: r.current ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (r.current) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.colorBrandSoft,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text('сейчас',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: context.colorBrand)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: r.pct,
                      minHeight: 8,
                      backgroundColor: context.colorSurface2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(r.pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${r.done}/${r.total}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 10, color: context.colorMuted),
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
