import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';
import 'shared/theme/theme.dart';
import 'shared/theme/theme_provider.dart';
import 'shared/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ProviderScope(child: LocusApp()));
}

class LocusApp extends ConsumerWidget {
  const LocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;

    return MaterialApp.router(
      title: 'Цикл',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
