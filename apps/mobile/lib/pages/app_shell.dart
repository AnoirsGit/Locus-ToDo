import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/theme/theme.dart';
import '../widgets/app_drawer.dart';

class AppShell extends ConsumerWidget {
  /// Call from anywhere to open the sidebar drawer.
  static final _scaffoldKey = GlobalKey<ScaffoldState>();
  static void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  final Widget child;
  const AppShell({super.key, required this.child});

  static const _routes = ['/view', '/backlog', '/archive', '/settings'];

  int _currentIndex(String path) {
    for (int i = 0; i < _routes.length; i++) {
      if (path.startsWith(_routes[i])) return i;
    }
    // Stats goes under "View" tab visually (no dedicated bottom slot)
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _currentIndex(location);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_routes[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: 'Просмотр',
          ),
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: 'Бэклог',
          ),
          NavigationDestination(
            icon: const Icon(Icons.archive_outlined),
            selectedIcon: const Icon(Icons.archive),
            label: 'Архив',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
