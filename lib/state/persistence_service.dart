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
  static const _kPlanTaskDone = 'bodyx.plan_task_done';
  static const _kAlertRead = 'bodyx.alert_read';
  static const _kNotificationsEnabled = 'bodyx.notifications_enabled';
  static const _kWorkoutRemindersEnabled = 'bodyx.workout_reminders_enabled';
  static const _kHealthSyncEnabled = 'bodyx.health_sync_enabled';
  static const _kWaterLog = 'bodyx.water_log';
  static const _kWaterLogDate = 'bodyx.water_log_date';
  static const _kMeals = 'bodyx.meals';
  static const _kMealsDate = 'bodyx.meals_date';

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

  Future<List<bool>?> loadAlertRead() async {
    final raw = (await _prefs).getString(_kAlertRead);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<bool>();
  }

  Future<void> saveAlertRead(List<bool> read) async =>
      (await _prefs).setString(_kAlertRead, jsonEncode(read));

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

  /// Signs the session out without discarding the user's logged history —
  /// there's only ever one local "account" in this prototype, so their
  /// weight/measurement log survives a sign-out/sign-in cycle.
  Future<void> clearSession() async {
    await (await _prefs).remove(_kOnboardingDone);
  }
}
