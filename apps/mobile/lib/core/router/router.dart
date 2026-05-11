import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';
import '../../pages/app_shell.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/tasks/tasks_page.dart';
import '../../pages/docs/docs_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/stats/stats_page.dart';
import '../../pages/view_tab/view_tab_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/view',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final loggingIn = state.uri.path == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/view';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/view',     builder: (_, __) => const ViewTabPage()),
          GoRoute(path: '/backlog',  builder: (_, __) => const TasksPage(view: 'backlog')),
          GoRoute(path: '/archive',  builder: (_, __) => const TasksPage(view: 'archive')),
          GoRoute(path: '/stats',    builder: (_, __) => const StatsPage()),
          GoRoute(path: '/docs',     builder: (_, __) => const DocsPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
});
