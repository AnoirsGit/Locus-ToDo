import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_notifier.dart';
import '../shared/core/strings.dart';
import '../shared/providers/view_provider.dart';
import '../shared/theme/theme.dart';
import '../shared/theme/theme_provider.dart';
import '../entities/task/grouped_tasks_notifier.dart';
import '../entities/task/task.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;
    final activeView = ref.watch(activeViewProvider);

    // Task counts for horizon badges
    final dayData    = ref.watch(groupedTasksProvider('day')).valueOrNull;
    final weekData   = ref.watch(groupedTasksProvider('week')).valueOrNull;
    final monthData  = ref.watch(groupedTasksProvider('month')).valueOrNull;
    final yearData   = ref.watch(groupedTasksProvider('year')).valueOrNull;
    final backlogData = ref.watch(groupedTasksProvider('backlog')).valueOrNull;

    int _todoCount(GroupedTasks? data) {
      if (data == null) return 0;
      return data.primary.where((t) => t.period.status == TaskStatus.todo).length;
    }

    int _backlogCount() {
      if (backlogData == null) return 0;
      return backlogData!.primary.length;
    }

    void navigate(String route, {String? view}) {
      Navigator.of(context).pop(); // close drawer
      if (view != null) {
        ref.read(activeViewProvider.notifier).setView(view);
        context.go('/view');
      } else {
        context.go(route);
      }
    }

    final String currentRoute = GoRouterState.of(context).uri.path;

    bool isActive(String route, {String? view}) {
      if (view != null) return currentRoute == '/view' && activeView == view;
      return currentRoute == route;
    }

    return Drawer(
      backgroundColor: context.colorSurface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Brand ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Locus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: context.colorTextStrong,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colorBrand,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: context.colorBorder, height: 1),

            // ── Nav list ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _SectionLabel(S.sectionHorizons),
                  _NavItem(
                    icon: Icons.today_outlined,
                    selectedIcon: Icons.today,
                    label: S.navToday,
                    count: _todoCount(dayData),
                    active: isActive('/view', view: 'day'),
                    onTap: () => navigate('/view', view: 'day'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.view_week_outlined,
                    selectedIcon: Icons.view_week,
                    label: S.navWeek,
                    count: _todoCount(weekData),
                    active: isActive('/view', view: 'week'),
                    onTap: () => navigate('/view', view: 'week'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month,
                    label: S.navMonth,
                    count: _todoCount(monthData),
                    active: isActive('/view', view: 'month'),
                    onTap: () => navigate('/view', view: 'month'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.calendar_today_outlined,
                    selectedIcon: Icons.calendar_today,
                    label: S.navYear,
                    count: _todoCount(yearData),
                    active: isActive('/view', view: 'year'),
                    onTap: () => navigate('/view', view: 'year'),
                    context: context,
                  ),

                  const SizedBox(height: 4),
                  Divider(color: context.colorBorder, height: 24, indent: 16, endIndent: 16),

                  _SectionLabel(S.sectionRecords),
                  _NavItem(
                    icon: Icons.inbox_outlined,
                    selectedIcon: Icons.inbox,
                    label: S.navBacklog,
                    count: _backlogCount(),
                    showDot: _backlogCount() > 0,
                    active: isActive('/backlog'),
                    onTap: () => navigate('/backlog'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.archive_outlined,
                    selectedIcon: Icons.archive,
                    label: S.navArchive,
                    active: isActive('/archive'),
                    onTap: () => navigate('/archive'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    label: S.navStats,
                    active: isActive('/stats'),
                    onTap: () => navigate('/stats'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.note_outlined,
                    selectedIcon: Icons.note,
                    label: S.notes,
                    active: isActive('/notes'),
                    onTap: () => navigate('/notes'),
                    context: context,
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: S.navSettings,
                    active: isActive('/settings'),
                    onTap: () => navigate('/settings'),
                    context: context,
                  ),
                ],
              ),
            ),

            Divider(color: context.colorBorder, height: 1),

            // ── Footer: theme toggle + user card ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme toggle row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(themeModeProvider.notifier).setMode(
                              themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.colorSurface2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colorBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                themeMode == ThemeMode.dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 15,
                                color: context.colorMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                themeMode == ThemeMode.dark ? S.themeLight : S.themeDark,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colorMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // User card
                  if (user != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: context.colorBrandSoft,
                          child: Text(
                            (user.name.isNotEmpty ? user.name[0] : user.email[0]).toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colorBrand,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (user.name.isNotEmpty)
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorTextStrong,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                user.email,
                                style: TextStyle(fontSize: 11, color: context.colorMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: context.colorMuted2,
          ),
        ),
      );
}

// ── Nav item ───────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int count;
  final bool showDot;
  final bool active;
  final VoidCallback onTap;
  final BuildContext context;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.count = 0,
    this.showDot = false,
    required this.active,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? context.colorBrand.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              active ? selectedIcon : icon,
              size: 18,
              color: active ? context.colorBrand : context.colorMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? context.colorBrand : context.colorText,
                ),
              ),
            ),
            if (showDot)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorWarning,
                ),
              ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? context.colorBrand.withAlpha(30) : context.colorSurface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? context.colorBrand : context.colorMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
