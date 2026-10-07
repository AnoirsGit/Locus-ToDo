// mobile-tasks-parity.md Gap 4: a kanban day column's "+ Add task" opens an
// inline field (web DayColumn parity) that creates a *day* task for that
// column's date through the 'day' provider — the one the columns render from —
// so the new card shows up without a manual refresh.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:locus_mobile/entities/task/task.dart';
import 'package:locus_mobile/pages/view_tab/view_tab_page.dart';
import 'package:locus_mobile/shared/api/api_client.dart';
import 'package:locus_mobile/shared/api/tags_api.dart';
import 'package:locus_mobile/shared/api/tasks_api.dart';
import 'package:locus_mobile/shared/core/date_utils.dart';
import 'package:locus_mobile/shared/core/strings.dart';
import 'package:locus_mobile/shared/providers/view_provider.dart';

TaskWithPeriod _dayTask(String id, String title, String date) => TaskWithPeriod.fromJson({
      'id': id,
      'userId': 'u1',
      'title': title,
      'level': 'day',
      'createdAt': '2026-10-05T00:00:00Z',
      'updatedAt': '2026-10-05T00:00:00Z',
      'period': {
        'id': 'p-$id',
        'taskId': id,
        'userId': 'u1',
        'periodType': 'day',
        'periodStart': date,
        'periodEnd': date,
        'status': 'todo',
        'createdAt': '2026-10-05T00:00:00Z',
        'updatedAt': '2026-10-05T00:00:00Z',
      },
    });

/// Server stand-in. Day tasks of any date come back for `view=day`, so a task
/// created in some column is visible after that provider refetches.
class _FakeTasksApi extends TasksApi {
  _FakeTasksApi() : super(ApiClient(Dio()));

  final dayTasks = <TaskWithPeriod>[];
  final created = <Map<String, dynamic>>[];
  final toggled = <String>[];

  @override
  Future<List<TaskWithPeriod>> fetchTasks({String? view}) async =>
      view == 'day' ? List.of(dayTasks) : const [];

  @override
  Future<TaskWithPeriod> createTask(Map<String, dynamic> data) async {
    created.add(data);
    final task = _dayTask('new${created.length}', data['title'] as String, data['periodStart'] as String);
    dayTasks.add(task);
    return task;
  }

  @override
  Future<void> toggleTask(String periodId, TaskStatus status) async => toggled.add(periodId);

  @override
  Future<void> deleteTask(String id) async => dayTasks.removeWhere((t) => t.id == id);

  @override
  Future<List<TaskWithPeriod>> getSubtasks(String taskId) async => const [];
}

class _FakeTagsApi extends TagsApi {
  _FakeTagsApi() : super(ApiClient(Dio()));

  @override
  Future<List<TagDto>> list() async => const [];

  @override
  Future<List<TaskTagAssignment>> getAllTaskAssignments() async => const [];

  @override
  Future<List<TagDto>> getTaskTags(String taskId) async => const [];
}

class _WeekView extends ActiveViewNotifier {
  @override
  String build() => 'week';
}

void main() {
  late _FakeTasksApi api;
  // First kanban column = Monday of the current week (same rule as the page).
  final now = DateTime.now();
  final mondayIso = localIso(now.subtract(Duration(days: now.weekday - 1)));

  Future<void> pumpWeekView(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tasksApiProvider.overrideWithValue(api),
        tagsApiProvider.overrideWithValue(_FakeTagsApi()),
        activeViewProvider.overrideWith(_WeekView.new),
      ],
      child: const MaterialApp(home: ViewTabPage()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = _FakeTasksApi();
  });

  testWidgets('quick-add creates a day task for the column date and shows it', (tester) async {
    await pumpWeekView(tester);

    await tester.tap(find.text(S.addTask).first); // Monday's column
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(api.created, [
      {'title': 'Buy milk', 'level': 'day', 'periodStart': mondayIso},
    ]);
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('submitting the quick-add field empty just closes it', (tester) async {
    await pumpWeekView(tester);

    await tester.tap(find.text(S.addTask).first);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(api.created, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });

  // Day tasks in the columns come from the 'day' provider while the week view
  // itself is the 'week' provider: their toggle/edit/delete must update 'day'.

  testWidgets('toggling a day task in a column flips its checkbox', (tester) async {
    api.dayTasks.add(_dayTask('d1', 'Gym', mondayIso));
    await pumpWeekView(tester);
    expect(find.byIcon(Icons.check), findsNothing);

    final row = find.ancestor(of: find.text('Gym'), matching: find.byType(InkWell)).first;
    await tester.tap(find.descendant(of: row, matching: find.byType(AnimatedContainer)).first);
    await tester.pumpAndSettle();

    expect(api.toggled, ['p-d1']);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('deleting a day task from a column removes its card', (tester) async {
    api.dayTasks.add(_dayTask('d1', 'Gym', mondayIso));
    await pumpWeekView(tester);

    await tester.tap(find.text('Gym')); // opens the edit sheet
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete')); // confirm dialog
    await tester.pumpAndSettle();

    expect(api.dayTasks, isEmpty);
    expect(find.text('Gym'), findsNothing);
  });
}
