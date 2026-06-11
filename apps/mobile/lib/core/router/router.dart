import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';
import '../../pages/app_shell.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/tasks/tasks_page.dart';
import '../../pages/notes/notes_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/stats/stats_page.dart';
import '../../pages/view_tab/view_tab_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/view',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final authPath = state.uri.path == '/login' || state.uri.path == '/register';
      if (!loggedIn && !authPath) return '/login';
      if (loggedIn && authPath) return '/view';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/view',     builder: (_, __) => const ViewTabPage()),
          GoRoute(path: '/backlog',  builder: (_, __) => const TasksPage(view: 'backlog')),
          GoRoute(path: '/archive',  builder: (_, __) => const TasksPage(view: 'archive')),
          GoRoute(path: '/stats',    builder: (_, __) => const StatsPage()),
          GoRoute(path: '/notes',    builder: (_, __) => const NotesPage()),
          GoRoute(
            path: '/notes/:id',
            builder: (_, state) => NotesPage(rootId: state.pathParameters['id']),
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
});
