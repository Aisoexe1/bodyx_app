import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications` — schedules the two
/// daily reminders the Settings screen's toggles promise ("Workout
/// reminders" and general "Notifications", used here for a hydration nudge)
/// entirely on-device, no push server involved.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _workoutReminderId = 1001;
  static const _hydrationReminderId = 1002;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fall back to UTC if the platform's abbreviation isn't in the
      // timezone database — reminders still fire, just on UTC wall-clock.
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  NotificationDetails get _dailyDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'bodyx_reminders',
          'BodyX reminders',
          channelDescription: 'Daily workout and hydration nudges',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> scheduleWorkoutReminder() async {
    await init();
    await _plugin.zonedSchedule(
      _workoutReminderId,
      "Today's workout is waiting",
      "Check your plan and get moving — you've got this.",
      _nextInstanceOfTime(18, 0),
      _dailyDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelWorkoutReminder() async {
    await init();
    await _plugin.cancel(_workoutReminderId);
  }

  Future<void> scheduleHydrationReminder() async {
    await init();
    await _plugin.zonedSchedule(
      _hydrationReminderId,
      'Hydration check',
      "Have you hit your water goal today?",
      _nextInstanceOfTime(14, 0),
      _dailyDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelHydrationReminder() async {
    await init();
    await _plugin.cancel(_hydrationReminderId);
  }
}
