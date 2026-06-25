import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../entities/note/model/notes_notifier.dart';
import '../entities/task/grouped_tasks_notifier.dart';
import '../shared/sync/notes_sync_worker.dart';
import '../shared/sync/sync_worker.dart';
import '../widgets/app_drawer.dart';

class AppShell extends ConsumerStatefulWidget {
  static final _scaffoldKey = GlobalKey<ScaffoldState>();
  static void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _routes = ['/view', '/notes', '/stats', '/settings'];

  // Throttle resume refetches so a quick app-switch doesn't hammer the API.
  DateTime? _lastResumeRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < const Duration(seconds: 60)) {
      return;
    }
    _lastResumeRefresh = now;

    // The scheduler mutates task state server-side (todo→overdue→backlog, day
    // rollover) on an hourly tick; an app left backgrounded across one shows
    // stale statuses and a stale "today". Refetch on resume. Invalidating the
    // family refetches whichever view is currently watched and recomputes the
    // local "today"/week window when its widgets rebuild.
    ref.invalidate(groupedTasksProvider);
    ref.invalidate(notesProvider);

    // Resume is also when connectivity typically returns — drain the outboxes.
    ref.read(syncWorkerProvider).flush();
    ref.read(notesSyncWorkerProvider).flush();
  }

  int _currentIndex(String path) {
    for (int i = 0; i < _routes.length; i++) {
      if (path.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _currentIndex(location);

    return Scaffold(
      key: AppShell._scaffoldKey,
      drawer: const AppDrawer(),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_routes[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Просмотр',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Заметки',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
