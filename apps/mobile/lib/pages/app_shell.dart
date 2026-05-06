import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int getCurrentIndex() {
      if (location.startsWith('/day')) return 0;
      if (location.startsWith('/week')) return 1;
      if (location.startsWith('/month')) return 2;
      if (location.startsWith('/year')) return 3;
      return 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: getCurrentIndex(),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/day'); break;
            case 1: context.go('/week'); break;
            case 2: context.go('/month'); break;
            case 3: context.go('/year'); break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Day'),
          BottomNavigationBarItem(icon: Icon(Icons.view_week), label: 'Week'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Month'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Year'),
        ],
      ),
    );
  }
}
