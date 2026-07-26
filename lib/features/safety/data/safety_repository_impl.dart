import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/safety_repository.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<int> raiseSos({
    required String eventType,
    int? tripId,
    double? lat,
    double? lng,
    double? accuracyM,
    String? note,
  }) async {
    final data = await _api.post(
      ApiEndpoints.sos,
      body: {
        'event_type': eventType,
        'initiated_by': 'driver',
        'trip_id': ?tripId,
        'lat': ?lat,
        'lng': ?lng,
        'accuracy_m': ?accuracyM,
        'note': ?note,
      },
    );
    return (data['sos_id'] as num?)?.toInt() ?? (data['id'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<SupportTicket>> fetchTickets() async {
    final list = await _api.getList(ApiEndpoints.supportTickets);
    return list
        .whereType<Map<String, dynamic>>()
        .map(SupportTicket.fromJson)
        .toList(growable: false);
  }

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    String? category,
    int? tripId,
  }) async {
    final data = await _api.post(
      ApiEndpoints.supportCreateTicket,
      body: {
        'subject': subject,
        'body': body,
        'category': ?category,
        'trip_id': ?tripId,
      },
    );
    return SupportTicket.fromJson(data);
  }

  @override
  Future<SupportTicket> fetchTicket(int id) async {
    final data = await _api.get(ApiEndpoints.supportTicket(id));
    return SupportTicket.fromJson(data);
  }

  @override
  Future<void> addMessage({required int ticketId, required String body}) async {
    await _api.post(
      ApiEndpoints.supportTicketMessages(ticketId),
      body: {'body': body},
    );
  }
}
