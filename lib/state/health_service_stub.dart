import 'health_types.dart';

/// No-op fallback used wherever `dart:io` isn't available (web). Mirrors
/// [HealthService]'s mobile API so callers never need platform checks —
/// see [health_service.dart] for the conditional export that picks this.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  Future<bool> requestPermissions() async => false;
  Future<bool> hasPermissions() async => false;
  Future<HealthDailySnapshot?> fetchDailySnapshot(DateTime day) async => null;
  Future<List<HealthWeightSample>> fetchWeightHistory({int days = 90}) async =>
      const [];
}
