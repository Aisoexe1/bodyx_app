import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../network/auth_repository.dart';
import '../network/measurement_repository.dart';
import '../network/profile_repository.dart';
import '../network/weight_repository.dart';
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
  AppState({
    PersistenceService? persistence,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    WeightRepository? weightRepository,
    MeasurementRepository? measurementRepository,
  })  : _persistence = persistence ?? PersistenceService(),
        _authRepository = authRepository ?? ApiAuthRepository(),
        _profileRepository = profileRepository ?? ApiProfileRepository(),
        _weightRepository = weightRepository ?? ApiWeightRepository(),
        _measurementRepository =
            measurementRepository ?? ApiMeasurementRepository() {
    dailyStats = MockData.generateDailyStats();
    weightHistory = MockData.generateWeightHistory();
    bodyMeasurements = MockData.generateBodyMeasurements(Gender.male);
    alerts = MockData.alerts;
    planTasks = MockData.todayPlan;
    meals = MockData.todayMeals;
  }

  final PersistenceService _persistence;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final WeightRepository _weightRepository;
  final MeasurementRepository _measurementRepository;
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

    await _restoreServerSession();
  }

  /// Best-effort: if a JWT is still stored, re-validate it against the
  /// server and refresh the profile/weight/measurements from there. Any
  /// failure (offline, timeout, expired token) is swallowed — [hydrate]'s
  /// local-load above has already put the app in a usable state, so this
  /// only ever upgrades it, never blocks or degrades it.
  Future<void> _restoreServerSession() async {
    final restoredUser = await _authRepository.restoreSession();
    if (restoredUser == null) return;

    user = restoredUser;
    bodyViewerGender = restoredUser.gender;
    _hasSession = true;
    unawaited(_persistence.setOnboardingDone(true));
    _persistUser();

    try {
      final serverWeight = await _weightRepository.list();
      if (serverWeight.isNotEmpty) {
        weightHistory = serverWeight;
        _persistWeight();
      }
      final serverMeasurements = await _measurementRepository.getAll();
      if (serverMeasurements.isNotEmpty) {
        bodyMeasurements = serverMeasurements;
        _persistMeasurements();
      }
    } catch (e) {
      debugPrint('Failed to pull weight/measurements during session restore: $e');
    }
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

  // ---- Best-effort server sync --------------------------------------------
  // Local persistence above is always the source of truth for MVP — these
  // mirror each mutation to the server unawaited, with failures swallowed
  // exactly like the existing notification-sync methods below. A signed-out
  // session (no server account yet) has nothing to sync to, so these are
  // no-ops until [signIn]/[submitUsername] succeed.

  void _syncUserToServer() => unawaited(_pushUserToServer());

  Future<void> _pushUserToServer() async {
    if (user == null || !_hasSession) return;
    try {
      await _profileRepository.updateMe({
        'username': user!.username,
        'name': user!.name,
        'gender': user!.gender.name,
        'heightCm': user!.heightCm,
        'weightKg': user!.weightKg,
        'age': user!.age,
        'goal': user!.goal,
        'activityLevel': user!.activityLevel,
        'unitsMetric': user!.unitsMetric,
        'avatarSeed': user!.avatarSeed,
      });
    } catch (e) {
      debugPrint('User sync failed: $e');
    }
  }

  void _syncMeasurementsToServer() => unawaited(_pushMeasurementsToServer());

  Future<void> _pushMeasurementsToServer() async {
    if (!_hasSession) return;
    try {
      await _measurementRepository.replaceAll(bodyMeasurements);
    } catch (e) {
      debugPrint('Measurements sync failed: $e');
    }
  }

  void _syncWeightToServer(double kg, double bodyFatPct) =>
      unawaited(_pushWeightToServer(kg, bodyFatPct));

  Future<void> _pushWeightToServer(double kg, double bodyFatPct) async {
    if (!_hasSession) return;
    try {
      await _weightRepository.add(kg, bodyFatPct);
    } catch (e) {
      debugPrint('Weight sync failed: $e');
    }
  }

  void _syncMeasurementZoneToServer(MuscleZone zone, double valueCm) =>
      unawaited(_pushMeasurementZoneToServer(zone, valueCm));

  Future<void> _pushMeasurementZoneToServer(MuscleZone zone, double valueCm) async {
    if (!_hasSession) return;
    try {
      await _measurementRepository.updateZone(zone, valueCm);
    } catch (e) {
      debugPrint('Measurement zone sync failed: $e');
    }
  }

  // ---- Auth / onboarding -------------------------------------------------
  AuthStage authStage = AuthStage.splash;
  String? _pendingEmail;
  String? _pendingPassword;
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
    _pendingPassword = password;
    authStage = AuthStage.chooseUsername;
    notifyListeners();
  }

  /// Logs in against the real backend. Throws [ApiException] (bad
  /// credentials, banned account) or a network error on failure — the
  /// sign-in screen catches this and shows a message; there's no
  /// meaningful offline fallback for authenticating an identity.
  Future<void> signIn(String email, String password) async {
    final resolvedEmail = email.trim().isEmpty ? 'alex@bodyx.app' : email.trim();
    user = await _authRepository.login(email: resolvedEmail, password: password);
    authStage = AuthStage.done;
    _hasSession = true;
    _persistUser();
    unawaited(_persistence.setOnboardingDone(true));
    notifyListeners();
  }

  /// Creates the account against the real backend — this is the single
  /// point in the sign-up flow where the account actually gets created.
  /// Throws on failure (duplicate email/username, network error); the
  /// username screen catches this and shows a message, staying put.
  Future<void> submitUsername(String username) async {
    final resolvedUsername = username.trim().isEmpty ? 'newuser' : username.trim();
    user = await _authRepository.register(
      email: _pendingEmail ?? 'you@bodyx.app',
      username: resolvedUsername,
      password: _pendingPassword ?? '',
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
    _syncUserToServer();
    _syncMeasurementsToServer();
    notifyListeners();
  }

  void signOut() {
    user = null;
    _pendingEmail = null;
    _pendingPassword = null;
    navIndex = 0;
    authStage = AuthStage.signIn;
    _hasSession = false;
    unawaited(_persistence.clearSession());
    unawaited(_authRepository.signOut());
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
    _syncWeightToServer(kg, bodyFatPct);
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
    _syncMeasurementZoneToServer(zone, valueCm);
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
    _syncUserToServer();
    notifyListeners();
  }

  void updateGender(Gender gender) {
    if (user == null) return;
    user!.gender = gender;
    bodyViewerGender = gender;
    bodyMeasurements = MockData.generateBodyMeasurements(gender);
    _persistUser();
    _persistMeasurements();
    _syncUserToServer();
    _syncMeasurementsToServer();
    notifyListeners();
  }

  void updateHeightWeightAge({double? heightCm, double? weightKg, int? age}) {
    if (user == null) return;
    if (heightCm != null) user!.heightCm = heightCm;
    if (weightKg != null) user!.weightKg = weightKg;
    if (age != null) user!.age = age;
    _persistUser();
    _syncUserToServer();
    notifyListeners();
  }

  void toggleUnits() {
    if (user == null) return;
    user!.unitsMetric = !user!.unitsMetric;
    _persistUser();
    _syncUserToServer();
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
}
