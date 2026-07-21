import 'dart:io';

import 'package:bodyx_app/models/models.dart';
import 'package:bodyx_app/network/announcement_repository.dart';
import 'package:bodyx_app/network/auth_repository.dart';
import 'package:bodyx_app/network/measurement_repository.dart';
import 'package:bodyx_app/network/profile_repository.dart';
import 'package:bodyx_app/network/support_repository.dart';
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
    );
  }

  /// The server's pet XP to hand back on the next [login] — simulates a
  /// value another device already synced, for testing AppState's
  /// higher-wins reconciliation.
  int nextLoginPetXp = 0;

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    final derived = email.split('@').first.isEmpty ? 'alex' : email.split('@').first;
    return UserProfile(email: email, username: derived, petXp: nextLoginPetXp);
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

  /// When true, [loginWithGoogle]/[loginWithApple] simulate a brand-new
  /// email (no existing account) by throwing [OAuthNeedsUsername] instead
  /// of returning a profile directly — matching what the real backend does
  /// for a first-time sign-in.
  bool googleNeedsUsername = false;
  bool appleNeedsUsername = false;

  @override
  Future<UserProfile> loginWithGoogle(String idToken) async {
    if (googleLoginThrows != null) throw googleLoginThrows!;
    if (googleNeedsUsername) {
      throw OAuthNeedsUsername(email: 'google-user@bodyx.app', token: idToken);
    }
    return UserProfile(email: 'google-user@bodyx.app', username: 'googleuser');
  }

  @override
  Future<UserProfile> completeGoogleSignUp(String idToken, String username) async =>
      UserProfile(email: 'google-user@bodyx.app', username: username);

  @override
  Future<UserProfile> loginWithApple(String identityToken) async {
    if (appleLoginThrows != null) throw appleLoginThrows!;
    if (appleNeedsUsername) {
      throw OAuthNeedsUsername(email: 'apple-user@bodyx.app', token: identityToken);
    }
    return UserProfile(email: 'apple-user@bodyx.app', username: 'appleuser');
  }

  @override
  Future<UserProfile> completeAppleSignUp(String identityToken, String username) async =>
      UserProfile(email: 'apple-user@bodyx.app', username: username);

  @override
  Future<UserProfile?> restoreSession() async => restoredSession;

  @override
  Future<void> signOut() async {}

  bool deleteAccountCalled = false;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
  }
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
  Future<UserProfile> completeGoogleSignUp(String idToken, String username) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile> loginWithApple(String identityToken) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile> completeAppleSignUp(String identityToken, String username) =>
      throw const SocketException('Network is unreachable');

  @override
  Future<UserProfile?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() =>
      throw const SocketException('Network is unreachable');
}

class FakeProfileRepository implements ProfileRepository {
  /// Every `updates` map passed to [updateMe], in call order — lets tests
  /// assert what AppState actually pushed to the server (e.g. petXp sync).
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<void> updateMe(Map<String, dynamic> updates) async {
    updateCalls.add(updates);
  }
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

class FakeSupportRepository implements SupportRepository {
  List<SupportTicket> tickets = [];
  Object? createThrows;
  Object? addMessageThrows;
  int _nextId = 1;

  @override
  Future<List<SupportTicket>> listTickets() async => tickets;

  @override
  Future<SupportTicket> getTicket(String ticketId) async =>
      tickets.firstWhere((t) => t.id == ticketId);

  @override
  Future<SupportTicket> createTicket(String subject, String message) async {
    if (createThrows != null) throw createThrows!;
    final now = DateTime.now();
    final ticket = SupportTicket(
      id: 'ticket-${_nextId++}',
      subject: subject,
      status: TicketStatus.open,
      messages: [
        TicketMessage(
            sender: TicketMessageSender.user, text: message, createdAt: now),
      ],
      createdAt: now,
      updatedAt: now,
    );
    tickets = [ticket, ...tickets];
    return ticket;
  }

  @override
  Future<SupportTicket> addMessage(String ticketId, String text) async {
    if (addMessageThrows != null) throw addMessageThrows!;
    final existing = tickets.firstWhere((t) => t.id == ticketId);
    final updated = SupportTicket(
      id: existing.id,
      subject: existing.subject,
      status: TicketStatus.open,
      messages: [
        ...existing.messages,
        TicketMessage(
            sender: TicketMessageSender.user,
            text: text,
            createdAt: DateTime.now()),
      ],
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    tickets = tickets.map((t) => t.id == ticketId ? updated : t).toList();
    return updated;
  }
}

class FakeAnnouncementRepository implements AnnouncementRepository {
  List<Announcement> active = [];
  Object? listActiveThrows;

  @override
  Future<List<Announcement>> listActive() async {
    if (listActiveThrows != null) throw listActiveThrows!;
    return active;
  }
}

/// Builds an [AppState] wired to fakes for every network dependency, so
/// tests exercise the same code paths as production without touching HTTP
/// or the keychain. [persistence] is left real (backed by the
/// `shared_preferences` mock set up in `setUp`) since that's what these
/// tests are actually verifying round-trips against.
AppState newTestAppState({
  PersistenceService? persistence,
  AuthRepository? authRepository,
  ProfileRepository? profileRepository,
  AnnouncementRepository? announcementRepository,
}) =>
    AppState(
      persistence: persistence,
      authRepository: authRepository ?? FakeAuthRepository(),
      profileRepository: profileRepository ?? FakeProfileRepository(),
      weightRepository: FakeWeightRepository(),
      measurementRepository: FakeMeasurementRepository(),
      supportRepository: FakeSupportRepository(),
      announcementRepository: announcementRepository ?? FakeAnnouncementRepository(),
    );
