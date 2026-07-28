import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../api/notes_api.dart';

/// Replays the notes outbox (create/update/delete) with exponential backoff.
/// Call on app foreground and after a successful notes fetch.
class NotesSyncWorker {
  final AppDatabase _db;
  final NotesApi _api;

  NotesSyncWorker(this._db, this._api);

  Future<void> flush() async {
    final pending = await _db.getPendingNoteOutbox();
    if (pending.isEmpty) return;

    for (final item in pending) {
      try {
        final body = item.payloadJson != null
            ? jsonDecode(item.payloadJson!) as Map<String, dynamic>
            : <String, dynamic>{};
        switch (item.op) {
          case 'create':
            await _api.createRaw(body);
          case 'update':
            await _api.patchRaw(item.noteId, body);
          case 'delete':
            await _api.delete(item.noteId);
        }
        await _db.removeNoteOutbox(item.id);
      } catch (_) {
        await _db.incrementNoteOutboxAttempt(
          item.id,
          item.attempts + 1,
          DateTime.now().add(_backoffDelay(item.attempts)),
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
    return delays[attempts.clamp(0, delays.length - 1)];
  }
}

final notesSyncWorkerProvider = Provider<NotesSyncWorker>(
  (ref) => NotesSyncWorker(
    ref.watch(appDatabaseProvider),
    ref.watch(notesApiProvider),
  ),
);

/// Reactive count of pending note outbox entries.
/// Drives the sync-pending banner in [AppShell] (combined with task outbox).
final noteOutboxCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchPendingNoteOutboxCount();
});

/// Reactive count of note outbox entries stuck retrying (attempts > 0).
/// Drives the failed-sync styling of the banner in [AppShell].
final failedNoteOutboxCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchFailedNoteOutboxCount();
});
