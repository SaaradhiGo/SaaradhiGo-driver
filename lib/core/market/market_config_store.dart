/// Fetches, caches and serves the [MarketConfig].
///
/// Order of preference, always: FRESH response -> CACHED last good response ->
/// BUILT-IN defaults (today's India behaviour). A failed fetch (offline,
/// timeout, 5xx, 404 for an unknown country, garbage body) never throws, never
/// blocks start-up, and never replaces something better with something worse.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_endpoints.dart';
import 'app_headers_interceptor.dart';
import 'market_config.dart';

class MarketConfigStore extends ChangeNotifier {
  MarketConfigStore({
    Dio? dio,
    this.timeout = const Duration(seconds: 6),
    this.appName = 'driver',
  }) : _dio = dio;

  /// The app-wide instance. Non-widget code reads [current] from here; widgets
  /// reach it through [marketConfigProvider] so they rebuild when it changes.
  static final MarketConfigStore instance = MarketConfigStore();

  static const cacheKey = 'market_config_cache_v1';
  static const countryKey = 'market_config_country_v1';

  Dio? _dio;
  final Duration timeout;
  final String appName;

  MarketConfig _current = MarketConfig.builtIn;
  String? _lastCountry;

  MarketConfig get current => _current;

  /// Which layer the current value came from, for tests and diagnostics.
  String source = 'built-in';

  Dio get _client => _dio ??= Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      // 404 (unknown country) is an answer, not an exception.
      validateStatus: (_) => true,
    ),
  )..interceptors.add(AppHeadersInterceptor());

  /// Loads the cached response (cheap, local). Call before the first frame.
  Future<void> restoreCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastCountry = prefs.getString(countryKey);
      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _current = MarketConfig.fromData(Map<String, dynamic>.from(decoded));
        source = 'cached';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MarketConfig: cache unreadable ($e); using built-in');
    }
  }

  /// Fetches the document and, if it is good, adopts and caches it.
  /// [country] defaults to the last known country, then to IN as the very
  /// last fallback. Returns the config now in force. Never throws.
  Future<MarketConfig> refresh({String? country}) async {
    final code = (country ?? _lastCountry ?? MarketConfig.builtIn.countryCode)
        .toUpperCase();
    try {
      final response = await _client
          .get<dynamic>(
            '/app-config/',
            queryParameters: {'country': code, 'app': appName},
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        // 404 = unknown country: never a crash, never a guess. Keep what we have.
        debugPrint(
          'MarketConfig: HTTP ${response.statusCode}; keeping $source',
        );
        return _current;
      }
      final body = _asMap(response.data);
      final data = body?['data'];
      if (data is! Map || data['country'] is! Map) return _current;
      final map = Map<String, dynamic>.from(data);
      _current = MarketConfig.fromData(map);
      source = 'fresh';
      _lastCountry = _current.countryCode;
      await _persist(map);
      notifyListeners();
    } on Object catch (e) {
      debugPrint(
        'MarketConfig: fetch failed (${e.runtimeType}); keeping $source',
      );
    }
    return _current;
  }

  /// After sign-in: use the country of the signed-in user's phone number.
  /// Same dialling code as the config in force -> refresh that country;
  /// otherwise ask the backend which live country owns that code.
  Future<MarketConfig> refreshForPhone(String? e164) async {
    final digits = (e164 ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty || digits.startsWith(_current.callingCode)) {
      return refresh();
    }
    try {
      final response = await _client.get<dynamic>('/app-config/').timeout(
        timeout,
      );
      if (response.statusCode == 200) {
        final body = _asMap(response.data);
        final countries = body?['data'] is Map
            ? (body!['data'] as Map)['countries']
            : null;
        if (countries is List) {
          for (final c in countries) {
            if (c is Map) {
              final cc = (c['calling_code'] ?? '').toString();
              if (cc.isNotEmpty && digits.startsWith(cc)) {
                return await refresh(country: c['code']?.toString());
              }
            }
          }
        }
      }
    } on Object catch (e) {
      debugPrint('MarketConfig: country lookup failed (${e.runtimeType})');
    }
    return refresh();
  }

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final d = jsonDecode(data);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setString(countryKey, _current.countryCode);
    } catch (e) {
      debugPrint('MarketConfig: could not cache ($e)');
    }
  }

  /// Test seam.
  @visibleForTesting
  void debugSet(MarketConfig config, {String from = 'fresh'}) {
    _current = config;
    source = from;
    notifyListeners();
  }
}
