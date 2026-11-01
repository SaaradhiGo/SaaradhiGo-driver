/// Nothing a log line carries may be a credential.
///
/// THE DEFECT THIS CLOSES
/// ----------------------
/// `LoggingInterceptor` logs request and response bodies with key-based
/// redaction, and the key list was matched EXACTLY. It had `device_token` but
/// not `fcm_token` -- so when the app started PATCHing
/// `{'fcm_token': ...}` to /auth/update/ to register a rotated push token,
/// that body was written to the log in full.
///
/// A device token is a credential: anyone holding one can send a push to that
/// handset. The backend's `base/logging_filters.py` already matches by
/// substring for exactly this reason -- its own comment says exact
/// enumeration "would inevitably miss one (`fcm_token`, `access_token`,
/// `webhook_secret`, ...)" -- so this now mirrors that policy rather than
/// keeping a second, weaker one.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/logging_interceptor.dart';

void main() {
  group('the keys that must never be logged', () {
    test('fcm_token -- the key that was missed', () {
      expect(LoggingInterceptor.isSensitiveKey('fcm_token'), isTrue);
      expect(LoggingInterceptor.isSensitiveKey('FCM_Token'), isTrue);
    });

    test('every token-shaped key, present and future', () {
      for (final key in [
        'token',
        'access_token',
        'refresh_token',
        'device_token',
        'fcm_token',
        'id_token',
        'push_token',
        'session_token',
        'reset_token',
      ]) {
        expect(LoggingInterceptor.isSensitiveKey(key), isTrue,
            reason: '"$key" would be written to the log');
      }
    });

    test('credentials and secrets', () {
      for (final key in [
        'password',
        'passwd',
        'authorization',
        'otp',
        'client_secret',
        'webhook_secret',
        'api_key',
        'apiKey',
        'jwt',
        'signature',
        'credential',
        'cvv',
      ]) {
        expect(LoggingInterceptor.isSensitiveKey(key), isTrue,
            reason: '"$key" would be written to the log');
      }
    });

    test('a presigned upload URL, which is a write capability', () {
      // Anyone holding one can upload or overwrite the object until it
      // expires, which for KYC documents means replacing somebody's licence.
      expect(LoggingInterceptor.isSensitiveKey('upload_url'), isTrue);
    });
  });

  group('what must still be loggable', () {
    test('ordinary fields are not redacted', () {
      // Over-redaction is not free: it looks like privacy while destroying
      // the diagnostics the log exists for.
      for (final key in [
        'trip_id',
        'status',
        'pickup_address',
        'distance_km',
        'estimated_fare',
        'vehicle_type',
        'rating_id',
        'score',
        'issue_type',
      ]) {
        expect(LoggingInterceptor.isSensitiveKey(key), isFalse,
            reason: '"$key" carries no credential and a fare audit needs it');
      }
    });

    test('a rate card identifier is not mistaken for a payment card', () {
      // The backend records this trap explicitly: a bare `card` substring
      // also swallowed `rate_card_id` and `rate_card_version`, which are
      // pricing-schedule identifiers and exactly the provenance a fare
      // dispute needs.
      expect(LoggingInterceptor.isSensitiveKey('rate_card_id'), isFalse);
      expect(LoggingInterceptor.isSensitiveKey('rate_card_version'), isFalse);
    });
  });

  group('query parameters in a URL', () {
    test('a token in a query string is redacted', () {
      // The trip and chat sockets carry `?token=` in their URL.
      final sanitized = LoggingInterceptor.sanitizeUri(
        Uri.parse('wss://api.example/ws/ride/trip/1/?token=real-jwt-value'),
      );

      expect(sanitized, isNot(contains('real-jwt-value')));
      // Uri.replace percent-encodes the marker, so the log shows
      // %5BREDACTED%5D. What matters is that the value is gone.
      expect(sanitized.toUpperCase(), contains('REDACTED'));
    });

    test('a harmless query parameter survives', () {
      final sanitized = LoggingInterceptor.sanitizeUri(
        Uri.parse('https://api.example/ride/driver-history/?page=3'),
      );

      expect(sanitized, contains('page=3'));
    });

    test('a URL with no query string is returned unchanged', () {
      const url = 'https://api.example/driver/driver/profile/';

      expect(LoggingInterceptor.sanitizeUri(Uri.parse(url)), url);
    });
  });
}
