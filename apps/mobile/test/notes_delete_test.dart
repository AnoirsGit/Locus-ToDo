// Regression test for the "delete only clears content" bug (notes-v2/01-delete-bug.md, Cause A):
// without ValueKey(node.id) on _NoteRow, deleting a row that is in edit mode made
// Flutter reuse its State for the neighbor row, rewriting the neighbor's content
// with the deleted note's text.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:locus_mobile/pages/notes/notes_page.dart';
import 'package:locus_mobile/shared/api/api_client.dart';
import 'package:locus_mobile/shared/api/notes_api.dart';

class _FakeNotesApi extends NotesApi {
  _FakeNotesApi(this.notes) : super(ApiClient(Dio()));

  final List<NoteDto> notes;
  final List<({String id, String? content})> updates = [];
  final List<String> deletes = [];

  @override
  Future<List<NoteDto>> list() async => notes;

  @override
  Future<NoteDto> create({
    required String id,
    String? parentId,
    String nodeType = 'text',
    required String content,
    String? url,
    required int sortOrder,
  }) async =>
      NoteDto(
        id: id,
        parentId: parentId,
        nodeType: nodeType,
        content: content,
        url: url,
        collapsed: false,
        sortOrder: sortOrder,
        children: const [],
      );

  @override
  Future<void> update(
    String id, {
    String? nodeType,
    String? content,
    bool? collapsed,
    Object? parentId,
    Object? url,
    int? sortOrder,
  }) async {
    updates.add((id: id, content: content));
  }

  @override
  Future<void> delete(String id) async {
    deletes.add(id);
  }
}

NoteDto _note(String id, String content) => NoteDto(
      id: id,
      content: content,
      collapsed: false,
      sortOrder: 0,
      children: const [],
    );

void main() {
  testWidgets('deleting a note while editing it does not rewrite its neighbor',
      (tester) async {
    final api = _FakeNotesApi([
      _note('a', 'Alpha'),
      _note('b', 'Beta'),
      _note('c', 'Gamma'),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [notesApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: NotesPage()),
    ));
    await tester.pumpAndSettle();

    // Enter edit mode on the middle note.
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Beta'), findsOneWidget);

    // Delete it via the row's actions sheet (test locale is en).
    await tester.tap(find.byIcon(Icons.more_horiz).at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(api.deletes, ['b']);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Gamma'), findsOneWidget);

    // Tap outside any lingering editor — a stale reused State would commit
    // the deleted note's text onto Gamma here.
    await tester.tapAt(const Offset(5, 200));
    await tester.pumpAndSettle();

    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(api.updates.where((u) => u.id == 'c'), isEmpty,
        reason: 'neighbor note must not receive the deleted note content');
  });
}
