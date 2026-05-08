import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-configurable notification settings, persisted in SharedPreferences.
class NotificationPrefs {
  final bool preDeadlineEnabled;
  final int preDeadlineMinutes;   // lead time before scheduledTime (default 30)
  final bool eveningSummaryEnabled;
  final int eveningSummaryHour;   // 0-23 (default 20)
  final int eveningSummaryMinute; // 0-59 (default 0)

  const NotificationPrefs({
    this.preDeadlineEnabled   = true,
    this.preDeadlineMinutes   = 30,
    this.eveningSummaryEnabled = true,
    this.eveningSummaryHour   = 20,
    this.eveningSummaryMinute = 0,
  });

  NotificationPrefs copyWith({
    bool? preDeadlineEnabled,
    int? preDeadlineMinutes,
    bool? eveningSummaryEnabled,
    int? eveningSummaryHour,
    int? eveningSummaryMinute,
  }) => NotificationPrefs(
    preDeadlineEnabled:    preDeadlineEnabled   ?? this.preDeadlineEnabled,
    preDeadlineMinutes:    preDeadlineMinutes   ?? this.preDeadlineMinutes,
    eveningSummaryEnabled: eveningSummaryEnabled ?? this.eveningSummaryEnabled,
    eveningSummaryHour:    eveningSummaryHour   ?? this.eveningSummaryHour,
    eveningSummaryMinute:  eveningSummaryMinute ?? this.eveningSummaryMinute,
  );

  static const _kPreEnabled    = 'notif_pre_enabled';
  static const _kPreMinutes    = 'notif_pre_minutes';
  static const _kEveEnabled    = 'notif_eve_enabled';
  static const _kEveHour       = 'notif_eve_hour';
  static const _kEveMinute     = 'notif_eve_minute';

  static Future<NotificationPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPrefs(
      preDeadlineEnabled:    prefs.getBool(_kPreEnabled)   ?? true,
      preDeadlineMinutes:    prefs.getInt(_kPreMinutes)    ?? 30,
      eveningSummaryEnabled: prefs.getBool(_kEveEnabled)   ?? true,
      eveningSummaryHour:    prefs.getInt(_kEveHour)       ?? 20,
      eveningSummaryMinute:  prefs.getInt(_kEveMinute)     ?? 0,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPreEnabled,   preDeadlineEnabled);
    await prefs.setInt(_kPreMinutes,    preDeadlineMinutes);
    await prefs.setBool(_kEveEnabled,   eveningSummaryEnabled);
    await prefs.setInt(_kEveHour,       eveningSummaryHour);
    await prefs.setInt(_kEveMinute,     eveningSummaryMinute);
  }
}

class NotificationPrefsNotifier extends AsyncNotifier<NotificationPrefs> {
  @override
  Future<NotificationPrefs> build() => NotificationPrefs.load();

  Future<void> update(NotificationPrefs updated) async {
    await updated.save();
    state = AsyncData(updated);
  }
}

final notificationPrefsProvider =
    AsyncNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  NotificationPrefsNotifier.new,
);
