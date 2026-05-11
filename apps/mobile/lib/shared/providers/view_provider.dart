import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kViewKey = 'view_tab_last_view';

/// Persisted active sub-view for the View tab: 'day' | 'week' | 'month' | 'year'
class ActiveViewNotifier extends Notifier<String> {
  @override
  String build() {
    _loadPersisted();
    return 'day';
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kViewKey);
    if (saved != null && ['day', 'week', 'month', 'year'].contains(saved)) {
      state = saved;
    }
  }

  Future<void> setView(String view) async {
    state = view;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kViewKey, view);
  }
}

final activeViewProvider = NotifierProvider<ActiveViewNotifier, String>(ActiveViewNotifier.new);
