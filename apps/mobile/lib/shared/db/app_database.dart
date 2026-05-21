import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

class Tasks extends Table {
  TextColumn get id          => text()();
  TextColumn get userId      => text()();
  TextColumn get title       => text()();
  TextColumn get description => text().nullable()();
  TextColumn get level       => text()();           // day|week|month|year
  TextColumn get scheduledTime => text().nullable()();
  // recurringConfig stored as JSON string for simplicity
  TextColumn get recurringConfigJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskPeriods extends Table {
  TextColumn get id          => text()();
  TextColumn get taskId      => text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId      => text()();
  TextColumn get periodType  => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd   => dateTime()();
  TextColumn get status      => text()();           // todo|done|overdue|backlog|archived
  TextColumn get targetDate  => text().nullable()();
  IntColumn  get deadlineMonth => integer().nullable()();
  IntColumn  get sortOrder   => integer().withDefault(const Constant(0))();
  DateTimeColumn get doneAt     => dateTime().nullable()();
  DateTimeColumn get backlogAt  => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt  => dateTime()();
  DateTimeColumn get updatedAt  => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Outbox: pending toggle operations to sync with server
class SyncOutbox extends Table {
  TextColumn get id        => text()();               // UUID
  TextColumn get periodId  => text()();
  TextColumn get status    => text()();               // todo|done
  DateTimeColumn get doneAt      => dateTime().nullable()();
  DateTimeColumn get createdAt   => dateTime()();
  IntColumn  get attempts  => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Tasks, TaskPeriods, SyncOutbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Task queries ──────────────────────────────────────────────────────────

  Future<void> upsertTask(TasksCompanion task) =>
      into(tasks).insertOnConflictUpdate(task);

  Future<void> upsertPeriod(TaskPeriodsCompanion period) =>
      into(taskPeriods).insertOnConflictUpdate(period);

  /// All active tasks+periods (todo|done|overdue) for a given view
  Future<List<Task>> getTasksByView(String view) {
    return (select(tasks)).get();
  }

  Future<List<TaskPeriod>> getActivePeriods() =>
      (select(taskPeriods)
        ..where((p) => p.status.isIn(['todo', 'done', 'overdue']))).get();

  Future<void> updatePeriodStatus(String periodId, String status, DateTime? doneAt) =>
      (update(taskPeriods)..where((p) => p.id.equals(periodId)))
          .write(TaskPeriodsCompanion(
            status: Value(status),
            doneAt: Value(doneAt),
            updatedAt: Value(DateTime.now()),
          ));

  Future<List<TaskPeriod>> getPeriodsForDate(String isoDate) =>
      (select(taskPeriods)
        ..where((p) =>
            p.status.isIn(['todo', 'done', 'overdue']) &
            (p.targetDate.equals(isoDate) |
             (p.periodType.equals('day') &
              p.periodStart.equals(DateTime.parse(isoDate)))))).get();

  Future<void> clearAll() async {
    await delete(taskPeriods).go();
    await delete(tasks).go();
  }

  // ── Outbox queries ────────────────────────────────────────────────────────

  Future<void> enqueueToggle({
    required String id,
    required String periodId,
    required String status,
    DateTime? doneAt,
  }) =>
      into(syncOutbox).insertOnConflictUpdate(SyncOutboxCompanion(
        id: Value(id),
        periodId: Value(periodId),
        status: Value(status),
        doneAt: Value(doneAt),
        createdAt: Value(DateTime.now()),
        attempts: const Value(0),
        nextRetryAt: Value(DateTime.now()),
      ));

  /// Dedup — keep only latest entry per periodId
  Future<List<SyncOutboxData>> getPendingOutbox() =>
      (select(syncOutbox)
        ..where((o) => o.nextRetryAt.isSmallerOrEqualValue(DateTime.now()))
        ..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();

  Future<void> removeFromOutbox(String id) =>
      (delete(syncOutbox)..where((o) => o.id.equals(id))).go();

  Future<void> incrementOutboxAttempt(String id, DateTime nextRetry) =>
      (update(syncOutbox)..where((o) => o.id.equals(id)))
          .write(SyncOutboxCompanion(
            attempts: const Value.absent(),
            nextRetryAt: Value(nextRetry),
          ));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'locus.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
