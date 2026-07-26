import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret local state: settings, and the last-known trip snapshot used for
/// crash-safe recovery.
///
/// The snapshot exists so a driver whose app was killed mid-trip sees the trip
/// again instantly on relaunch instead of a blank home screen. It is a cache,
/// never the truth — on start the app reconciles it against `GET /ride/active/`
/// and the server always wins.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async =>
      LocalStore(await SharedPreferences.getInstance());

  static const _kTripSnapshot = 'active_trip_snapshot';
  static const _kOnDuty = 'was_on_duty';
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kPushEnabled = 'push_enabled';

  Map<String, dynamic>? readTripSnapshot() {
    final raw = _prefs.getString(_kTripSnapshot);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeTripSnapshot(Map<String, dynamic>? snapshot) async {
    if (snapshot == null) {
      await _prefs.remove(_kTripSnapshot);
      return;
    }
    await _prefs.setString(_kTripSnapshot, jsonEncode(snapshot));
  }

  /// Whether the driver was on duty when the app last stopped. Used to
  /// re-establish the duty socket after a crash or an OEM task-kill without
  /// the driver having to notice they went offline.
  bool get wasOnDuty => _prefs.getBool(_kOnDuty) ?? false;
  Future<void> setWasOnDuty(bool value) => _prefs.setBool(_kOnDuty, value);

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_kThemeMode, value);

  String get locale => _prefs.getString(_kLocale) ?? 'en';
  Future<void> setLocale(String value) => _prefs.setString(_kLocale, value);

  bool get pushEnabled => _prefs.getBool(_kPushEnabled) ?? true;
  Future<void> setPushEnabled(bool value) =>
      _prefs.setBool(_kPushEnabled, value);

  Future<void> clearSessionState() async {
    await _prefs.remove(_kTripSnapshot);
    await _prefs.remove(_kOnDuty);
  }
}
