import 'dart:io';

import 'package:bodyx_app/models/models.dart';
import 'package:bodyx_app/network/auth_repository.dart';
import 'package:bodyx_app/network/measurement_repository.dart';
import 'package:bodyx_app/network/profile_repository.dart';
import 'package:bodyx_app/network/weight_repository.dart';
import 'package:bodyx_app/state/app_state.dart';
import 'package:bodyx_app/state/persistence_service.dart';

/// In-memory stand-ins for the network layer — unit tests must never touch
/// real HTTP or platform-channel secure storage. These replicate just
/// enough of a real backend's behavior (deriving a username from an email
/// on login, echoing back what was registered) for the existing auth-flow
/// assertions to hold unchanged.
class FakeAuthRepository implements AuthRepository {
  UserProfile? restoredSession;

  /// Set to a non-null value to make [forgotPassword] return it (simulating
  /// dev-mode); set [forgotPasswordThrows] to make it throw instead.
  String? nextForgotPasswordCode = '123456';
  Object? forgotPasswordThrows;

  /// Set to make [resetPassword] throw (e.g. simulate a wrong/expired code).
  Object? resetPasswordThrows;
  String? lastResetCode;
  String? lastResetPassword;

  @override
  Future<UserProfile> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final resolvedUsername = username.trim().isEmpty ? 'newuser' : username.trim();
    return UserProfile(
      email: email,
      username: resolvedUsername,
      name: resolvedUsername.isEmpty ? 'Athlete' : resolvedUsername,
    );
  }

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    final derived = email.split('@').first.isEmpty ? 'alex' : email.split('@').first;
    return UserProfile(email: email, username: derived);
  }

  @override
  Future<String?> forgotPassword(String email) async {
    if (forgotPasswordThrows != null) throw forgotPasswordThrows!;
    return nextForgotPasswordCode;
  }

  @override
  Future<UserProfile> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    lastResetCode = code;
    lastResetPassword = newPassword;
    if (resetPasswordThrows != null) throw resetPasswordThrows!;
    final derived = email.split('@').first.isEmpty ? 'alex' : email.split('@').first;
    return UserProfile(email: email, username: derived);
  }

  Object? googleLoginThrows;
  Object? appleLoginThrows;

  @override
  Future<UserProfile> loginWithGoogle(String idToken) async {
    if (googleLoginThrows != null) throw googleLoginThrows!;
    return UserProfile(email: 'google-user@bodyx.app', username: 'googleuser');
  }

  @override
  Future<UserProfile> loginWithApple(String identityToken) async {
    if (appleLoginThrows != null) throw appleLoginThrows!;
    return UserProfile(email: 'apple-user@bodyx.app', username: 'appleuser');
  }

  @override
  Future<UserProfile?> restoreSession() async => restoredSession;

  @override
  Future<void> signOut() async {}
}

/// Simulates a completely unreachable backend (no server deployed, offline,
/// timeout) — every call throws a plain connectivity-style error, as
/// opposed to [ApiException] which represents a server that *did* respond,
/// just with a rejection.
class UnreachableAuthRepository implements AuthRepository {
  @override
  Future<UserProfile> register({
    required String email,
    required String username,
    required String password,
  }) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile> login({required String email, required String password}) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<String?> forgotPassword(String email) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile> loginWithGoogle(String idToken) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile> loginWithApple(String identityToken) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<void> updateMe(Map<String, dynamic> updates) async {}
}

class FakeWeightRepository implements WeightRepository {
  List<WeightEntry> remote = [];

  @override
  Future<List<WeightEntry>> list() async => remote;

  @override
  Future<void> add(double kg, double bodyFatPct) async {}
}

class FakeMeasurementRepository implements MeasurementRepository {
  Map<MuscleZone, BodyMeasurement> remote = {};

  @override
  Future<Map<MuscleZone, BodyMeasurement>> getAll() async => remote;

  @override
  Future<void> replaceAll(Map<MuscleZone, BodyMeasurement> measurements) async {}

  @override
  Future<void> updateZone(MuscleZone zone, double valueCm) async {}
}

/// Builds an [AppState] wired to fakes for every network dependency, so
/// tests exercise the same code paths as production without touching HTTP
/// or the keychain. [persistence] is left real (backed by the
/// `shared_preferences` mock set up in `setUp`) since that's what these
/// tests are actually verifying round-trips against.
AppState newTestAppState({
  PersistenceService? persistence,
  AuthRepository? authRepository,
}) =>
    AppState(
      persistence: persistence,
      authRepository: authRepository ?? FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      weightRepository: FakeWeightRepository(),
      measurementRepository: FakeMeasurementRepository(),
    );
