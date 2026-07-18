import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../logic/health_insights.dart';
import '../models/models.dart';
import '../network/auth_repository.dart';
import '../network/measurement_repository.dart';
import '../network/profile_repository.dart';
import '../network/support_repository.dart';
import '../network/weight_repository.dart';
import 'health_service.dart';
import 'notification_service.dart';
import 'persistence_service.dart';
import 'progress_photo_storage.dart';

enum AuthStage {
  splash,
  signIn,
  signUp,
  chooseUsername,
  bodyData,
  done,
  forgotPassword,
  resetPassword,
}

/// Single source of truth for the whole prototype. Everything the UI reads
/// (auth flow, dashboard numbers, body measurements, plan, alerts) lives
/// here so every screen updates reactively when mock data changes.
///
/// Anything the user actively logs or configures (profile, weight/
/// measurement history, plan/alert read-state, settings, today's water/
/// meals) is persisted via [PersistenceService] and restored on the next
/// launch through [hydrate]. Generated demo history (daily steps/calories/
/// sleep) is deliberately re-rolled each session so the dashboard always
/// feels alive — meals start empty each day since there's no realistic way
/// to fake "what you ate" the way a step count can be simulated.
class AppState extends ChangeNotifier {
  AppState({
    PersistenceService? persistence,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    WeightRepository? weightRepository,
    MeasurementRepository? measurementRepository,
    SupportRepository? supportRepository,
  })  : _persistence = persistence ?? PersistenceService(),
        _authRepository = authRepository ?? ApiAuthRepository(),
        _profileRepository = profileRepository ?? ApiProfileRepository(),
        _weightRepository = weightRepository ?? ApiWeightRepository(),
        _measurementRepository =
            measurementRepository ?? ApiMeasurementRepository(),
        _supportRepository = supportRepository ?? ApiSupportRepository() {
    dailyStats = MockData.generateDailyStats();
    weightHistory = MockData.generateWeightHistory();
    bodyMeasurements = MockData.generateBodyMeasurements(Gender.male);
    alerts = MockData.alerts;
    planTasks = MockData.todayPlan;
    todayWorkout = MockData.todayWorkout;
    meals = [];
    progressPhotos = [];
  }

  final PersistenceService _persistence;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final WeightRepository _weightRepository;
  final MeasurementRepository _measurementRepository;
  final SupportRepository _supportRepository;
  bool _hasSession = false;

  // ---- Support tickets -----------------------------------------------------
  // Always fetched live from the server (no local persistence/offline cache)
  // — a support thread is only ever meaningful in sync with the admin side.
  Future<List<SupportTicket>> listSupportTickets() =>
      _supportRepository.listTickets();

  Future<SupportTicket> getSupportTicket(String ticketId) =>
      _supportRepository.getTicket(ticketId);

  Future<SupportTicket> createSupportTicket(String subject, String message) =>
      _supportRepository.createTicket(subject, message);

  Future<SupportTicket> addSupportTicketMessage(String ticketId, String text) =>
      _supportRepository.addMessage(ticketId, text);

  /// Loads any persisted session/data over the freshly-seeded mock state.
  /// Call once, right after construction and before [runApp] — cheap and
  /// fast enough not to need its own loading screen.
  Future<void> hydrate() async {
    final savedLocaleCode = await _persistence.loadLocaleCode();
    if (savedLocaleCode != null) {
      locale = Locale(savedLocaleCode);
    }

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

    final savedPhotos = await _persistence.loadProgressPhotos();
    if (savedPhotos != null) {
      progressPhotos = savedPhotos;
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

    final savedWaterLog = await _persistence.loadTodayWaterLog();
    if (savedWaterLog != null && savedWaterLog.isNotEmpty) {
      todayWaterLog = savedWaterLog;
      _applyTodayWaterTotal();
    }

    final savedMeals = await _persistence.loadTodayMeals();
    if (savedMeals != null) {
      meals = savedMeals;
    }

    final savedWorkoutDone = await _persistence.loadTodayWorkoutSetsDone();
    if (savedWorkoutDone != null &&
        savedWorkoutDone.length == todayWorkout.sets.length) {
      for (var i = 0; i < savedWorkoutDone.length; i++) {
        todayWorkout.sets[i].done = savedWorkoutDone[i];
      }
    }

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
  String? _pendingResetEmail;
  String? get pendingResetEmail => _pendingResetEmail;
  UserProfile? user;

  /// Dev-mode only: the raw reset code echoed back by the backend when no
  /// SMTP is configured yet, so the flow is testable without an inbox.
  /// Always null once real email delivery is wired up server-side.
  String? devResetCode;

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

  void goToForgotPassword() {
    devResetCode = null;
    authStage = AuthStage.forgotPassword;
    notifyListeners();
  }

  /// Requests a reset code for [email]. Always succeeds server-side (no
  /// email enumeration) — throws only on a network/server error, which the
  /// forgot-password screen surfaces via [describeApiError].
  Future<void> requestPasswordReset(String email) async {
    final resolvedEmail = email.trim();
    devResetCode = await _authRepository.forgotPassword(resolvedEmail);
    _pendingResetEmail = resolvedEmail;
    authStage = AuthStage.resetPassword;
    notifyListeners();
  }

  /// Verifies [code] and sets [newPassword], logging the user in on success
  /// — same as [signIn]. Throws [ApiException] on an invalid/expired/reused
  /// code or a password that fails strength rules; the reset-password
  /// screen catches this and shows a message, staying put.
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    user = await _authRepository.resetPassword(
      email: _pendingResetEmail ?? '',
      code: code,
      newPassword: newPassword,
    );
    devResetCode = null;
    authStage = AuthStage.done;
    _hasSession = true;
    _persistUser();
    unawaited(_persistence.setOnboardingDone(true));
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

  /// Verifies [idToken] server-side and logs in, creating the account on
  /// first sign-in. Throws [ApiException] on an invalid token or if the
  /// backend's Google client ID isn't configured yet (501).
  Future<void> signInWithGoogle(String idToken) async {
    user = await _authRepository.loginWithGoogle(idToken);
    authStage = AuthStage.done;
    _hasSession = true;
    _persistUser();
    unawaited(_persistence.setOnboardingDone(true));
    notifyListeners();
  }

  /// Verifies [identityToken] server-side and logs in, creating the account
  /// on first sign-in. Throws [ApiException] on an invalid token or if the
  /// backend's Apple client ID isn't configured yet (501).
  Future<void> signInWithApple(String identityToken) async {
    user = await _authRepository.loginWithApple(identityToken);
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
    _pendingResetEmail = null;
    devResetCode = null;
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
  late Workout todayWorkout;
  late List<ProgressPhoto> progressPhotos;
  List<WaterLogEntry> todayWaterLog = [];

  void togglePlanTask(int index) {
    planTasks[index].done = !planTasks[index].done;
    _persistPlanTasks();
    notifyListeners();
  }

  void toggleWorkoutSet(int index) {
    final set = todayWorkout.sets[index];
    set.done = !set.done;
    if (set.done) HapticFeedback.mediumImpact();
    unawaited(_persistence.saveTodayWorkoutSetsDone(
        todayWorkout.sets.map((s) => s.done).toList()));
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

  /// Combines the weight trend with the body-fat% trend into one verdict —
  /// see [HealthInsights.weightVerdict] for why neither number alone is
  /// enough to tell "gaining muscle" from "gaining fat".
  StatusResult get weightVerdict => HealthInsights.weightVerdict(weightHistory);

  /// True once a weight entry has actually been logged today — drives the
  /// "Log body weight" checklist item off real data instead of a togglable
  /// checkbox that could be ticked without doing anything.
  bool get loggedWeightToday {
    if (weightHistory.isEmpty) return false;
    final last = weightHistory.last.date;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  // Unlike most other persisted fields in this class, the photo metadata
  // save is awaited (not fire-and-forget) before these methods return —
  // photos are irreplaceable, and the goal of this feature is a reliable
  // long-term record, so it's worth shrinking (not eliminating) the crash
  // window between a file landing on disk and its metadata being saved.
  Future<void> addProgressPhoto(ProgressPhoto photo) async {
    HapticFeedback.mediumImpact();
    progressPhotos = [photo, ...progressPhotos]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _persistence.saveProgressPhotos(progressPhotos);
  }

  Future<void> deleteProgressPhoto(ProgressPhoto photo) async {
    await ProgressPhotoStorage.instance.delete(photo.fileName);
    progressPhotos = progressPhotos.where((p) => p.id != photo.id).toList();
    notifyListeners();
    await _persistence.saveProgressPhotos(progressPhotos);
  }

  // ---- Calories / protein --------------------------------------------------

  double get tdee => user == null
      ? 2200
      : HealthInsights.tdee(
          gender: user!.gender,
          weightKg: user!.weightKg,
          heightCm: user!.heightCm,
          age: user!.age,
          activityLevel: user!.activityLevel,
        );

  /// Calories actually eaten today — from logged meals, not [DailyStats
  /// .calories] (that field holds *active calories burned*, the same one
  /// Health sync overwrites from HealthKit's ACTIVE_ENERGY_BURNED, so it
  /// isn't comparable to TDEE the way a surplus needs).
  int get todayCaloriesEaten => meals.fold<int>(0, (sum, m) => sum + m.kcal);

  int get calorieSurplus => todayCaloriesEaten - tdee.round();

  StatusResult get calorieSurplusStatus =>
      HealthInsights.calorieSurplusStatus(calorieSurplus);

  double get proteinTargetG =>
      HealthInsights.proteinTargetG(user?.weightKg ?? 75);

  double get todayProteinG =>
      meals.fold<double>(0, (sum, m) => sum + m.proteinG);

  StatusResult get proteinStatus =>
      HealthInsights.proteinStatus(todayProteinG, proteinTargetG);

  // ---- Heart rate -----------------------------------------------------------

  ({String label, StatusLevel level}) get hrZone => HealthInsights.hrZoneFor(
        bpm: selectedStats.heartRateBpm,
        age: user?.age ?? 25,
      );

  double get hrZoneFraction => HealthInsights.hrZoneFraction(
        bpm: selectedStats.heartRateBpm,
        age: user?.age ?? 25,
      );

  /// Trend vs. the last 7 days *excluding* today — a rising number here is
  /// often the earliest sign of under-recovery, before it shows up anywhere
  /// else.
  StatusResult get restingHrTrend {
    final priorDays = dailyStats.length > 1
        ? dailyStats
            .sublist(0, dailyStats.length - 1)
            .reversed
            .take(7)
            .map((s) => s.heartRateBpm)
            .toList()
        : <int>[];
    return HealthInsights.restingHrTrend(
      todayBpm: dailyStats.last.heartRateBpm,
      priorDaysBpm: priorDays,
    );
  }

  // ---- Water --------------------------------------------------------------

  /// True if today's plan includes a workout — bumps the water target per
  /// [HealthInsights.waterGoalMl].
  bool get isWorkoutDayToday => todayWorkout.sets.isNotEmpty;

  int get individualizedWaterGoalMl => HealthInsights.waterGoalMl(
        weightKg: user?.weightKg ?? 75,
        isWorkoutDay: isWorkoutDayToday,
      );

  /// Pace-aware status for *today* only — a rolling window like this can't
  /// be meaningfully computed for a past date, so callers should only show
  /// it when [selectedDateIndex] is -1 (today).
  StatusResult get todayWaterStatus => HealthInsights.waterStatus(
        consumedMl: dailyStats.last.waterMl,
        goalMl: individualizedWaterGoalMl,
        now: DateTime.now(),
      );

  void logWater(int ml) {
    HapticFeedback.lightImpact();
    todayWaterLog = [...todayWaterLog, WaterLogEntry(DateTime.now(), ml)];
    _applyTodayWaterTotal();
    unawaited(_persistence.saveTodayWaterLog(todayWaterLog));
    notifyListeners();
  }

  void _applyTodayWaterTotal() {
    final total = todayWaterLog.fold<int>(0, (sum, e) => sum + e.ml);
    final today = dailyStats.last;
    final updated = List<DailyStats>.from(dailyStats);
    updated[updated.length - 1] = DailyStats(
      date: today.date,
      steps: today.steps,
      stepGoal: today.stepGoal,
      calories: today.calories,
      calorieGoal: today.calorieGoal,
      sleepMinutes: today.sleepMinutes,
      sleepGoalMinutes: today.sleepGoalMinutes,
      waterMl: total,
      waterGoalMl: individualizedWaterGoalMl,
      lightSleepMinutes: today.lightSleepMinutes,
      deepSleepMinutes: today.deepSleepMinutes,
      remSleepMinutes: today.remSleepMinutes,
      awakeMinutes: today.awakeMinutes,
      heartRateBpm: today.heartRateBpm,
    );
    dailyStats = updated;
  }

  // ---- Meals --------------------------------------------------------------

  void logMeal(MealEntry meal) {
    meals = [...meals, meal];
    unawaited(_persistence.saveTodayMeals(meals));
    notifyListeners();
  }

  void removeMeal(int index) {
    final updated = List<MealEntry>.from(meals)..removeAt(index);
    meals = updated;
    unawaited(_persistence.saveTodayMeals(meals));
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
  bool healthSyncEnabled = false;

  /// Null means "follow system locale". Only set once the user picks a
  /// language explicitly in Settings.
  Locale? locale;

  void setLocale(Locale? value) {
    locale = value;
    unawaited(_persistence.saveLocaleCode(value?.languageCode));
    notifyListeners();
  }

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
