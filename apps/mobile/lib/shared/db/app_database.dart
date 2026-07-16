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

// Notes: local mirror of the notes tree for offline reads.
class Notes extends Table {
  TextColumn get id         => text()();
  TextColumn get parentId   => text().nullable()();
  TextColumn get nodeType   => text().withDefault(const Constant('bullet'))();
  TextColumn get content    => text().withDefault(const Constant(''))();
  TextColumn get url        => text().nullable()();
  IntColumn  get sortOrder  => integer().withDefault(const Constant(0))();
  BoolColumn get collapsed  => boolean().withDefault(const Constant(false))();
  BoolColumn get done       => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Notes outbox: pending create/update/delete operations to sync with server.
class NotesOutbox extends Table {
  TextColumn get id          => text()();             // outbox entry UUID
  TextColumn get op          => text()();             // create|update|delete
  TextColumn get noteId      => text()();
  TextColumn get payloadJson => text().nullable()();  // JSON of create/update fields
  DateTimeColumn get createdAt   => dateTime()();
  IntColumn  get attempts    => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime()();

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

@DriftDatabase(tables: [Tasks, TaskPeriods, SyncOutbox, Notes, NotesOutbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(notes);
            await m.createTable(notesOutbox);
          }
        },
      );

  // ── Notes queries ───────────────────────────────────────────────────────────

  Future<void> upsertNote(NotesCompanion note) =>
      into(notes).insertOnConflictUpdate(note);

  Future<List<Note>> getAllNotes() => select(notes).get();

  Future<void> deleteNoteLocal(String id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  Future<void> clearNotes() => delete(notes).go();

  Future<void> replaceAllNotes(List<NotesCompanion> rows) =>
      transaction(() async {
        await delete(notes).go();
        for (final row in rows) {
          await into(notes).insert(row);
        }
      });

  // ── Notes outbox queries ──────────────────────────────────────────────────────

  Future<void> enqueueNoteOp(NotesOutboxCompanion entry) =>
      into(notesOutbox).insert(entry);

  Future<List<NotesOutboxData>> getPendingNoteOutbox() =>
      (select(notesOutbox)
            ..where((o) => o.nextRetryAt.isSmallerOrEqualValue(DateTime.now()))
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .get();

  Future<void> removeNoteOutbox(String id) =>
      (delete(notesOutbox)..where((o) => o.id.equals(id))).go();

  Future<void> incrementNoteOutboxAttempt(String id, int attempts, DateTime nextRetry) =>
      (update(notesOutbox)..where((o) => o.id.equals(id))).write(
        NotesOutboxCompanion(attempts: Value(attempts), nextRetryAt: Value(nextRetry)),
      );

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

  /// Reactive count of all pending task-toggle outbox entries.
  Stream<int> watchPendingOutboxCount() =>
      (select(syncOutbox)).watch().map((rows) => rows.length);
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
