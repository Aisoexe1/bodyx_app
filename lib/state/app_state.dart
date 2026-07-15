import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

enum AuthStage { splash, signIn, signUp, chooseUsername, bodyData, done }

/// Single source of truth for the whole prototype. Everything the UI reads
/// (auth flow, dashboard numbers, body measurements, plan, alerts) lives
/// here so every screen updates reactively when mock data changes.
class AppState extends ChangeNotifier {
  AppState() {
    dailyStats = MockData.generateDailyStats();
    weightHistory = MockData.generateWeightHistory();
    bodyMeasurements = MockData.generateBodyMeasurements(Gender.male);
    alerts = MockData.alerts;
    planTasks = MockData.todayPlan;
    meals = MockData.todayMeals;
  }

  // ---- Auth / onboarding -------------------------------------------------
  AuthStage authStage = AuthStage.splash;
  String? _pendingEmail;
  UserProfile? user;

  void finishSplash() {
    authStage = AuthStage.signIn;
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
    authStage = AuthStage.done;
    notifyListeners();
  }

  void signOut() {
    user = null;
    _pendingEmail = null;
    navIndex = 0;
    authStage = AuthStage.signIn;
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
    notifyListeners();
  }

  void logWeight(double kg, double bodyFatPct) {
    weightHistory = [
      ...weightHistory,
      WeightEntry(DateTime.now(), kg, bodyFatPct),
    ];
    if (user != null) user!.weightKg = kg;
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
    notifyListeners();
  }

  // ---- Alerts -----------------------------------------------------------
  late List<AlertItem> alerts;

  int get unreadAlertCount => alerts.where((a) => !a.read).length;

  void markAlertRead(int index) {
    alerts[index].read = true;
    notifyListeners();
  }

  void markAllAlertsRead() {
    for (final a in alerts) {
      a.read = true;
    }
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
    notifyListeners();
  }

  void updateGender(Gender gender) {
    if (user == null) return;
    user!.gender = gender;
    bodyViewerGender = gender;
    bodyMeasurements = MockData.generateBodyMeasurements(gender);
    notifyListeners();
  }

  void updateHeightWeightAge({double? heightCm, double? weightKg, int? age}) {
    if (user == null) return;
    if (heightCm != null) user!.heightCm = heightCm;
    if (weightKg != null) user!.weightKg = weightKg;
    if (age != null) user!.age = age;
    notifyListeners();
  }

  void toggleUnits() {
    if (user == null) return;
    user!.unitsMetric = !user!.unitsMetric;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void toggleWorkoutReminders(bool value) {
    workoutRemindersEnabled = value;
    notifyListeners();
  }
}
