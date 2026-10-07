// mobile-tasks-parity.md Gap 6: an empty backlog/archive uses the web copy
// (`common.empty`, plus `common.keep_going` on backlog) instead of "No tasks".

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:locus_mobile/entities/task/task.dart';
import 'package:locus_mobile/pages/tasks/tasks_page.dart';
import 'package:locus_mobile/shared/api/api_client.dart';
import 'package:locus_mobile/shared/api/tags_api.dart';
import 'package:locus_mobile/shared/api/tasks_api.dart';
import 'package:locus_mobile/shared/core/strings.dart';

class _EmptyTasksApi extends TasksApi {
  _EmptyTasksApi() : super(ApiClient(Dio()));

  @override
  Future<List<TaskWithPeriod>> fetchTasks({String? view}) async => const [];
}

class _NoTagsApi extends TagsApi {
  _NoTagsApi() : super(ApiClient(Dio()));

  @override
  Future<List<TagDto>> list() async => const [];

  @override
  Future<List<TaskTagAssignment>> getAllTaskAssignments() async => const [];
}

Future<void> _pump(WidgetTester tester, String view) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [
      tasksApiProvider.overrideWithValue(_EmptyTasksApi()),
      tagsApiProvider.overrideWithValue(_NoTagsApi()),
    ],
    child: MaterialApp(home: TasksPage(view: view)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty backlog: "empty" + keep-going line', (tester) async {
    await _pump(tester, 'backlog');

    expect(find.text(S.emptyClean), findsOneWidget);
    expect(find.text(S.keepGoing), findsOneWidget);
    expect(find.text(S.noTasks), findsNothing);
  });

  testWidgets('empty archive: "empty" without the keep-going line', (tester) async {
    await _pump(tester, 'archive');

    expect(find.text(S.emptyClean), findsOneWidget);
    expect(find.text(S.keepGoing), findsNothing);
  });

  testWidgets('empty planning view keeps "no tasks"', (tester) async {
    await _pump(tester, 'week');

    expect(find.text(S.noTasks), findsOneWidget);
    expect(find.text(S.emptyClean), findsNothing);
  });
}
