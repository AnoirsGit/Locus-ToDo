import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../entities/note/model/notes_notifier.dart';
import '../entities/task/grouped_tasks_notifier.dart';
import '../shared/sync/notes_sync_worker.dart';
import '../shared/sync/sync_worker.dart';
import '../shared/theme/theme.dart';
import '../shared/ui/app_toast.dart';
import '../widgets/app_drawer.dart';

class AppShell extends ConsumerStatefulWidget {
  static final _scaffoldKey = GlobalKey<ScaffoldState>();
  static void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  static const _routes = ['/view', '/notes', '/stats', '/settings'];
  DateTime? _lastRefresh;

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

  /// B3: on app resume, refetch if ≥60 s have passed since last load.
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    // Leaving the foreground: push out any debounced note edits now —
    // otherwise up to 600ms of typing is silently lost if the app is
    // killed while backgrounded. `inactive` fires first (e.g. app
    // switcher, incoming call) so flush there rather than waiting for
    // `paused`, which may never arrive before the process is killed.
    if ((appState == AppLifecycleState.inactive ||
            appState == AppLifecycleState.paused ||
            appState == AppLifecycleState.hidden) &&
        ref.exists(notesProvider)) {
      // Guarded by ref.exists: don't force-initialize (and fetch) notes
      // just because the app backgrounded if the user never opened them.
      ref.read(notesProvider.notifier).flushPendingSaves();
    }

    if (appState != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < const Duration(seconds: 60)) return;
    _lastRefresh = now;
    for (final view in ['day', 'week', 'month', 'year', 'backlog']) {
      ref.invalidate(groupedTasksProvider(view));
    }
  }

  int _currentIndex(String path) {
    for (int i = 0; i < _routes.length; i++) {
      if (path.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // B4: show toasts from any notifier.
    ref.listen(appToastProvider, (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      ref.read(appToastProvider.notifier).clear();
    });

    final location = GoRouterState.of(context).uri.path;
    final idx = _currentIndex(location);
    // B4: combined pending-sync count across tasks + notes outboxes, with a
    // distinct "failed" style once any entry has retried at least once
    // (attempts > 0) rather than just being freshly queued while offline.
    final taskOutboxCount = ref.watch(outboxCountProvider).valueOrNull ?? 0;
    final noteOutboxCount = ref.watch(noteOutboxCountProvider).valueOrNull ?? 0;
    final outboxCount = taskOutboxCount + noteOutboxCount;
    final failedCount = (ref.watch(failedOutboxCountProvider).valueOrNull ?? 0) +
        (ref.watch(failedNoteOutboxCountProvider).valueOrNull ?? 0);

    return Scaffold(
      key: AppShell._scaffoldKey,
      drawer: const AppDrawer(),
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (outboxCount > 0)
            _SyncBanner(count: outboxCount, failed: failedCount > 0),
          NavigationBar(
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
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final int count;
  final bool failed;
  const _SyncBanner({required this.count, this.failed = false});

  @override
  Widget build(BuildContext context) {
    final color = failed ? context.colorDanger : context.colorWarning;
    final label = failed
        ? '$count ${count == 1 ? 'изменение' : 'изменений'} не синхронизировано, повтор...'
        : '$count ${count == 1 ? 'изменение ожидает' : 'изменений ожидают'} синхронизации';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: context.colorWarningTint,
      child: Row(
        children: [
          Icon(
            failed ? Icons.error_outline : Icons.sync_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.colorWarningInk, fontWeight: failed ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
