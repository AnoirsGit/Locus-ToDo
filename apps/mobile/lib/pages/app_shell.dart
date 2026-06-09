import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/theme/theme.dart';
import '../widgets/app_drawer.dart';

class AppShell extends ConsumerWidget {
  static final _scaffoldKey = GlobalKey<ScaffoldState>();
  static void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  final Widget child;
  const AppShell({super.key, required this.child});

  static const _routes = ['/view', '/notes', '/stats', '/settings'];

  int _currentIndex(String path) {
    for (int i = 0; i < _routes.length; i++) {
      if (path.startsWith(_routes[i])) return i;
    }
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
