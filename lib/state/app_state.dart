import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import 'health_service.dart';
import 'notification_service.dart';
import 'persistence_service.dart';

enum AuthStage { splash, signIn, signUp, chooseUsername, bodyData, done }

/// Single source of truth for the whole prototype. Everything the UI reads
/// (auth flow, dashboard numbers, body measurements, plan, alerts) lives
/// here so every screen updates reactively when mock data changes.
///
/// Anything the user actively logs or configures (profile, weight/
/// measurement history, plan/alert read-state, settings) is persisted via
/// [PersistenceService] and restored on the next launch through [hydrate].
/// Generated demo history (daily steps/calories/sleep, today's meals) is
/// deliberately re-rolled each session so the dashboard always feels alive.
class AppState extends ChangeNotifier {
  AppState({PersistenceService? persistence})
      : _persistence = persistence ?? PersistenceService() {
    dailyStats = MockData.generateDailyStats();
    weightHistory = MockData.generateWeightHistory();
    bodyMeasurements = MockData.generateBodyMeasurements(Gender.male);
    alerts = MockData.alerts;
    planTasks = MockData.todayPlan;
    meals = MockData.todayMeals;
  }

  final PersistenceService _persistence;
  bool _hasSession = false;

  /// Loads any persisted session/data over the freshly-seeded mock state.
  /// Call once, right after construction and before [runApp] — cheap and
  /// fast enough not to need its own loading screen.
  Future<void> hydrate() async {
    _hasSession = await _persistence.onboardingDone;
    if (!_hasSession) return;

    final savedUser = await _persistence.loadUserProfile();
    if (savedUser == null) {
      _hasSession = false;
      return;
    }
    user = savedUser;
    bodyViewerGender = savedUser.gender;

    final savedWeight = await _persistence.loadWeightHistory();
    if (savedWeight != null && savedWeight.isNotEmpty) {
      weightHistory = savedWeight;
    }

    final savedMeasurements = await _persistence.loadBodyMeasurements();
    if (savedMeasurements != null && savedMeasurements.isNotEmpty) {
      bodyMeasurements = savedMeasurements;
    }

    final savedTasksDone = await _persistence.loadPlanTaskDone();
    if (savedTasksDone != null && savedTasksDone.length == planTasks.length) {
      for (var i = 0; i < planTasks.length; i++) {
        planTasks[i].done = savedTasksDone[i];
      }
    }

    final savedAlertsRead = await _persistence.loadAlertRead();
    if (savedAlertsRead != null && savedAlertsRead.length == alerts.length) {
      for (var i = 0; i < alerts.length; i++) {
        alerts[i].read = savedAlertsRead[i];
      }
    }

    notificationsEnabled =
        await _persistence.loadNotificationsEnabled() ?? notificationsEnabled;
    workoutRemindersEnabled = await _persistence.loadWorkoutRemindersEnabled() ??
        workoutRemindersEnabled;
    healthSyncEnabled =
        await _persistence.loadHealthSyncEnabled() ?? healthSyncEnabled;
  }

  void _persistUser() {
    if (user != null) unawaited(_persistence.saveUserProfile(user!));
  }

  void _persistPlanTasks() => unawaited(
      _persistence.savePlanTaskDone(planTasks.map((t) => t.done).toList()));

  void _persistAlerts() => unawaited(
      _persistence.saveAlertRead(alerts.map((a) => a.read).toList()));

  void _persistWeight() =>
      unawaited(_persistence.saveWeightHistory(weightHistory));

  void _persistMeasurements() =>
      unawaited(_persistence.saveBodyMeasurements(bodyMeasurements));

  // ---- Auth / onboarding -------------------------------------------------
  AuthStage authStage = AuthStage.splash;
  String? _pendingEmail;
  UserProfile? user;

  void finishSplash() {
    authStage = _hasSession ? AuthStage.done : AuthStage.signIn;
    notifyListeners();
  }

  void goToSignUp() {
    authStage = AuthStage.signUp;
    notifyListeners();
  }

  void goToSignIn() {
    authStage = AuthStage.signIn;
    notifyListeners();
  }

  void submitSignUp(String email, String password) {
    _pendingEmail = email.trim().isEmpty ? 'you@bodyx.app' : email.trim();
    authStage = AuthStage.chooseUsername;
    notifyListeners();
  }

  void signIn(String email, String password) {
    user = UserProfile(
      email: email.trim().isEmpty ? 'alex@bodyx.app' : email.trim(),
      username: email.split('@').first.isEmpty ? 'alex' : email.split('@').first,
    );
    authStage = AuthStage.done;
    _hasSession = true;
    _persistUser();
    unawaited(_persistence.setOnboardingDone(true));
    notifyListeners();
  }

  void submitUsername(String username) {
    user = UserProfile(
      email: _pendingEmail ?? 'you@bodyx.app',
      username: username.trim().isEmpty ? 'newuser' : username.trim(),
      name: username.trim().isEmpty ? 'Athlete' : username.trim(),
    );
    authStage = AuthStage.bodyData;
    notifyListeners();
  }

  void submitBodyData({
    required Gender gender,
    required double heightCm,
    required double weightKg,
    required int age,
  }) {
    user!.gender = gender;
    user!.heightCm = heightCm;
    user!.weightKg = weightKg;
    user!.age = age;
    bodyMeasurements = MockData.generateBodyMeasurements(gender);
    bodyViewerGender = gender;
    authStage = AuthStage.done;
    _hasSession = true;
    _persistUser();
    _persistMeasurements();
    unawaited(_persistence.setOnboardingDone(true));
    notifyListeners();
  }

  void signOut() {
    user = null;
    _pendingEmail = null;
    navIndex = 0;
    authStage = AuthStage.signIn;
    _hasSession = false;
    unawaited(_persistence.clearSession());
    notifyListeners();
  }

  // ---- Bottom navigation --------------------------------------------------
  int navIndex = 0;

  void selectNav(int index) {
    navIndex = index;
    notifyListeners();
  }

  // ---- Daily stats / plan --------------------------------------------------
  late List<DailyStats> dailyStats;
  int selectedDateIndex = -1; // -1 == "today" (last element)

  DailyStats get selectedStats =>
      dailyStats[selectedDateIndex == -1 ? dailyStats.length - 1 : selectedDateIndex];

  void selectDateIndex(int index) {
    selectedDateIndex = index;
    notifyListeners();
  }

  late List<WeightEntry> weightHistory;
  late List<PlanTask> planTasks;
  late List<MealEntry> meals;

  void togglePlanTask(int index) {
    planTasks[index].done = !planTasks[index].done;
    _persistPlanTasks();
    notifyListeners();
  }

  void logWeight(double kg, double bodyFatPct) {
    weightHistory = [
      ...weightHistory,
      WeightEntry(DateTime.now(), kg, bodyFatPct),
    ];
    if (user != null) user!.weightKg = kg;
    _persistWeight();
    _persistUser();
    notifyListeners();
  }

  // ---- Body metrics ---------------------------------------------------------
  late Map<MuscleZone, BodyMeasurement> bodyMeasurements;
  MuscleZone selectedZone = MuscleZone.chest;
  Gender bodyViewerGender = Gender.male;

  void selectZone(MuscleZone zone) {
    selectedZone = zone;
    notifyListeners();
  }

  void toggleBodyViewerGender() {
    bodyViewerGender =
        bodyViewerGender == Gender.male ? Gender.female : Gender.male;
    notifyListeners();
  }

  void logMeasurement(MuscleZone zone, double valueCm) {
    final current = bodyMeasurements[zone]!;
    bodyMeasurements[zone] = BodyMeasurement(
      zone: zone,
      valueCm: valueCm,
      history: [...current.history, valueCm],
      targetCm: current.targetCm,
    );
    _persistMeasurements();
    notifyListeners();
  }

  // ---- Alerts -----------------------------------------------------------
  late List<AlertItem> alerts;

  int get unreadAlertCount => alerts.where((a) => !a.read).length;

  void markAlertRead(int index) {
    alerts[index].read = true;
    _persistAlerts();
    notifyListeners();
  }

  void markAllAlertsRead() {
    for (final a in alerts) {
      a.read = true;
    }
    _persistAlerts();
    notifyListeners();
  }

  // ---- Profile / settings -------------------------------------------------
  bool notificationsEnabled = true;
  bool darkModeLocked = true; // this app is dark-only, shown as a toggle
  bool workoutRemindersEnabled = true;
  bool healthSyncEnabled = false;

  void updateProfile({
    String? name,
    String? username,
    String? goal,
    String? activityLevel,
  }) {
    if (user == null) return;
    if (name != null) user!.name = name;
    if (username != null) user!.username = username;
    if (goal != null) user!.goal = goal;
    if (activityLevel != null) user!.activityLevel = activityLevel;
    _persistUser();
    notifyListeners();
  }

  void updateGender(Gender gender) {
    if (user == null) return;
    user!.gender = gender;
    bodyViewerGender = gender;
    bodyMeasurements = MockData.generateBodyMeasurements(gender);
    _persistUser();
    _persistMeasurements();
    notifyListeners();
  }

  void updateHeightWeightAge({double? heightCm, double? weightKg, int? age}) {
    if (user == null) return;
    if (heightCm != null) user!.heightCm = heightCm;
    if (weightKg != null) user!.weightKg = weightKg;
    if (age != null) user!.age = age;
    _persistUser();
    notifyListeners();
  }

  void toggleUnits() {
    if (user == null) return;
    user!.unitsMetric = !user!.unitsMetric;
    _persistUser();
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    unawaited(_persistence.saveNotificationsEnabled(value));
    unawaited(_syncHydrationReminder());
    notifyListeners();
  }

  void toggleWorkoutReminders(bool value) {
    workoutRemindersEnabled = value;
    unawaited(_persistence.saveWorkoutRemindersEnabled(value));
    unawaited(_syncWorkoutReminder());
    notifyListeners();
  }

  /// Local notifications are a nice-to-have, not core app functionality —
  /// any failure here (denied permission, missing plugin binding in tests,
  /// no platform channel) is swallowed so it never breaks a settings toggle.
  Future<void> _syncHydrationReminder() async {
    try {
      if (notificationsEnabled) {
        await NotificationService.instance.requestPermission();
        await NotificationService.instance.scheduleHydrationReminder();
      } else {
        await NotificationService.instance.cancelHydrationReminder();
      }
    } catch (e) {
      debugPrint('Hydration reminder sync failed: $e');
    }
  }

  Future<void> _syncWorkoutReminder() async {
    try {
      if (workoutRemindersEnabled) {
        await NotificationService.instance.requestPermission();
        await NotificationService.instance.scheduleWorkoutReminder();
      } else {
        await NotificationService.instance.cancelWorkoutReminder();
      }
    } catch (e) {
      debugPrint('Workout reminder sync failed: $e');
    }
  }

  /// Re-applies the persisted reminder settings on launch — called once
  /// after [hydrate] so a returning user's toggles keep working without
  /// having to flip them again.
  Future<void> syncNotificationSchedules() async {
    await _syncHydrationReminder();
    await _syncWorkoutReminder();
  }

  // ---- Health sync (Apple Health / Google Health Connect) ----------------

  /// Flips the toggle. Turning it on requests OS permission first — the
  /// toggle only actually turns on if the user grants access, so the
  /// returned bool tells the caller whether to show a "not granted" message.
  Future<bool> toggleHealthSync(bool value) async {
    if (!value) {
      healthSyncEnabled = false;
      unawaited(_persistence.saveHealthSyncEnabled(false));
      notifyListeners();
      return true;
    }

    final granted = await HealthService.instance.requestPermissions();
    healthSyncEnabled = granted;
    unawaited(_persistence.saveHealthSyncEnabled(granted));
    notifyListeners();
    if (granted) unawaited(syncHealthData());
    return granted;
  }

  /// Overlays real Health data onto the current mock-generated history —
  /// per field, per day, so days/metrics with no real reading keep showing
  /// their mock value rather than a hole. A no-op unless sync is enabled.
  Future<void> syncHealthData() async {
    if (!healthSyncEnabled) return;
    try {
      final updated = <DailyStats>[];
      for (final day in dailyStats) {
        final snapshot = await HealthService.instance.fetchDailySnapshot(day.date);
        updated.add(_mergeHealthSnapshot(day, snapshot));
      }
      dailyStats = updated;

      final weightSamples = await HealthService.instance.fetchWeightHistory();
      if (weightSamples.isNotEmpty) {
        final carriedBodyFat =
            weightHistory.isNotEmpty ? weightHistory.last.bodyFatPct : 0.0;
        weightHistory = weightSamples
            .map((s) => WeightEntry(s.date, s.kg, s.bodyFatPct ?? carriedBodyFat))
            .toList();
        if (user != null) user!.weightKg = weightHistory.last.kg;
        _persistUser();
        _persistWeight();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Health sync failed: $e');
    }
  }

  DailyStats _mergeHealthSnapshot(DailyStats base, HealthDailySnapshot? snapshot) {
    if (snapshot == null) return base;
    return DailyStats(
      date: base.date,
      steps: snapshot.steps ?? base.steps,
      stepGoal: base.stepGoal,
      calories: snapshot.activeCalories ?? base.calories,
      calorieGoal: base.calorieGoal,
      sleepMinutes: snapshot.totalSleepMinutes ?? base.sleepMinutes,
      sleepGoalMinutes: base.sleepGoalMinutes,
      waterMl: snapshot.waterMl ?? base.waterMl,
      waterGoalMl: base.waterGoalMl,
      lightSleepMinutes: snapshot.sleepLightMinutes ?? base.lightSleepMinutes,
      deepSleepMinutes: snapshot.sleepDeepMinutes ?? base.deepSleepMinutes,
      remSleepMinutes: snapshot.sleepRemMinutes ?? base.remSleepMinutes,
      awakeMinutes: snapshot.sleepAwakeMinutes ?? base.awakeMinutes,
      heartRateBpm: snapshot.heartRateBpm ?? base.heartRateBpm,
    );
  }
}
