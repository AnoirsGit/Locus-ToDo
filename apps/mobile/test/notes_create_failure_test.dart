// Regression test: NotesNotifier's create paths (addRoot/addChild/addAfter)
// used `.catchError((_) { toast })` on a Future<NoteDto>. The handler returned
// nothing, so when the local (Drift) write failed the toast showed but the
// future then completed with an unhandled TypeError ("Null is not a subtype
// of NoteDto") — flagged by the analyzer as body_might_complete_normally_catch_error.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:locus_mobile/entities/note/model/notes_notifier.dart';
import 'package:locus_mobile/shared/api/api_client.dart';
import 'package:locus_mobile/shared/api/notes_api.dart';
import 'package:locus_mobile/shared/api/offline_notes_api.dart';
import 'package:locus_mobile/shared/core/strings.dart';
import 'package:locus_mobile/shared/db/app_database.dart';
import 'package:locus_mobile/shared/sync/notes_sync_worker.dart';
import 'package:locus_mobile/shared/ui/app_toast.dart';

class _FakeNotesApi extends NotesApi {
  _FakeNotesApi() : super(ApiClient(Dio()));

  @override
  Future<List<NoteDto>> list() async => [
        const NoteDto(id: 'a', content: 'Alpha', collapsed: false, sortOrder: 0, children: []),
      ];
}

/// Local store whose create write fails (e.g. a Drift/disk error).
class _FailingCreateStore implements NoteLocalStore {
  @override
  Future<void> cacheTree(List<NoteDto> tree) async {}
  @override
  Future<List<NoteDto>> loadTree() async => const [];
  @override
  Future<void> upsertFromDto(NoteDto n) async {}
  @override
  Future<void> upsertCreate(Map<String, dynamic> body) async =>
      throw StateError('local write failed');
  @override
  Future<void> applyUpdate(String id, Map<String, dynamic> body) async {}
  @override
  Future<void> deleteLocal(String id) async {}
  @override
  Future<void> enqueue(String op, String noteId, Map<String, dynamic>? payload) async {}
}

class _NoOpSyncWorker extends NotesSyncWorker {
  _NoOpSyncWorker(super.db, super.api);
  @override
  Future<void> flush() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Never opened (the sync worker is a no-op); one instance avoids drift's
  // multiple-database debug warning.
  final db = AppDatabase();
  tearDownAll(db.close);

  final cases = <String, void Function(NotesNotifier)>{
    'addRoot': (n) => n.addRoot(),
    'addChild': (n) => n.addChild('a'),
    'addAfter': (n) => n.addAfter('a'),
  };

  for (final entry in cases.entries) {
    test('${entry.key}: a failed local create toasts without an unhandled error', () async {
      final api = _FakeNotesApi();
      final container = ProviderContainer(overrides: [
        notesApiProvider.overrideWithValue(api),
        offlineNotesApiProvider.overrideWithValue(OfflineNotesApi(api, _FailingCreateStore())),
        notesSyncWorkerProvider.overrideWithValue(_NoOpSyncWorker(db, api)),
      ]);
      addTearDown(container.dispose);

      await container.read(notesProvider.future);
      entry.value(container.read(notesProvider.notifier));
      // Let the failed create settle; an unhandled async error fails the test.
      await pumpEventQueue();

      expect(container.read(appToastProvider)?.text, S.noteCreateFailed);
    });
  }
}
