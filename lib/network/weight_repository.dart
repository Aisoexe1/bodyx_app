import '../models/models.dart';
import 'api_client.dart';

abstract class WeightRepository {
  Future<List<WeightEntry>> list();
  Future<void> add(double kg, double bodyFatPct);
}

class ApiWeightRepository implements WeightRepository {
  ApiWeightRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<WeightEntry>> list() async {
    final json = await _client.get('/weight') as List;
    return json
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> add(double kg, double bodyFatPct) async {
    await _client.post('/weight', {'kg': kg, 'bodyFatPct': bodyFatPct});
  }
}
