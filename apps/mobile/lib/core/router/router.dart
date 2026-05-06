import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';
import '../../pages/app_shell.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/tasks/tasks_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/day',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final loggingIn = state.uri.path == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/day';
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
          GoRoute(
            path: '/day',
            builder: (context, state) => const TasksPage(view: 'day'),
          ),
          GoRoute(
            path: '/week',
            builder: (context, state) => const TasksPage(view: 'week'),
          ),
          GoRoute(
            path: '/month',
            builder: (context, state) => const TasksPage(view: 'month'),
          ),
          GoRoute(
            path: '/year',
            builder: (context, state) => const TasksPage(view: 'year'),
          ),
        ],
      ),
    ],
  );
});
