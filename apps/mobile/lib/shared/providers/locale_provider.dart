import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/strings.dart';

const _kLocaleKey = 'app_locale_override';

/// Persisted ru/en override for [S]'s string table.
///
/// `null` means "follow the OS locale" (the app's original behavior before
/// this in-app language switch existed).
class LocaleOverrideNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLocaleKey);
    final value = (stored == 'ru' || stored == 'en') ? stored : null;
    S.setLocaleOverride(value);
    return value;
  }

  Future<void> setLocale(String? code) async {
    state = AsyncData(code);
    S.setLocaleOverride(code);
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_kLocaleKey);
    } else {
      await prefs.setString(_kLocaleKey, code);
    }
  }
}

final localeOverrideProvider =
    AsyncNotifierProvider<LocaleOverrideNotifier, String?>(LocaleOverrideNotifier.new);
