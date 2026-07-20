import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Thin wrapper around [SharedPreferences] — everything the user actively
/// logs or configures (profile, weight/measurement history, plan/alert
/// read-state, settings, today's water/meals) survives an app restart.
/// Generated demo history (daily steps/calories/sleep) is deliberately NOT
/// persisted here; it's regenerated each session so the dashboard always
/// has a lively, populated feel.
class PersistenceService {
  static const _kOnboardingDone = 'bodyx.onboarding_done';
  static const _kUserProfile = 'bodyx.user_profile';
  static const _kWeightHistory = 'bodyx.weight_history';
  static const _kBodyMeasurements = 'bodyx.body_measurements';
  static const _kProgressPhotos = 'bodyx.progress_photos';
  static const _kPlanTaskDone = 'bodyx.plan_task_done';
  static const _kAlertRead = 'bodyx.alert_read';
  static const _kNotificationsEnabled = 'bodyx.notifications_enabled';
  static const _kWorkoutRemindersEnabled = 'bodyx.workout_reminders_enabled';
  static const _kHealthSyncEnabled = 'bodyx.health_sync_enabled';
  static const _kWaterLog = 'bodyx.water_log';
  static const _kWaterLogDate = 'bodyx.water_log_date';
  static const _kMeals = 'bodyx.meals';
  static const _kMealsDate = 'bodyx.meals_date';
  static const _kWorkoutSets = 'bodyx.workout_sets';
  static const _kWorkoutSetsDate = 'bodyx.workout_sets_date';
  static const _kWorkoutTimerSeconds = 'bodyx.workout_timer_seconds';
  static const _kWorkoutTimerStartedAt = 'bodyx.workout_timer_started_at';
  static const _kWorkoutTimerDate = 'bodyx.workout_timer_date';
  static const _kMobilityActivities = 'bodyx.mobility_activities';
  static const _kMobilityActivitiesDate = 'bodyx.mobility_activities_date';
  static const _kLocale = 'bodyx.locale';
  static const _kPublicProfile = 'bodyx.public_profile';
  static const _kShareAnonData = 'bodyx.share_anon_data';
  static const _kDismissedAnnouncementIds = 'bodyx.dismissed_announcement_ids';
  static const _kAchievementProgress = 'bodyx.achievement_progress';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String get _todayKey {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  Future<bool> get onboardingDone async =>
      (await _prefs).getBool(_kOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) async =>
      (await _prefs).setBool(_kOnboardingDone, value);

  Future<UserProfile?> loadUserProfile() async {
    final raw = (await _prefs).getString(_kUserProfile);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUserProfile(UserProfile profile) async =>
      (await _prefs).setString(_kUserProfile, jsonEncode(profile.toJson()));

  Future<List<WeightEntry>?> loadWeightHistory() async {
    final raw = (await _prefs).getString(_kWeightHistory);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveWeightHistory(List<WeightEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kWeightHistory, encoded);
  }

  /// Unlike weight history, an empty saved list is meaningful here (the
  /// user deleted every photo) — callers should only treat `null` as
  /// "never saved", not as "empty".
  Future<List<ProgressPhoto>?> loadProgressPhotos() async {
    final raw = (await _prefs).getString(_kProgressPhotos);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ProgressPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProgressPhotos(List<ProgressPhoto> photos) async {
    final encoded = jsonEncode(photos.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kProgressPhotos, encoded);
  }

  Future<Map<MuscleZone, BodyMeasurement>?> loadBodyMeasurements() async {
    final raw = (await _prefs).getString(_kBodyMeasurements);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((zoneName, value) => MapEntry(
          MuscleZone.values.byName(zoneName),
          BodyMeasurement.fromJson(value as Map<String, dynamic>),
        ));
  }

  Future<void> saveBodyMeasurements(
      Map<MuscleZone, BodyMeasurement> measurements) async {
    final map =
        measurements.map((zone, m) => MapEntry(zone.name, m.toJson()));
    await (await _prefs).setString(_kBodyMeasurements, jsonEncode(map));
  }

  Future<List<bool>?> loadPlanTaskDone() async {
    final raw = (await _prefs).getString(_kPlanTaskDone);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<bool>();
  }

  Future<void> savePlanTaskDone(List<bool> done) async =>
      (await _prefs).setString(_kPlanTaskDone, jsonEncode(done));

  /// Ids of alerts the user has already read — alerts are derived live from
  /// real data (see `AppState._buildAlerts`) rather than stored as a fixed
  /// list, so read state is tracked by stable id, not position.
  Future<List<String>?> loadReadAlertIds() async {
    final raw = (await _prefs).getString(_kAlertRead);
    if (raw == null) return null;
    // whereType, not cast — this key used to store a List<bool> (alerts were
    // tracked by position, not id); a stale value in that old shape should
    // be dropped, not crash the whole app on launch.
    return (jsonDecode(raw) as List).whereType<String>().toList();
  }

  Future<void> saveReadAlertIds(Iterable<String> ids) async =>
      (await _prefs).setString(_kAlertRead, jsonEncode(ids.toList()));

  Future<bool?> loadNotificationsEnabled() async =>
      (await _prefs).getBool(_kNotificationsEnabled);

  Future<void> saveNotificationsEnabled(bool value) async =>
      (await _prefs).setBool(_kNotificationsEnabled, value);

  Future<bool?> loadWorkoutRemindersEnabled() async =>
      (await _prefs).getBool(_kWorkoutRemindersEnabled);

  Future<void> saveWorkoutRemindersEnabled(bool value) async =>
      (await _prefs).setBool(_kWorkoutRemindersEnabled, value);

  Future<bool?> loadHealthSyncEnabled() async =>
      (await _prefs).getBool(_kHealthSyncEnabled);

  Future<void> saveHealthSyncEnabled(bool value) async =>
      (await _prefs).setBool(_kHealthSyncEnabled, value);

  /// Returns null if there's no saved log, or if it's from a previous day
  /// (a fresh mock day has already been generated, so a stale log would
  /// double-count).
  Future<List<WaterLogEntry>?> loadTodayWaterLog() async {
    final prefs = await _prefs;
    if (prefs.getString(_kWaterLogDate) != _todayKey) return null;

    final raw = prefs.getString(_kWaterLog);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => WaterLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTodayWaterLog(List<WaterLogEntry> entries) async {
    final prefs = await _prefs;
    await prefs.setString(_kWaterLogDate, _todayKey);
    await prefs.setString(
        _kWaterLog, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  /// Same day-scoped pattern as the water log — meals are real user-logged
  /// data now (see [MealEntry]), not part of the regenerated mock history.
  Future<List<MealEntry>?> loadTodayMeals() async {
    final prefs = await _prefs;
    if (prefs.getString(_kMealsDate) != _todayKey) return null;

    final raw = prefs.getString(_kMeals);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTodayMeals(List<MealEntry> meals) async {
    final prefs = await _prefs;
    await prefs.setString(_kMealsDate, _todayKey);
    await prefs.setString(
        _kMeals, jsonEncode(meals.map((e) => e.toJson()).toList()));
  }

  /// Same day-scoped pattern again — which sets of today's workout are
  /// checked off, keyed only by index (the workout template itself is
  /// regenerated fresh each session, like [MockData.todayPlan]).
  /// The user's own exercise list for today (no fixed template — see
  /// [AppState.todayWorkoutSets]), day-scoped like water/meals so it
  /// starts empty again on a new day rather than carrying over.
  Future<List<WorkoutSet>?> loadTodayWorkoutSets() async {
    final prefs = await _prefs;
    if (prefs.getString(_kWorkoutSetsDate) != _todayKey) return null;
    final raw = prefs.getString(_kWorkoutSets);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTodayWorkoutSets(List<WorkoutSet> sets) async {
    final prefs = await _prefs;
    await prefs.setString(_kWorkoutSetsDate, _todayKey);
    await prefs.setString(
        _kWorkoutSets, jsonEncode(sets.map((s) => s.toJson()).toList()));
  }

  /// [accumulatedSeconds] is the total from all stop presses today;
  /// [startedAt] is non-null only while the timer is actively running, so
  /// a relaunch mid-workout can resume counting from where it left off
  /// (including time spent with the app closed) instead of losing it.
  Future<(int accumulatedSeconds, DateTime? startedAt)?>
      loadTodayWorkoutTimer() async {
    final prefs = await _prefs;
    if (prefs.getString(_kWorkoutTimerDate) != _todayKey) return null;
    final seconds = prefs.getInt(_kWorkoutTimerSeconds);
    if (seconds == null) return null;
    final startedAtRaw = prefs.getString(_kWorkoutTimerStartedAt);
    final startedAt =
        startedAtRaw == null ? null : DateTime.parse(startedAtRaw);
    return (seconds, startedAt);
  }

  Future<void> saveTodayWorkoutTimer(
      int accumulatedSeconds, DateTime? startedAt) async {
    final prefs = await _prefs;
    await prefs.setString(_kWorkoutTimerDate, _todayKey);
    await prefs.setInt(_kWorkoutTimerSeconds, accumulatedSeconds);
    if (startedAt == null) {
      await prefs.remove(_kWorkoutTimerStartedAt);
    } else {
      await prefs.setString(
          _kWorkoutTimerStartedAt, startedAt.toIso8601String());
    }
  }

  /// Same day-scoped, user-built pattern as [loadTodayWorkoutSets] — no
  /// fixed mobility template, so this starts empty every day too.
  Future<List<MobilityActivity>?> loadTodayMobilityActivities() async {
    final prefs = await _prefs;
    if (prefs.getString(_kMobilityActivitiesDate) != _todayKey) return null;
    final raw = prefs.getString(_kMobilityActivities);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => MobilityActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTodayMobilityActivities(
      List<MobilityActivity> activities) async {
    final prefs = await _prefs;
    await prefs.setString(_kMobilityActivitiesDate, _todayKey);
    await prefs.setString(_kMobilityActivities,
        jsonEncode(activities.map((a) => a.toJson()).toList()));
  }

  Future<AchievementProgress?> loadAchievementProgress() async {
    final raw = (await _prefs).getString(_kAchievementProgress);
    if (raw == null) return null;
    return AchievementProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveAchievementProgress(AchievementProgress progress) async =>
      (await _prefs)
          .setString(_kAchievementProgress, jsonEncode(progress.toJson()));

  Future<bool?> loadPublicProfile() async =>
      (await _prefs).getBool(_kPublicProfile);

  Future<void> savePublicProfile(bool value) async =>
      (await _prefs).setBool(_kPublicProfile, value);

  Future<bool?> loadShareAnonData() async =>
      (await _prefs).getBool(_kShareAnonData);

  Future<void> saveShareAnonData(bool value) async =>
      (await _prefs).setBool(_kShareAnonData, value);

  Future<String?> loadLocaleCode() async => (await _prefs).getString(_kLocale);

  Future<void> saveLocaleCode(String? code) async {
    final prefs = await _prefs;
    if (code == null) {
      await prefs.remove(_kLocale);
    } else {
      await prefs.setString(_kLocale, code);
    }
  }

  Future<List<String>> loadDismissedAnnouncementIds() async {
    final raw = (await _prefs).getString(_kDismissedAnnouncementIds);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).whereType<String>().toList();
  }

  Future<void> saveDismissedAnnouncementIds(Iterable<String> ids) async =>
      (await _prefs)
          .setString(_kDismissedAnnouncementIds, jsonEncode(ids.toList()));

  /// Signs the session out without discarding the user's logged history —
  /// there's only ever one local "account" in this app, so their
  /// weight/measurement log survives a sign-out/sign-in cycle.
  Future<void> clearSession() async {
    await (await _prefs).remove(_kOnboardingDone);
  }

  /// Wipes every locally persisted value — used for account deletion, where
  /// (unlike [clearSession]) the logged history must not survive.
  // Survives clearAllData() by being written after it — see
  // AppState.deleteAccount(): marks that the server-side DELETE /users/me
  // failed and should be retried on a future launch.
  static const _kPendingAccountDeletion = 'bodyx.pending_account_deletion';

  Future<bool> loadPendingAccountDeletion() async =>
      (await _prefs).getBool(_kPendingAccountDeletion) ?? false;

  Future<void> savePendingAccountDeletion(bool pending) async => pending
      ? (await _prefs).setBool(_kPendingAccountDeletion, true)
      : (await _prefs).remove(_kPendingAccountDeletion).then((_) {});

  Future<void> clearAllData() async {
    await (await _prefs).clear();
  }
}
