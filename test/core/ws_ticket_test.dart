/// 16 Nov ruling: the driver's sockets never carry the token in the address.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saaradhigo_driver/core/network/ws_ticket.dart';

void main() {
  final url = Uri.parse(
    'wss://qa.example/ws/driver/location/?token=secret-jwt&lat=43.6&lng=-116.2',
  );

  test('the token is swapped for a single-use ticket', () async {
    final asked = <http.Request>[];
    final uri = await ticketedWsUri(
      url,
      client: MockClient((req) async {
        asked.add(req);
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {'ticket': 'tk-9', 'expires_in': 30},
          }),
          201,
        );
      }),
    );
    expect(uri.queryParameters, {
      'lat': '43.6',
      'lng': '-116.2',
      'ticket': 'tk-9',
    });
    expect(uri.toString(), isNot(contains('secret-jwt')));
    expect(asked.single.url.path, endsWith('/auth/ws-ticket/'));
    expect(asked.single.headers['Authorization'], 'Bearer secret-jwt');
  });

  test('no ticket: still no token in the address', () async {
    final uri = await ticketedWsUri(
      url,
      client: MockClient((_) async => http.Response('down', 503)),
    );
    expect(uri.queryParameters.containsKey('token'), isFalse);
  });
}
