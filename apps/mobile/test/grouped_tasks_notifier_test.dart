// Regression test for bugs.md B4 on the *live* task path: the view/tasks pages
// mutate tasks through GroupedTasksNotifier (fire-and-forget from the form
// sheet), so a failed call must surface as a toast instead of an unhandled
// error, and a failed toggle must roll its optimistic flip back.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:locus_mobile/entities/task/grouped_tasks_notifier.dart';
import 'package:locus_mobile/entities/task/task.dart';
import 'package:locus_mobile/shared/api/api_client.dart';
import 'package:locus_mobile/shared/api/tasks_api.dart';
import 'package:locus_mobile/shared/core/strings.dart';
import 'package:locus_mobile/shared/ui/app_toast.dart';

TaskWithPeriod _task(String id, {String status = 'todo'}) => TaskWithPeriod.fromJson({
      'id': id,
      'userId': 'u1',
      'title': 'Task $id',
      'level': 'week',
      'createdAt': '2026-10-05T00:00:00Z',
      'updatedAt': '2026-10-05T00:00:00Z',
      'period': {
        'id': 'p-$id',
        'taskId': id,
        'userId': 'u1',
        'periodType': 'week',
        'periodStart': '2026-10-05',
        'periodEnd': '2026-10-11',
        'status': status,
        'createdAt': '2026-10-05T00:00:00Z',
        'updatedAt': '2026-10-05T00:00:00Z',
      },
    });

DioException _httpError(int status) {
  final req = RequestOptions(path: '/tasks');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status),
    type: DioExceptionType.badResponse,
  );
}

class _FakeTasksApi extends TasksApi {
  _FakeTasksApi(this.weekTasks) : super(ApiClient(Dio()));

  final List<TaskWithPeriod> weekTasks;

  /// When set, every mutation throws it.
  Object? failWith;
  int weekFetches = 0;

  void _maybeFail() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<TaskWithPeriod>> fetchTasks({String? view}) async {
    if (view != 'week') return const [];
    weekFetches++;
    return weekTasks;
  }

  @override
  Future<void> toggleTask(String periodId, TaskStatus status) async => _maybeFail();

  @override
  Future<TaskWithPeriod> createTask(Map<String, dynamic> data) async {
    _maybeFail();
    return weekTasks.first;
  }

  @override
  Future<void> updateTask(String id, Map<String, dynamic> data) async => _maybeFail();

  @override
  Future<void> deleteTask(String id) async => _maybeFail();

  @override
  Future<TaskWithPeriod> replanTask(String taskId, String periodStart) async {
    _maybeFail();
    return weekTasks.first;
  }
}

void main() {
  late _FakeTasksApi api;
  late ProviderContainer container;

  GroupedTasksNotifier notifier() => container.read(groupedTasksProvider('week').notifier);
  String? toast() => container.read(appToastProvider)?.text;
  TaskStatus statusOf(String id) => container
      .read(groupedTasksProvider('week'))
      .requireValue
      .primary
      .firstWhere((t) => t.id == id)
      .period
      .status;

  setUp(() async {
    api = _FakeTasksApi([_task('a')]);
    container = ProviderContainer(overrides: [tasksApiProvider.overrideWithValue(api)]);
    // Keep the autoDispose-free family alive and loaded, as the page does.
    container.listen(groupedTasksProvider('week'), (_, __) {});
    await container.read(groupedTasksProvider('week').future);
  });

  tearDown(() => container.dispose());

  test('create failure shows a toast and skips the refetch', () async {
    api.failWith = _httpError(500);
    final fetchesBefore = api.weekFetches;

    await notifier().createTask({'title': 'x', 'level': 'week', 'periodStart': '2026-10-05'});

    expect(toast(), S.taskCreateFailed);
    expect(api.weekFetches, fetchesBefore);
  });

  test('create success refetches without a toast', () async {
    final fetchesBefore = api.weekFetches;

    await notifier().createTask({'title': 'x', 'level': 'week', 'periodStart': '2026-10-05'});

    expect(toast(), isNull);
    expect(api.weekFetches, fetchesBefore + 1);
  });

  test('update failure shows a toast', () async {
    api.failWith = _httpError(500);

    await notifier().updateTask('a', {'title': 'y'});

    expect(toast(), S.taskSaveFailed);
  });

  test('delete of a task with archived periods (409) explains why', () async {
    api.failWith = _httpError(409);

    await notifier().deleteTask('a');

    expect(toast(), S.taskDeleteArchivedError);
  });

  test('other delete failures (e.g. offline) show the generic message', () async {
    api.failWith = DioException(
      requestOptions: RequestOptions(path: '/tasks/a'),
      type: DioExceptionType.connectionError,
    );

    await notifier().deleteTask('a');

    expect(toast(), S.taskDeleteFailed);
  });

  test('replan failure shows a toast', () async {
    api.failWith = _httpError(500);

    await notifier().replan('a', '2026-10-12');

    expect(toast(), S.replanFailed);
  });

  test('toggle failure rolls the optimistic flip back and shows a toast', () async {
    api.failWith = _httpError(500);

    await notifier().toggle(_task('a'));

    expect(statusOf('a'), TaskStatus.todo);
    expect(toast(), S.taskSaveFailed);
  });

  test('toggle success keeps the new status without a toast', () async {
    await notifier().toggle(_task('a'));

    expect(statusOf('a'), TaskStatus.done);
    expect(toast(), isNull);
  });
}
