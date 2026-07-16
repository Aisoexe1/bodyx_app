import '../models/models.dart';
import 'api_client.dart';

abstract class MeasurementRepository {
  Future<Map<MuscleZone, BodyMeasurement>> getAll();
  Future<void> replaceAll(Map<MuscleZone, BodyMeasurement> measurements);
  Future<void> updateZone(MuscleZone zone, double valueCm);
}

class ApiMeasurementRepository implements MeasurementRepository {
  ApiMeasurementRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<Map<MuscleZone, BodyMeasurement>> getAll() async {
    final json = await _client.get('/measurements') as Map<String, dynamic>;
    return _parse(json);
  }

  @override
  Future<void> replaceAll(Map<MuscleZone, BodyMeasurement> measurements) async {
    final body = measurements.map((zone, m) {
      final json = m.toJson()..remove('zone');
      return MapEntry(zone.name, json);
    });
    await _client.put('/measurements', body);
  }

  @override
  Future<void> updateZone(MuscleZone zone, double valueCm) async {
    await _client.patch('/measurements/${zone.name}', {'valueCm': valueCm});
  }

  Map<MuscleZone, BodyMeasurement> _parse(Map<String, dynamic> json) {
    return json.map((zoneName, value) => MapEntry(
          MuscleZone.values.byName(zoneName),
          BodyMeasurement.fromJson({
            ...value as Map<String, dynamic>,
            'zone': zoneName,
          }),
        ));
  }
}
