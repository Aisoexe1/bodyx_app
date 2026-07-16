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
  Future<UserProfile?> restoreSession() async => restoredSession;

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
AppState newTestAppState({PersistenceService? persistence}) => AppState(
      persistence: persistence,
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      weightRepository: FakeWeightRepository(),
      measurementRepository: FakeMeasurementRepository(),
    );
