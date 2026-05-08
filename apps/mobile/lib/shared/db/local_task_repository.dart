import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/task.dart';
import 'app_database.dart';

/// Converts between Drift rows and domain TaskWithPeriod objects
class LocalTaskRepository {
  final AppDatabase _db;

  LocalTaskRepository(this._db);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> saveTasksWithPeriods(List<TaskWithPeriod> items) async {
    for (final t in items) {
      await _db.upsertTask(TasksCompanion.insert(
        id: t.id,
        userId: t.userId,
        title: t.title,
        description: Value(t.description),
        level: t.level.name,
        scheduledTime: Value(t.scheduledTime),
        recurringConfigJson: Value(
          t.recurringConfig != null ? jsonEncode(_recurringToJson(t.recurringConfig!)) : null,
        ),
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      ));

      await _db.upsertPeriod(TaskPeriodsCompanion.insert(
        id: t.period.id,
        taskId: t.period.taskId,
        userId: t.period.userId,
        periodType: t.period.periodType.name,
        periodStart: t.period.periodStart,
        periodEnd: t.period.periodEnd,
        status: t.period.status.name,
        targetDate: Value(t.period.targetDate),
        deadlineMonth: Value(t.period.deadlineMonth),
        sortOrder: Value(t.period.sortOrder),
        doneAt: Value(t.period.doneAt),
        backlogAt: Value(t.period.backlogAt),
        archivedAt: Value(t.period.archivedAt),
        createdAt: t.period.createdAt,
        updatedAt: t.period.updatedAt,
      ));
    }
  }

  Future<void> updatePeriodStatus(String periodId, TaskStatus status, DateTime? doneAt) =>
      _db.updatePeriodStatus(periodId, status.name, doneAt);

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<TaskWithPeriod>> getActiveTasks() async {
    final taskRows   = await _db.select(_db.tasks).get();
    final periodRows = await _db.getActivePeriods();

    return _join(taskRows, periodRows);
  }

  Future<List<TaskWithPeriod>> getTasksForDate(String isoDate) async {
    final periodRows = await _db.getPeriodsForDate(isoDate);
    if (periodRows.isEmpty) return [];

    final taskIds = periodRows.map((p) => p.taskId).toSet();
    final taskRows = await (_db.select(_db.tasks)
      ..where((t) => t.id.isIn(taskIds))).get();

    return _join(taskRows, periodRows);
  }

  Future<void> clearAndSave(List<TaskWithPeriod> items) async {
    await _db.clearAll();
    await saveTasksWithPeriods(items);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<TaskWithPeriod> _join(List<TaskData> taskRows, List<TaskPeriodData> periodRows) {
    final taskMap = {for (final t in taskRows) t.id: t};
    final result = <TaskWithPeriod>[];

    for (final p in periodRows) {
      final t = taskMap[p.taskId];
      if (t == null) continue;

      RecurringConfig? rc;
      if (t.recurringConfigJson != null) {
        try {
          rc = _recurringFromJson(jsonDecode(t.recurringConfigJson!));
        } catch (_) {}
      }

      result.add(TaskWithPeriod(
        id: t.id,
        userId: t.userId,
        title: t.title,
        description: t.description,
        level: TaskLevel.fromString(t.level),
        scheduledTime: t.scheduledTime,
        recurringConfig: rc,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
        period: TaskPeriod(
          id: p.id,
          taskId: p.taskId,
          userId: p.userId,
          periodType: TaskLevel.fromString(p.periodType),
          periodStart: p.periodStart,
          periodEnd: p.periodEnd,
          status: TaskStatus.fromString(p.status),
          targetDate: p.targetDate,
          deadlineMonth: p.deadlineMonth,
          sortOrder: p.sortOrder,
          doneAt: p.doneAt,
          backlogAt: p.backlogAt,
          archivedAt: p.archivedAt,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
        ),
      ));
    }

    return result;
  }

  Map<String, dynamic> _recurringToJson(RecurringConfig r) => {
    'id': r.id,
    'taskId': r.taskId,
    'daysOfWeek': r.daysOfWeek,
    'dayOfMonth': r.dayOfMonth,
    'isActive': r.isActive,
    'createdAt': r.createdAt.toIso8601String(),
  };

  RecurringConfig _recurringFromJson(Map<String, dynamic> j) => RecurringConfig(
    id: j['id'],
    taskId: j['taskId'],
    daysOfWeek: (j['daysOfWeek'] as List<dynamic>?)?.cast<int>(),
    dayOfMonth: j['dayOfMonth'],
    isActive: j['isActive'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}

final localTaskRepositoryProvider = Provider<LocalTaskRepository>(
  (ref) => LocalTaskRepository(ref.watch(appDatabaseProvider)),
);
