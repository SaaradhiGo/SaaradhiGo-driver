import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/jwt_expiry.dart';

/// THE DEFECT THIS EXISTS FOR
///
/// The driver app left open past its access-token lifetime could not go
/// online again. Going online opens `ws/driver/location/` with the token in
/// the query string -- a path that never touches Dio, so `AuthInterceptor`'s
/// 401-driven refresh could not see it. The server refused the upgrade, the
/// client saw only `WebSocketChannelException`, it retried six times, logged
/// "Max reconnect attempts reached" and settled on "You're Offline" with no
/// explanation. A freshly minted token for the same account connected on the
/// first attempt, which is what proved it was the token and not the server.
///
/// There is no status code to react to, so expiry has to be read from the
/// token before connecting.

String _jwt(Map<String, dynamic> claims) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(claims)}.sig';
}

void main() {
  final now = DateTime.utc(2026, 10, 19, 12, 0, 0);

  group('jwtExpiry', () {
    test('reads exp as a UTC instant', () {
      final token = _jwt({'exp': now.millisecondsSinceEpoch ~/ 1000});
      expect(jwtExpiry(token), now);
    });

    test('is null for anything that is not a three-part JWT', () {
      for (final junk in ['', 'abc', 'a.b', 'a.b.c.d']) {
        expect(jwtExpiry(junk), isNull, reason: junk);
      }
    });

    test('is null when the payload is not decodable', () {
      expect(jwtExpiry('header.!!!not-base64!!!.sig'), isNull);
    });

    test('is null when there is no exp claim', () {
      expect(jwtExpiry(_jwt({'user_id': '8'})), isNull);
    });

    test('is null when exp is not an integer', () {
      expect(jwtExpiry(_jwt({'exp': 'soon'})), isNull);
    });
  });

  group('isJwtExpired', () {
    test('a token that has already lapsed is expired', () {
      final token = _jwt({
        'exp': now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      expect(isJwtExpired(token, now: now), isTrue);
    });

    test('a comfortably valid token is not expired', () {
      final token = _jwt({
        'exp': now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
      });
      expect(isJwtExpired(token, now: now), isFalse);
    });

    test('a token expiring inside the margin counts as expired', () {
      // The alternative is a driver going offline for a round trip and a
      // backoff cycle because the token lapsed mid-handshake.
      final token = _jwt({
        'exp': now.add(const Duration(seconds: 5)).millisecondsSinceEpoch ~/ 1000,
      });
      expect(isJwtExpired(token, now: now), isTrue);
    });

    test('expiry exactly at the margin boundary counts as expired', () {
      final token = _jwt({
        'exp': now.add(const Duration(seconds: 30)).millisecondsSinceEpoch ~/ 1000,
      });
      expect(isJwtExpired(token, now: now), isTrue);
    });

    test('an unreadable token is used as-is rather than refused', () {
      // Refusing to connect over a token we cannot parse would be worse than
      // letting the server be the judge of it.
      expect(isJwtExpired('not-a-jwt', now: now), isFalse);
      expect(isJwtExpired(_jwt({'user_id': '8'}), now: now), isFalse);
    });
  });
}
