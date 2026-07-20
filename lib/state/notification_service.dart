import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/gen/app_localizations.dart';

/// Thin wrapper around `flutter_local_notifications` — schedules the two
/// daily reminders the Settings screen's toggles promise ("Workout
/// reminders" and general "Notifications", used here for a hydration nudge)
/// entirely on-device, no push server involved.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _workoutReminderId = 1001;
  static const _hydrationReminderId = 1002;
  static const _activityDoneId = 1003;

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

  NotificationDetails _dailyDetails(Locale locale) {
    final l10n = lookupAppLocalizations(locale);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'bodyx_reminders',
        l10n.notificationChannelRemindersName,
        channelDescription: l10n.notificationChannelRemindersDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> scheduleWorkoutReminder(Locale locale) async {
    await init();
    final l10n = lookupAppLocalizations(locale);
    await _plugin.zonedSchedule(
      _workoutReminderId,
      l10n.notificationWorkoutReminderTitle,
      l10n.notificationWorkoutReminderBody,
      _nextInstanceOfTime(18, 0),
      _dailyDetails(locale),
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

  Future<void> scheduleHydrationReminder(Locale locale) async {
    await init();
    final l10n = lookupAppLocalizations(locale);
    await _plugin.zonedSchedule(
      _hydrationReminderId,
      l10n.notificationHydrationReminderTitle,
      l10n.notificationHydrationReminderBody,
      _nextInstanceOfTime(14, 0),
      _dailyDetails(locale),
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

  /// Fires immediately with sound — used when a mobility activity's
  /// countdown finishes, so the "done" moment is audible even with the
  /// phone locked or the app in the background.
  Future<void> showActivityCompleted(
      Locale locale, String title, String body) async {
    await init();
    // Best-effort: if permission (incl. sound) was never granted — the user
    // never touched a Notifications toggle — request it now rather than
    // silently presenting nothing. A no-op if already decided either way.
    try {
      await requestPermission();
    } catch (e) {
      debugPrint('Activity-completed permission request failed: $e');
    }
    final l10n = lookupAppLocalizations(locale);
    await _plugin.show(
      _activityDoneId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bodyx_activity_done',
          l10n.notificationChannelActivityDoneName,
          channelDescription: l10n.notificationChannelActivityDoneDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        // `sound` must be set explicitly — on iOS, presentSound only
        // controls whether a foreground notification is *allowed* to play
        // whatever sound is attached; without a `sound` it plays nothing
        // (which is why this used to feel like "vibration but no sound").
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
    );
  }
}
