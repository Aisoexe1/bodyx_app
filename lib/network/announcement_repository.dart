import '../models/models.dart';
import 'api_client.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> listActive();
}

class ApiAnnouncementRepository implements AnnouncementRepository {
  ApiAnnouncementRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<Announcement>> listActive() async {
    final json = await _client.get('/announcements/active') as List;
    return json
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
