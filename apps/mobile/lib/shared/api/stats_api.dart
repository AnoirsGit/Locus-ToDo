import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ── DTOs ──────────────────────────────────────────────────────────────────────

class SnapshotStat {
  final int done;
  final int total;
  final int overdue;

  const SnapshotStat({required this.done, required this.total, this.overdue = 0});

  factory SnapshotStat.fromJson(Map<String, dynamic> j) => SnapshotStat(
        done: (j['done'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        overdue: (j['overdue'] as num? ?? 0).toInt(),
      );

  double get pct => total == 0 ? 0 : done / total;
}

class PeriodStat {
  final String periodStart;
  final int done;
  final int total;

  const PeriodStat({required this.periodStart, required this.done, required this.total});

  factory PeriodStat.fromJson(Map<String, dynamic> j) => PeriodStat(
        periodStart: j['periodStart'] as String,
        done: (j['done'] as num).toInt(),
        total: (j['total'] as num).toInt(),
      );

  double get pct => total == 0 ? 0 : done / total;
}

class StatsResult {
  final SnapshotStat today;
  final SnapshotStat week;
  final SnapshotStat month;
  final SnapshotStat year;
  final List<PeriodStat> weekTrend;
  final List<PeriodStat> monthTrend;
  final List<PeriodStat> yearHistory;
  // Consistency = recurring habit regularity (spec §9, never mixed with completion).
  final SnapshotStat consistency;

  const StatsResult({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
    required this.weekTrend,
    required this.monthTrend,
    required this.yearHistory,
    required this.consistency,
  });

  factory StatsResult.fromJson(Map<String, dynamic> j) {
    final snap = j['snapshot'] as Map<String, dynamic>;
    return StatsResult(
      today: SnapshotStat.fromJson(snap['today'] as Map<String, dynamic>),
      week:  SnapshotStat.fromJson(snap['week']  as Map<String, dynamic>),
      month: SnapshotStat.fromJson(snap['month'] as Map<String, dynamic>),
      year:  SnapshotStat.fromJson(snap['year']  as Map<String, dynamic>),
      weekTrend:   (j['weekTrend']   as List<dynamic>).map((e) => PeriodStat.fromJson(e as Map<String, dynamic>)).toList(),
      monthTrend:  (j['monthTrend']  as List<dynamic>).map((e) => PeriodStat.fromJson(e as Map<String, dynamic>)).toList(),
      yearHistory: (j['yearHistory'] as List<dynamic>).map((e) => PeriodStat.fromJson(e as Map<String, dynamic>)).toList(),
      consistency: j['consistency'] != null
          ? SnapshotStat.fromJson(j['consistency'] as Map<String, dynamic>)
          : const SnapshotStat(done: 0, total: 0),
    );
  }
}

// ── API ───────────────────────────────────────────────────────────────────────

class StatsApi {
  final ApiClient _client;
  const StatsApi(this._client);

  Future<StatsResult> get(String today) async {
    final res = await _client.get<Map<String, dynamic>>('/stats', queryParameters: {'today': today});
    return StatsResult.fromJson(res.data!);
  }
}

final statsApiProvider = Provider((ref) => StatsApi(ref.watch(apiClientProvider)));
