import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _routes = ['/day', '/week', '/month', '/year', '/backlog', '/archive', '/settings'];

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
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_routes[i]),
        backgroundColor: const Color(0xFF1E2428),
        indicatorColor: const Color(0x29579DFF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined),          selectedIcon: Icon(Icons.today),          label: 'День'),
          NavigationDestination(icon: Icon(Icons.view_week_outlined),      selectedIcon: Icon(Icons.view_week),      label: 'Неделя'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Месяц'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Год'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined),          selectedIcon: Icon(Icons.inbox),          label: 'Бэклог'),
          NavigationDestination(icon: Icon(Icons.archive_outlined),        selectedIcon: Icon(Icons.archive),        label: 'Архив'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),       selectedIcon: Icon(Icons.settings),       label: 'Настройки'),
        ],
      ),
    );
  }
}
