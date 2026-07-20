import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../logic/health_insights.dart';
import '../models/models.dart';
import '../network/announcement_repository.dart';
import '../network/api_client.dart';
import '../network/auth_repository.dart';
import '../network/measurement_repository.dart';
import '../network/profile_repository.dart';
import '../network/support_repository.dart';
import '../network/weight_repository.dart';
import 'health_service.dart';
import 'live_activity_service.dart';
import 'notification_service.dart';
import 'persistence_service.dart';
import 'progress_photo_storage.dart';
import 'widget_overview_service.dart';

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

/// Single source of truth for the whole app. Everything the UI reads
/// (auth flow, dashboard numbers, body measurements, plan, alerts) lives
/// here so every screen updates reactively when state changes.
///
/// Anything the user actively logs or configures (profile, weight/
/// measurement history, plan/alert read-state, settings, today's water/
/// meals) is persisted via [PersistenceService] and restored on the next
/// launch through [hydrate]. A fresh account starts every metric at an
/// honest zero/empty state (see [MockData.emptyDailyStats]/
/// [MockData.emptyBodyMeasurements]) rather than fabricated history — real
/// numbers come from the user's own logging or, once enabled, a real
/// HealthKit/Health Connect sync via [syncHealthData].
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  AppState({
    PersistenceService? persistence,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    WeightRepository? weightRepository,
    MeasurementRepository? measurementRepository,
    SupportRepository? supportRepository,
    AnnouncementRepository? announcementRepository,
  })  : _persistence = persistence ?? PersistenceService(),
        _authRepository = authRepository ?? ApiAuthRepository(),
        _profileRepository = profileRepository ?? ApiProfileRepository(),
        _weightRepository = weightRepository ?? ApiWeightRepository(),
        _measurementRepository =
            measurementRepository ?? ApiMeasurementRepository(),
        _supportRepository = supportRepository ?? ApiSupportRepository(),
        _announcementRepository =
            announcementRepository ?? ApiAnnouncementRepository() {
    dailyStats = MockData.emptyDailyStats();
    weightHistory = [];
    bodyMeasurements = MockData.emptyBodyMeasurements(Gender.male);
    planTasks = MockData.todayPlan;
    todayWorkoutSets = [];
    todayMobilityActivities = [];
    meals = [];
    progressPhotos = [];
    WidgetsBinding.instance.addObserver(this);
    _announcementPollTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _pollAnnouncements());
  }

  @override
  void dispose() {
    _announcementPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A running timer's Lock Screen "Stop" button ends the Live Activity
  /// directly from the widget extension, which has no Flutter engine to
  /// call back into — so the app only finds out once it's actually running
  /// again. Checked here (foreground) and once more at the end of
  /// [hydrate] (cold start), which together cover every way the app can
  /// come back after the button was tapped while it wasn't in the
  /// foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rolloverToNewDayIfNeeded();
      unawaited(_reconcilePendingLiveActivityStop());
    }
  }

  /// iOS keeps apps suspended for days — [hydrate]'s day-scoping only runs
  /// on a cold launch, so without this a user who reopens the app on a new
  /// day would see yesterday's meals/water/workout presented as "today",
  /// and anything they log would land on yesterday's [DailyStats] entry.
  /// Mirrors exactly what a fresh launch produces for a new day.
  void _rolloverToNewDayIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (dailyStats.last.date == today) return;

    dailyStats = MockData.emptyDailyStats();
    todayWaterLog = [];
    meals = [];
    todayWorkoutSets = [];
    _workoutAccumulatedSeconds = 0;
    _workoutTimerStartedAt = null;
    todayMobilityActivities = [];
    _mobilityCountdownTimer?.cancel();
    _mobilityCountdownTimer = null;
    activeMobilityCountdownIndex = null;
    _mobilityCountdownEndsAt = null;
    unawaited(LiveActivityService.instance.end('workout'));
    unawaited(LiveActivityService.instance.end('mobility'));
    unawaited(_persistence.saveTodayWaterLog(todayWaterLog));
    unawaited(_persistence.saveTodayMeals(meals));
    unawaited(_persistence.saveTodayWorkoutSets(todayWorkoutSets));
    unawaited(_persistence.saveTodayWorkoutTimer(0, null));
    unawaited(_persistence.saveTodayMobilityActivities(todayMobilityActivities));
    if (healthSyncEnabled) unawaited(syncHealthData());
    _pushWidgetOverview();
    notifyListeners();
  }

  Future<void> _reconcilePendingLiveActivityStop() async {
    final kind = await LiveActivityService.instance.consumePendingStop();
    if (kind == 'workout') {
      _applyExternalWorkoutStop();
    } else if (kind == 'mobility' && activeMobilityCountdownIndex != null) {
      cancelMobilityCountdown();
    }
  }

  final PersistenceService _persistence;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final WeightRepository _weightRepository;
  final MeasurementRepository _measurementRepository;
  final SupportRepository _supportRepository;
  final AnnouncementRepository _announcementRepository;
  bool _hasSession = false;

  // ---- Announcements --------------------------------------------------------
  // Admin-broadcast banners (see the Announcements view in /admin) — fetched
  // on session restore and re-polled periodically (there's no push channel
  // here) so one created while the app is already open still shows up
  // without the user having to restart it. Dismissed ids persist locally so
  // a banner the user closed doesn't reappear on this device.
  List<Announcement> _announcements = [];
  final Set<String> _dismissedAnnouncementIds = {};
  Timer? _announcementPollTimer;

  Future<void> _pollAnnouncements() async {
    if (!_hasSession) return;
    try {
      final fetched = await _announcementRepository.listActive();
      final changed = fetched.length != _announcements.length ||
          !fetched.every((a) => _announcements.any((b) => b.id == a.id));
      if (changed) {
        _announcements = fetched;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to poll announcements: $e');
    }
  }

  List<Announcement> get activeAnnouncements => _announcements
      .where((a) => !_dismissedAnnouncementIds.contains(a.id))
      .toList();

  void dismissAnnouncement(String id) {
    _dismissedAnnouncementIds.add(id);
    unawaited(
        _persistence.saveDismissedAnnouncementIds(_dismissedAnnouncementIds));
    notifyListeners();
  }

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

    final savedDismissedIds =
        await _persistence.loadDismissedAnnouncementIds();
    _dismissedAnnouncementIds
      ..clear()
      ..addAll(savedDismissedIds);

    // A previous account deletion whose server call failed leaves this flag
    // (written after the local wipe, so it's the only thing that survives).
    // Retry best-effort using the JWT still in Keychain — cleared only once
    // the server confirms — and never restore a session for a user who asked
    // for the account to be gone.
    if (await _persistence.loadPendingAccountDeletion()) {
      unawaited(_retryPendingAccountDeletion());
      return;
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

    final savedReadIds = await _persistence.loadReadAlertIds();
    if (savedReadIds != null) {
      _readAlertIds
        ..clear()
        ..addAll(savedReadIds);
    }

    notificationsEnabled =
        await _persistence.loadNotificationsEnabled() ?? notificationsEnabled;
    workoutRemindersEnabled = await _persistence.loadWorkoutRemindersEnabled() ??
        workoutRemindersEnabled;
    healthSyncEnabled =
        await _persistence.loadHealthSyncEnabled() ?? healthSyncEnabled;
    publicProfile = await _persistence.loadPublicProfile() ?? publicProfile;
    shareAnonData = await _persistence.loadShareAnonData() ?? shareAnonData;

    final savedWaterLog = await _persistence.loadTodayWaterLog();
    if (savedWaterLog != null && savedWaterLog.isNotEmpty) {
      todayWaterLog = savedWaterLog;
      _applyTodayWaterTotal();
    }

    final savedMeals = await _persistence.loadTodayMeals();
    if (savedMeals != null) {
      meals = savedMeals;
    }

    final savedWorkoutSets = await _persistence.loadTodayWorkoutSets();
    if (savedWorkoutSets != null) {
      todayWorkoutSets = savedWorkoutSets;
    }

    final savedTimer = await _persistence.loadTodayWorkoutTimer();
    if (savedTimer != null) {
      final (seconds, startedAt) = savedTimer;
      _workoutAccumulatedSeconds = seconds;
      _workoutTimerStartedAt = startedAt;
    }

    final savedMobility = await _persistence.loadTodayMobilityActivities();
    if (savedMobility != null) {
      todayMobilityActivities = savedMobility;
    }

    // Best-effort, matching this method's own doc comment ("never blocks
    // or degrades it") — it wasn't actually non-blocking before: awaiting
    // an up-to-8s network round trip here held up runApp() itself, so an
    // unreachable/slow backend could delay the first frame long enough for
    // iOS's launch watchdog to kill a cold (non-debugger-attached) launch
    // before it ever rendered anything.
    unawaited(_restoreServerSession());
    _pushWidgetOverview();
    // Best-effort and non-blocking, like every other native sync in this
    // method — a Live Activity stop signal should never hold up the splash
    // screen while the app waits on a platform-channel round trip.
    unawaited(_reconcilePendingLiveActivityStop());
  }

  /// Mirrors today's numbers into the Home Screen widget — call after any
  /// mutation that changes what the dashboard's Daily overview card shows.
  void _pushWidgetOverview() =>
      unawaited(WidgetOverviewService.instance.push(dailyStats.last));

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

    try {
      _announcements = await _announcementRepository.listActive();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch announcements during session restore: $e');
    }
  }

  void _persistUser() {
    if (user != null) unawaited(_persistence.saveUserProfile(user!));
  }

  void _persistPlanTasks() => unawaited(
      _persistence.savePlanTaskDone(planTasks.map((t) => t.done).toList()));

  void _persistAlerts() =>
      unawaited(_persistence.saveReadAlertIds(_readAlertIds));

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

  /// Logs in against the real backend. If the *server itself* rejects the
  /// attempt ([ApiException] — bad credentials, banned account), that's
  /// re-thrown so the sign-in screen can show the real reason. If the
  /// server is simply unreachable (no backend deployed yet, offline,
  /// timeout), falls back to a local-only profile instead of blocking the
  /// app — the same "local always works" behavior every other network
  /// feature here already has (health sync, profile/weight/measurement
  /// sync all swallow connectivity failures rather than erroring out).
  /// [rememberMe] controls whether the session survives an app restart —
  /// when false (the default — an explicit opt-in is required to stay
  /// signed in), the sign-in still succeeds for the current app run, but
  /// neither the "onboarding done" flag nor the Keychain token are kept, so
  /// [hydrate] finds no session next launch and the user has to sign in
  /// again (see [hydrate]'s `onboardingDone` gate).
  Future<void> signIn(String email, String password,
      {bool rememberMe = false}) async {
    final resolvedEmail = email.trim().isEmpty ? 'alex@bodyx.app' : email.trim();
    try {
      user = await _authRepository.login(email: resolvedEmail, password: password);
    } on ApiException {
      rethrow;
    } catch (_) {
      user = UserProfile(
        email: resolvedEmail,
        username: resolvedEmail.split('@').first.isEmpty
            ? 'alex'
            : resolvedEmail.split('@').first,
      );
    }
    authStage = AuthStage.done;
    _hasSession = true;
    if (rememberMe) {
      _persistUser();
      unawaited(_persistence.setOnboardingDone(true));
    } else {
      unawaited(_authRepository.signOut());
    }
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

  /// Creates the account against the real backend when one is reachable.
  /// A real rejection from the server ([ApiException] — duplicate email/
  /// username) is re-thrown so the username screen can show it. An
  /// unreachable server falls back to a local-only profile, same as
  /// [signIn].
  Future<void> submitUsername(String username) async {
    final resolvedUsername = username.trim().isEmpty ? 'newuser' : username.trim();
    try {
      user = await _authRepository.register(
        email: _pendingEmail ?? 'you@bodyx.app',
        username: resolvedUsername,
        password: _pendingPassword ?? '',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      user = UserProfile(
        email: _pendingEmail ?? 'you@bodyx.app',
        username: resolvedUsername,
      );
    }
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
    bodyMeasurements = MockData.emptyBodyMeasurements(gender);
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

  /// Permanently deletes the account. The server-side deletion is
  /// best-effort — swallowed on failure, same as every other network call
  /// in this class — but every local trace (profile, weight/measurement
  /// history, photos, settings) is always wiped and the session always
  /// ends, so deletion works for the user even when the backend is
  /// unreachable.
  Future<void> deleteAccount() async {
    var serverDeleteSucceeded = true;
    try {
      await _authRepository.deleteAccount();
    } catch (e) {
      serverDeleteSucceeded = false;
      debugPrint('Server-side account deletion failed: $e');
    }
    // A photo-directory failure must not abort the rest of the wipe — the
    // prefs clear and in-memory reset below still have to happen.
    try {
      await ProgressPhotoStorage.instance.deleteAll();
    } catch (e) {
      debugPrint('Progress photo wipe failed: $e');
    }
    await _persistence.clearAllData();
    // Written AFTER the wipe so it survives it — next launch retries the
    // server delete (see [hydrate]) instead of silently forgetting it.
    if (!serverDeleteSucceeded) {
      await _persistence.savePendingAccountDeletion(true);
    }
    _finishAccountReset();
  }

  Future<void> _retryPendingAccountDeletion() async {
    try {
      await _authRepository.deleteAccount();
      await _persistence.savePendingAccountDeletion(false);
      debugPrint('Pending server-side account deletion completed');
    } catch (e) {
      // Still unreachable — flag stays set, retried again next launch.
      debugPrint('Pending account deletion retry failed: $e');
    }
  }

  void _finishAccountReset() {
    user = null;
    _pendingEmail = null;
    _pendingPassword = null;
    _pendingResetEmail = null;
    devResetCode = null;
    navIndex = 0;
    authStage = AuthStage.signIn;
    _hasSession = false;
    progressPhotos = [];
    weightHistory = [];
    bodyMeasurements = MockData.emptyBodyMeasurements(Gender.male);
    meals = [];
    todayWorkoutSets = [];
    _workoutAccumulatedSeconds = 0;
    _workoutTimerStartedAt = null;
    todayMobilityActivities = [];
    _mobilityCountdownTimer?.cancel();
    _mobilityCountdownTimer = null;
    activeMobilityCountdownIndex = null;
    _mobilityCountdownEndsAt = null;
    todayWaterLog = [];
    dailyStats = MockData.emptyDailyStats();
    _readAlertIds.clear();
    unawaited(LiveActivityService.instance.end('workout'));
    unawaited(LiveActivityService.instance.end('mobility'));
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
  late List<ProgressPhoto> progressPhotos;
  List<WaterLogEntry> todayWaterLog = [];

  // ---- Workout (fully user-defined — no fixed template) --------------------
  //
  // The user builds today's exercise list themselves (see [addExercise]);
  // there's no mock "Lower Body Strength" starter data, so this starts
  // empty every day until they add something.
  late List<WorkoutSet> todayWorkoutSets;
  int _workoutAccumulatedSeconds = 0;
  DateTime? _workoutTimerStartedAt;

  int get todayWorkoutCompletedSets =>
      todayWorkoutSets.where((s) => s.done).length;

  double get todayWorkoutProgress => todayWorkoutSets.isEmpty
      ? 0
      : todayWorkoutCompletedSets / todayWorkoutSets.length;

  void togglePlanTask(int index) {
    planTasks[index].done = !planTasks[index].done;
    _persistPlanTasks();
    notifyListeners();
  }

  void toggleWorkoutSet(int index) {
    final set = todayWorkoutSets[index];
    set.done = !set.done;
    if (set.done) HapticFeedback.mediumImpact();
    _persistWorkoutSets();
    notifyListeners();
  }

  /// Appends [setCount] fresh (unchecked) sets of [exercise] to today's
  /// workout, e.g. addExercise('Bench Press', 4, 8) adds 4 sets of 8 reps.
  void addExercise(String exercise, int setCount, int targetReps) {
    HapticFeedback.mediumImpact();
    todayWorkoutSets = [
      ...todayWorkoutSets,
      for (var i = 1; i <= setCount; i++)
        WorkoutSet(exercise: exercise, setNumber: i, targetReps: targetReps),
    ];
    _persistWorkoutSets();
    notifyListeners();
  }

  /// Removes every set belonging to [exercise] — the unit a user thinks in
  /// terms of ("delete Bench Press"), not individual sets.
  void removeExercise(String exercise) {
    todayWorkoutSets =
        todayWorkoutSets.where((s) => s.exercise != exercise).toList();
    _persistWorkoutSets();
    notifyListeners();
  }

  void _persistWorkoutSets() =>
      unawaited(_persistence.saveTodayWorkoutSets(todayWorkoutSets));

  bool get isWorkoutTimerRunning => _workoutTimerStartedAt != null;

  /// Total time spent on today's workout — sums every past start/stop
  /// segment plus whatever's elapsed in the currently-running one, if any.
  Duration get todayWorkoutElapsed {
    final startedAt = _workoutTimerStartedAt;
    final liveSeconds =
        startedAt == null ? 0 : DateTime.now().difference(startedAt).inSeconds;
    return Duration(seconds: _workoutAccumulatedSeconds + liveSeconds);
  }

  /// One button, two behaviors: starts the timer if it's stopped, stops
  /// (and banks the elapsed time) if it's running — mirroring "press at
  /// the start of the workout, press again at the end."
  void toggleWorkoutTimer() {
    HapticFeedback.mediumImpact();
    final startedAt = _workoutTimerStartedAt;
    if (startedAt == null) {
      _workoutTimerStartedAt = DateTime.now();
    } else {
      _workoutAccumulatedSeconds +=
          DateTime.now().difference(startedAt).inSeconds;
      _workoutTimerStartedAt = null;
    }
    unawaited(_persistence.saveTodayWorkoutTimer(
        _workoutAccumulatedSeconds, _workoutTimerStartedAt));
    _syncTimerLiveActivity(
      'workout',
      lookupAppLocalizations(_effectiveLocale).planTodaysWorkoutTitle,
      _workoutAccumulatedSeconds,
      _workoutTimerStartedAt,
    );
    notifyListeners();
  }

  /// Zeroes the timer back to 0:00, whether it was running or stopped —
  /// for starting the clock over without leaving the sheet.
  void resetWorkoutTimer() {
    HapticFeedback.selectionClick();
    _workoutAccumulatedSeconds = 0;
    _workoutTimerStartedAt = null;
    unawaited(_persistence.saveTodayWorkoutTimer(
        _workoutAccumulatedSeconds, _workoutTimerStartedAt));
    unawaited(LiveActivityService.instance.end('workout'));
    notifyListeners();
  }

  /// Starts/updates a Lock Screen Live Activity mirroring a session timer
  /// — best-effort, iOS-only, and never blocks the actual timer state
  /// (see [LiveActivityService]).
  void _syncTimerLiveActivity(
      String kind, String title, int accumulatedSeconds, DateTime? startedAt) {
    unawaited(LiveActivityService.instance.startOrUpdate(
      kind: kind,
      title: title,
      accumulatedSeconds: accumulatedSeconds,
      startedAt: startedAt,
    ));
  }

  /// Mirrors what [toggleWorkoutTimer]'s stop branch does, for when the
  /// stop happened via the Lock Screen button instead of an in-app tap —
  /// the native side has already ended the Live Activity, so this only
  /// needs to bank the elapsed time into local/persisted state.
  void _applyExternalWorkoutStop() {
    final startedAt = _workoutTimerStartedAt;
    if (startedAt == null) return;
    _workoutAccumulatedSeconds += DateTime.now().difference(startedAt).inSeconds;
    _workoutTimerStartedAt = null;
    unawaited(_persistence.saveTodayWorkoutTimer(
        _workoutAccumulatedSeconds, _workoutTimerStartedAt));
    notifyListeners();
  }

  // ---- Mobility / stretch (also fully user-defined) ------------------------
  //
  // Same "no fixed template" shape as the workout — starts empty every
  // day, the user adds their own activities.
  late List<MobilityActivity> todayMobilityActivities;

  // ---- Per-activity countdown: completion is earned, not self-declared —
  // tapping an activity starts a countdown of its planned minutes, and only
  // the countdown finishing marks it done (with sound), so "done" always
  // means the time was actually spent.
  int? activeMobilityCountdownIndex;
  DateTime? _mobilityCountdownEndsAt;
  Timer? _mobilityCountdownTimer;

  Duration? get mobilityCountdownRemaining {
    final endsAt = _mobilityCountdownEndsAt;
    if (endsAt == null) return null;
    final left = endsAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Starts the countdown for [index]; tapping the already-running one
  /// cancels it instead (nothing gets marked done). Mirrors the workout
  /// timer's Live Activity — shows on the Lock Screen / Dynamic Island and
  /// is stoppable from there, just counting down instead of up.
  void startMobilityCountdown(int index) {
    if (activeMobilityCountdownIndex == index) {
      cancelMobilityCountdown();
      return;
    }
    HapticFeedback.mediumImpact();
    _mobilityCountdownTimer?.cancel();
    activeMobilityCountdownIndex = index;
    final activity = todayMobilityActivities[index];
    final duration = Duration(minutes: activity.minutes);
    final endsAt = DateTime.now().add(duration);
    _mobilityCountdownEndsAt = endsAt;
    _mobilityCountdownTimer = Timer(duration, _completeMobilityCountdown);
    unawaited(LiveActivityService.instance.startOrUpdate(
      kind: 'mobility',
      title: activity.name,
      accumulatedSeconds: 0,
      endsAt: endsAt,
    ));
    notifyListeners();
  }

  void cancelMobilityCountdown() {
    _mobilityCountdownTimer?.cancel();
    _mobilityCountdownTimer = null;
    activeMobilityCountdownIndex = null;
    _mobilityCountdownEndsAt = null;
    unawaited(LiveActivityService.instance.end('mobility'));
    notifyListeners();
  }

  void _completeMobilityCountdown() {
    final index = activeMobilityCountdownIndex;
    _mobilityCountdownTimer = null;
    activeMobilityCountdownIndex = null;
    _mobilityCountdownEndsAt = null;
    unawaited(LiveActivityService.instance.end('mobility'));
    if (index == null || index >= todayMobilityActivities.length) {
      notifyListeners();
      return;
    }
    final activity = todayMobilityActivities[index];
    activity.done = true;
    HapticFeedback.heavyImpact();
    _persistMobilityActivities();
    final l10n = lookupAppLocalizations(_effectiveLocale);
    unawaited(NotificationService.instance.showActivityCompleted(
      _effectiveLocale,
      l10n.mobilityActivityCompletedTitle,
      l10n.mobilityActivityCompletedBody(activity.name),
    ));
    notifyListeners();
  }

  int get todayMobilityCompletedCount =>
      todayMobilityActivities.where((a) => a.done).length;

  double get todayMobilityProgress => todayMobilityActivities.isEmpty
      ? 0
      : todayMobilityCompletedCount / todayMobilityActivities.length;

  void addMobilityActivity(String name, int minutes) {
    HapticFeedback.mediumImpact();
    todayMobilityActivities = [
      ...todayMobilityActivities,
      MobilityActivity(name: name, minutes: minutes),
    ];
    _persistMobilityActivities();
    notifyListeners();
  }

  void removeMobilityActivity(String name) {
    // Indices shift after removal, so any running countdown would complete
    // the wrong activity — cancel it rather than guess.
    if (activeMobilityCountdownIndex != null) cancelMobilityCountdown();
    todayMobilityActivities =
        todayMobilityActivities.where((a) => a.name != name).toList();
    _persistMobilityActivities();
    notifyListeners();
  }

  void toggleMobilityActivity(int index) {
    final activity = todayMobilityActivities[index];
    activity.done = !activity.done;
    if (activity.done) HapticFeedback.mediumImpact();
    _persistMobilityActivities();
    notifyListeners();
  }

  void _persistMobilityActivities() => unawaited(
      _persistence.saveTodayMobilityActivities(todayMobilityActivities));

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

  // ---- Water --------------------------------------------------------------

  /// True if today's plan includes a workout — bumps the water target per
  /// [HealthInsights.waterGoalMl].
  bool get isWorkoutDayToday => todayWorkoutSets.isNotEmpty;

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

  /// Undoes a single logged entry (e.g. a misclick on the wrong preset) —
  /// identity-based removal since [WaterLogEntry] has no id of its own.
  void removeWaterEntry(WaterLogEntry entry) {
    HapticFeedback.selectionClick();
    todayWaterLog = todayWaterLog.where((e) => e != entry).toList();
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
      sleepStagesSynced: today.sleepStagesSynced,
    );
    dailyStats = updated;
    _pushWidgetOverview();
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
  // Every alert here is derived live from a real, currently-true condition
  // in the user's own data — there is no fixed/fabricated list, and no
  // stored field to keep in sync: [alerts] recomputes on every access, so
  // it's always consistent with whatever water/health/photo state changed
  // most recently. Read state survives across rebuilds via the condition's
  // stable id in [_readAlertIds].
  final Set<String> _readAlertIds = {};

  List<AlertItem> get alerts => _buildAlerts();

  int get unreadAlertCount => alerts.where((a) => !a.read).length;

  void markAlertRead(String id) {
    _readAlertIds.add(id);
    _persistAlerts();
    notifyListeners();
  }

  void markAllAlertsRead() {
    for (final a in alerts) {
      _readAlertIds.add(a.id);
    }
    _persistAlerts();
    notifyListeners();
  }

  List<AlertItem> _buildAlerts() {
    final l10n = lookupAppLocalizations(_effectiveLocale);
    final now = DateTime.now();
    final today = dailyStats.last;
    final items = <AlertItem>[];

    if (now.hour >= 15 &&
        today.waterGoalMl > 0 &&
        today.waterMl < today.waterGoalMl * 0.5) {
      final behindLiters = (today.waterGoalMl - today.waterMl) / 1000;
      items.add(AlertItem(
        id: 'low_water',
        title: l10n.alertLowWaterTitle,
        subtitle: l10n.alertLowWaterSubtitle(behindLiters.toStringAsFixed(1)),
        icon: Icons.water_drop_rounded,
        severity: AlertSeverity.warning,
      ));
    }

    // Steps/sleep alerts need real history, which only exists once Health
    // sync has actually pulled it in — otherwise every day in [dailyStats]
    // is still the zeroed mock seed and any comparison would be fabricated.
    if (healthSyncEnabled) {
      final sleptDays = dailyStats.where((d) => d.sleepMinutes > 0).toList();
      if (sleptDays.length >= 3) {
        final avgMinutes =
            sleptDays.map((d) => d.sleepMinutes).reduce((a, b) => a + b) /
                sleptDays.length;
        if (avgMinutes < sleptDays.last.sleepGoalMinutes * 0.85) {
          items.add(AlertItem(
            id: 'sleep_debt',
            title: l10n.alertSleepDebtTitle,
            subtitle:
                l10n.alertSleepDebtSubtitle((avgMinutes / 60).toStringAsFixed(1)),
            icon: Icons.bedtime_rounded,
            severity: AlertSeverity.warning,
          ));
        }
      }

      final today0 = DateTime(now.year, now.month, now.day);
      final yesterday = today0.subtract(const Duration(days: 1));
      final pastDaysWithSteps = dailyStats
          .where((d) => d.date.isBefore(today0) && d.steps > 0)
          .toList()
        ..sort((a, b) => a.steps.compareTo(b.steps));
      if (pastDaysWithSteps.isNotEmpty) {
        final best = pastDaysWithSteps.last;
        final secondBest = pastDaysWithSteps.length > 1
            ? pastDaysWithSteps[pastDaysWithSteps.length - 2].steps
            : -1;
        if (best.date == yesterday && best.steps > secondBest) {
          items.add(AlertItem(
            id: 'steps_personal_best',
            title: l10n.alertStepsBestTitle,
            subtitle: l10n.alertStepsBestSubtitle(best.steps.toString()),
            icon: Icons.emoji_events_rounded,
            severity: AlertSeverity.success,
          ));
        }
      }
    }

    final lastPhotoDate =
        progressPhotos.isEmpty ? null : progressPhotos.first.date;
    final daysSincePhoto =
        lastPhotoDate == null ? null : now.difference(lastPhotoDate).inDays;
    if (daysSincePhoto == null || daysSincePhoto >= 7) {
      items.add(AlertItem(
        id: 'body_scan_reminder',
        title: l10n.alertBodyScanTitle,
        subtitle: l10n.alertBodyScanSubtitle,
        icon: Icons.camera_alt_rounded,
        severity: AlertSeverity.info,
      ));
    }

    for (final item in items) {
      item.read = _readAlertIds.contains(item.id);
    }
    return items;
  }

  // ---- Profile / settings -------------------------------------------------
  bool notificationsEnabled = true;
  bool darkModeLocked = true; // this app is dark-only, shown as a toggle
  bool workoutRemindersEnabled = true;
  bool healthSyncEnabled = false;
  bool publicProfile = false;
  bool shareAnonData = true;

  void togglePublicProfile(bool value) {
    publicProfile = value;
    unawaited(_persistence.savePublicProfile(value));
    notifyListeners();
  }

  void toggleShareAnonData(bool value) {
    shareAnonData = value;
    unawaited(_persistence.saveShareAnonData(value));
    notifyListeners();
  }

  /// Defaults to English regardless of the device's system language — the
  /// app used to fall back to "follow system locale" when unset, which
  /// silently showed Russian/Ukrainian on a matching system even after the
  /// user picked "English" (that previously mapped to `null` instead of an
  /// explicit locale). Overwritten by [hydrate] if a choice was persisted,
  /// and by [setLocale] whenever the user picks one explicitly (in Settings
  /// or on the sign-in screen).
  Locale? locale = const Locale('en');

  void setLocale(Locale? value) {
    locale = value;
    unawaited(_persistence.saveLocaleCode(value?.languageCode));
    notifyListeners();
  }

  /// The locale to render reminder notifications in: the user's explicit
  /// choice if set, otherwise the system locale — clamped to a supported
  /// language, since rendering with an unsupported one would throw.
  static const _supportedLocaleCodes = {'en', 'ru', 'uk'};

  Locale get _effectiveLocale {
    final candidate =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    return _supportedLocaleCodes.contains(candidate.languageCode)
        ? candidate
        : const Locale('en');
  }

  void updateProfile({
    String? username,
    String? goal,
    String? activityLevel,
  }) {
    if (user == null) return;
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
    bodyMeasurements = MockData.emptyBodyMeasurements(gender);
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

  /// Returns whether OS notification permission is actually granted — the
  /// toggle only turns on if it is, mirroring [toggleHealthSync], so the
  /// caller can show a "not granted" message instead of leaving the switch
  /// silently ON with reminders that never fire.
  Future<bool> toggleNotifications(bool value) async {
    final granted = value ? await _syncHydrationReminder(requestFor: true) : true;
    notificationsEnabled = value && granted;
    unawaited(_persistence.saveNotificationsEnabled(notificationsEnabled));
    if (!value) unawaited(_syncHydrationReminder(requestFor: false));
    notifyListeners();
    return granted;
  }

  Future<bool> toggleWorkoutReminders(bool value) async {
    final granted = value ? await _syncWorkoutReminder(requestFor: true) : true;
    workoutRemindersEnabled = value && granted;
    unawaited(_persistence.saveWorkoutRemindersEnabled(workoutRemindersEnabled));
    if (!value) unawaited(_syncWorkoutReminder(requestFor: false));
    notifyListeners();
    return granted;
  }

  /// Local notifications are a nice-to-have, not core app functionality —
  /// any local failure (missing plugin binding in tests, no platform
  /// channel) is swallowed and treated as granted, since it isn't a real
  /// user denial; an actual OS permission denial returns false so the
  /// caller can surface it.
  Future<bool> _syncHydrationReminder({required bool requestFor}) async {
    try {
      if (requestFor) {
        final granted = await NotificationService.instance.requestPermission();
        if (!granted) return false;
        await NotificationService.instance
            .scheduleHydrationReminder(_effectiveLocale);
      } else {
        await NotificationService.instance.cancelHydrationReminder();
      }
      return true;
    } catch (e) {
      debugPrint('Hydration reminder sync failed: $e');
      return true;
    }
  }

  Future<bool> _syncWorkoutReminder({required bool requestFor}) async {
    try {
      if (requestFor) {
        final granted = await NotificationService.instance.requestPermission();
        if (!granted) return false;
        await NotificationService.instance
            .scheduleWorkoutReminder(_effectiveLocale);
      } else {
        await NotificationService.instance.cancelWorkoutReminder();
      }
      return true;
    } catch (e) {
      debugPrint('Workout reminder sync failed: $e');
      return true;
    }
  }

  /// Re-applies the persisted reminder settings on launch — called once
  /// after [hydrate] so a returning user's toggles keep working without
  /// having to flip them again.
  Future<void> syncNotificationSchedules() async {
    await _syncHydrationReminder(requestFor: notificationsEnabled);
    await _syncWorkoutReminder(requestFor: workoutRemindersEnabled);
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

      _pushWidgetOverview();
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
      sleepStagesSynced:
          snapshot.totalSleepMinutes != null || base.sleepStagesSynced,
    );
  }
}
