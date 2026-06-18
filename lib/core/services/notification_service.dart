import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps local-notification scheduling for the daily "log your spending"
/// reminder. All platform specifics live here so the rest of the app deals in
/// plain enable/time calls.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _dailyReminderId = 1001;
  static const String _channelId = 'daily_reminder';

  bool _initialized = false;

  /// Loads timezone data and initializes the plugin. Safe to call more than
  /// once. Does not request permission (that happens when the user enables it).
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Fall back to the default (UTC) if the platform name can't be resolved.
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  /// Asks the OS for permission to show notifications. Returns whether granted.
  Future<bool> requestPermission() async {
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  /// Schedules (or reschedules) the daily reminder at [hour]:[minute] local
  /// time, repeating every day.
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await init();
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Track your spending',
      'Add today’s transactions in Jeb so nothing slips through.',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily reminder',
          channelDescription: 'Reminds you to log your spending',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() => _plugin.cancel(_dailyReminderId);

  /// The next [hour]:[minute] in local time — today if still ahead, else
  /// tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
