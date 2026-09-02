import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../domain/models/chat_message_model.dart';
import '../../../../domain/models/sos_alert_model.dart';
import '../../../../domain/models/support_message_model.dart';
import '../../../../domain/models/support_ticket_model.dart';

/// Contract for the Support, Safety & Comms data layer.
///
/// Every URL is a documented backend endpoint (API_Documentation_V2.md §4.14,
/// §6.1, §8.x, §1.4). The API docs pin no response bodies for chat history,
/// SOS, or tickets, so responses are decoded tolerantly by the models.
abstract class SupportRemoteDataSource {
  Future<List<ChatMessageModel>> getTripChatHistory(String tripId);

  Future<SosAlertModel> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  });

  Future<List<SupportTicketModel>> listTickets();

  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  });

  Future<SupportTicketModel> getTicketDetail(int ticketId);

  Future<SupportMessageModel> addTicketMessage(int ticketId, String body);

  Future<SupportTicketModel> closeTicket(int ticketId);

  /// Persists the driver's single trusted emergency contact via
  /// `PATCH /auth/update/` (`emergency_contact`). The backend stores one
  /// contact string; the UI manages one contact rather than inventing a list
  /// endpoint that is not documented.
  Future<void> updateEmergencyContact(String value);
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final Dio dio;

  SupportRemoteDataSourceImpl(this.dio);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data') &&
        responseData['data'] != null) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'] as List<dynamic>? ?? [];
      }
      if (data is List) {
        return data;
      }
      if (responseData.containsKey('results')) {
        return responseData['results'] as List<dynamic>? ?? [];
      }
    }
    if (responseData is List) {
      return responseData;
    }
    return [];
  }

  @override
  Future<List<ChatMessageModel>> getTripChatHistory(String tripId) async {
    final response = await dio.get(ApiEndpoints.tripChatHistory(tripId));
    final rawList = _extractList(response.data);
    return rawList
        .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SosAlertModel> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await dio.post(
      ApiEndpoints.sosRaise,
      data: <String, dynamic>{
        'trip_id': ?tripId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    final dataMap = _extractData(response.data);
    return SosAlertModel.fromJson(dataMap);
  }

  @override
  Future<List<SupportTicketModel>> listTickets() async {
    final response = await dio.get(ApiEndpoints.supportTickets);
    final rawList = _extractList(response.data);
    return rawList
        .map(
          (item) => SupportTicketModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String description,
    int? tripId,
  }) async {
    // [INFERRED] The API docs (8.2) do not pin the request body. The field
    // names below follow the incident-reporting flow in the PRD/UI spec
    // (category + description) and are the backend's own naming from the
    // driver-facing serializer docs, but they are not CONFIRMED.
    final response = await dio.post(
      ApiEndpoints.supportCreateTicket,
      data: <String, dynamic>{
        'category': category,
        'subject': subject,
        'description': description,
        'trip_id': ?tripId,
      },
    );
    final dataMap = _extractData(response.data);
    return SupportTicketModel.fromJson(dataMap);
  }

  @override
  Future<SupportTicketModel> getTicketDetail(int ticketId) async {
    final response = await dio.get(
      ApiEndpoints.supportTicketDetail(ticketId.toString()),
    );
    final dataMap = _extractData(response.data);
    return SupportTicketModel.fromJson(dataMap);
  }

  @override
  Future<SupportMessageModel> addTicketMessage(
    int ticketId,
    String body,
  ) async {
    // [INFERRED] The API docs (8.4) do not pin the request body; `body` is the
    // natural field matching the chat-wire format and ticket serializer.
    final response = await dio.post(
      ApiEndpoints.supportTicketMessages(ticketId.toString()),
      data: <String, dynamic>{'body': body},
    );
    final dataMap = _extractData(response.data);
    return SupportMessageModel.fromJson(dataMap);
  }

  @override
  Future<SupportTicketModel> closeTicket(int ticketId) async {
    final response = await dio.post(
      ApiEndpoints.supportTicketClose(ticketId.toString()),
    );
    final dataMap = _extractData(response.data);
    return SupportTicketModel.fromJson(dataMap);
  }

  @override
  Future<void> updateEmergencyContact(String value) async {
    await dio.patch(
      ApiEndpoints.updateProfile,
      data: <String, dynamic>{'emergency_contact': value},
    );
  }
}
