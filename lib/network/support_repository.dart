import '../models/models.dart';
import 'api_client.dart';

abstract class SupportRepository {
  Future<List<SupportTicket>> listTickets();
  Future<SupportTicket> getTicket(String ticketId);
  Future<SupportTicket> createTicket(String subject, String message);
  Future<SupportTicket> addMessage(String ticketId, String text);
}

class ApiSupportRepository implements SupportRepository {
  ApiSupportRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<SupportTicket>> listTickets() async {
    final json = await _client.get('/support/tickets') as List;
    return json
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SupportTicket> getTicket(String ticketId) async {
    final json = await _client.get('/support/tickets/$ticketId');
    return SupportTicket.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SupportTicket> createTicket(String subject, String message) async {
    final json = await _client
        .post('/support/tickets', {'subject': subject, 'message': message});
    return SupportTicket.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SupportTicket> addMessage(String ticketId, String text) async {
    final json = await _client
        .post('/support/tickets/$ticketId/messages', {'text': text});
    return SupportTicket.fromJson(json as Map<String, dynamic>);
  }
}
