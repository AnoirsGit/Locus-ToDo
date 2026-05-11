import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../entities/task/task.dart';
import 'notification_prefs.dart';

// Notification ID ranges:
//   1_000_000 + periodId.hashCode.abs() % 900_000  → pre-deadline
//   999_999                                          → evening summary

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  // ── Pre-deadline notifications ───────────────────────────────────────────

  /// Schedule a pre-deadline notification for a task with scheduledTime.
  static Future<void> schedulePreDeadline(
    TaskWithPeriod task,
    NotificationPrefs prefs,
  ) async {
    if (!prefs.preDeadlineEnabled) return;
    if (task.scheduledTime == null) return;
    if (task.period.status == TaskStatus.done) return;

    final parts = task.scheduledTime!.split(':');
    if (parts.length < 2) return;

    final schedHour   = int.tryParse(parts[0]) ?? 0;
    final schedMinute = int.tryParse(parts[1]) ?? 0;

    final periodDate = task.period.periodStart;
    final scheduledDt = DateTime(
      periodDate.year, periodDate.month, periodDate.day,
      schedHour, schedMinute,
    );

    final notifyAt = scheduledDt.subtract(Duration(minutes: prefs.preDeadlineMinutes));
    if (notifyAt.isBefore(DateTime.now())) return;

    final id = _preDeadlineId(task.period.id);
    final tzNotifyAt = tz.TZDateTime.from(notifyAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      task.title,
      'Due in ${prefs.preDeadlineMinutes} minutes',
      tzNotifyAt,
      _notifDetails(channelId: 'pre_deadline', channelName: 'Task reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelPreDeadline(String periodId) async {
    await _plugin.cancel(_preDeadlineId(periodId));
  }

  static int _preDeadlineId(String periodId) =>
      1000000 + periodId.hashCode.abs() % 900000;

  // ── Evening summary ──────────────────────────────────────────────────────

  static Future<void> scheduleEveningSummary(
    int pendingCount,
    NotificationPrefs prefs,
  ) async {
    await _plugin.cancel(999999);
    if (!prefs.eveningSummaryEnabled) return;
    if (pendingCount == 0) return;

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year, now.month, now.day,
      prefs.eveningSummaryHour, prefs.eveningSummaryMinute,
    );

    // If already past today's time, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      999999,
      'Locus — end of day',
      pendingCount == 1
          ? '1 task still pending today'
          : '$pendingCount tasks still pending today',
      tzTime,
      _notifDetails(channelId: 'evening_summary', channelName: 'Daily summary'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Reschedule all on task load ──────────────────────────────────────────

  static Future<void> rescheduleAll(
    List<TaskWithPeriod> tasks,
    NotificationPrefs prefs,
  ) async {
    if (kIsWeb) return;
    await init();

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

    int pendingToday = 0;

    for (final task in tasks) {
      final periodStart = task.period.periodStart;
      final periodDate = '${periodStart.year}-${periodStart.month.toString().padLeft(2,'0')}-${periodStart.day.toString().padLeft(2,'0')}';

      if (task.level == TaskLevel.day && periodDate == todayKey) {
        if (task.period.status == TaskStatus.todo || task.period.status == TaskStatus.overdue) {
          pendingToday++;
          await schedulePreDeadline(task, prefs);
        } else if (task.period.status == TaskStatus.done) {
          await cancelPreDeadline(task.period.id);
        }
      }
    }

    await scheduleEveningSummary(pendingToday, prefs);
  }

  static NotificationDetails _notifDetails({
    required String channelId,
    required String channelName,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId, channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

final notificationServiceProvider = Provider<NotificationService>((_) => NotificationService());
