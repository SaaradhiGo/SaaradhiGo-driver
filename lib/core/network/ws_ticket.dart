/// 16 Nov ruling: a socket never carries the sign-in token in its address.
/// Each connect trades it for a single-use ticket that expires after 30 s.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_endpoints.dart';

/// A fresh ticket for [token] from `POST /auth/ws-ticket/`, or null.
Future<String?> fetchWsTicket(String token, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final base = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final r = await c
        .post(
          Uri.parse('$base/auth/ws-ticket/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200 && r.statusCode != 201) return null;
    final body = jsonDecode(r.body);
    final data = body is Map ? body['data'] : null;
    final ticket = data is Map ? data['ticket']?.toString() : null;
    return (ticket == null || ticket.isEmpty) ? null : ticket;
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// [uri] with its `token` removed and a ticket in its place. Without a ticket
/// the address carries no credential; the server refuses it and the socket's
/// reconnect tries again with a fresh token.
Future<Uri> ticketedWsUri(Uri uri, {http.Client? client}) async {
  final params = Map<String, String>.from(uri.queryParameters);
  final token = params.remove('token');
  if (token == null) return uri;
  if (token.isNotEmpty) {
    final ticket = await fetchWsTicket(token, client: client);
    if (ticket != null) params['ticket'] = ticket;
  }
  final base = uri.toString().split('?').first;
  return Uri.parse(
    params.isEmpty ? base : '$base?${Uri(queryParameters: params).query}',
  );
}
