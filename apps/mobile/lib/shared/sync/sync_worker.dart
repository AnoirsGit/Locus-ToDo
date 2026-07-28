import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../shared/api/tasks_api.dart';
import '../../entities/task/task.dart';

/// Processes the sync outbox — retries failed toggle operations with exponential backoff.
/// Called on app foreground + after each successful network request.
class SyncWorker {
  final AppDatabase _db;
  final TasksApi _api;

  SyncWorker(this._db, this._api);

  Future<void> flush() async {
    final pending = await _db.getPendingOutbox();
    if (pending.isEmpty) return;

    // Dedup: per periodId keep only the latest entry
    final latest = <String, SyncOutboxData>{};
    for (final item in pending) {
      final existing = latest[item.periodId];
      if (existing == null || item.createdAt.isAfter(existing.createdAt)) {
        latest[item.periodId] = item;
      }
    }

    for (final item in latest.values) {
      // Remove stale duplicates for the same periodId
      final stale = pending.where(
        (o) => o.periodId == item.periodId && o.id != item.id,
      );
      for (final s in stale) {
        await _db.removeFromOutbox(s.id);
      }

      try {
        final status = TaskStatus.fromString(item.status);
        await _api.toggleTask(item.periodId, status);
        await _db.removeFromOutbox(item.id);
      } catch (_) {
        // Exponential backoff: 30s, 2m, 8m, 30m, cap at 1h
        final delay = _backoffDelay(item.attempts);
        await _db.incrementOutboxAttempt(
          item.id,
          DateTime.now().add(delay),
        );
      }
    }
  }

  Duration _backoffDelay(int attempts) {
    const delays = [
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 8),
      Duration(minutes: 30),
      Duration(hours: 1),
    ];
    final idx = attempts.clamp(0, delays.length - 1);
    return delays[idx];
  }
}

final syncWorkerProvider = Provider<SyncWorker>(
  (ref) => SyncWorker(
    ref.watch(appDatabaseProvider),
    ref.watch(tasksApiProvider),
  ),
);

/// Reactive count of pending task-toggle outbox entries.
/// Drives the sync-pending banner in [AppShell].
final outboxCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchPendingOutboxCount();
});

/// Reactive count of task-toggle outbox entries stuck retrying (attempts > 0).
/// Drives the failed-sync styling of the banner in [AppShell].
final failedOutboxCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchFailedOutboxCount();
});
