import 'api_client.dart';

/// Best-effort profile sync to the server. Callers (`AppState`) fire these
/// unawaited and swallow errors — local persistence is always the source of
/// truth for MVP; this just keeps the server copy roughly in sync.
abstract class ProfileRepository {
  Future<void> updateMe(Map<String, dynamic> updates);
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<void> updateMe(Map<String, dynamic> updates) async {
    await _client.patch('/users/me', updates);
  }
}
