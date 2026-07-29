import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';
import 'shared/core/strings.dart';
import 'shared/providers/locale_provider.dart';
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
    final locale = ref.watch(localeOverrideProvider).valueOrNull;

    // `S.*` is a plain static string table (not Flutter's `Localizations`),
    // so re-keying the whole subtree on locale change is what forces every
    // page below to rebuild and re-read the now-updated strings. The router
    // provider instance (and its navigation state) is unaffected since it
    // lives outside this widget's subtree.
    return MaterialApp.router(
      key: ValueKey('locale-$locale'),
      title: S.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
