import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsOnboardingComplete = 'is_onboarding_complete';
  static const _keyActiveTripId = 'active_trip_id';

  static Future<void> setOnboardingComplete(bool complete) async {
    await _prefs?.setBool(_keyIsOnboardingComplete, complete);
  }

  static bool isOnboardingComplete() {
    return _prefs?.getBool(_keyIsOnboardingComplete) ?? false;
  }

  static Future<void> setActiveTripId(String tripId) async {
    await _prefs?.setString(_keyActiveTripId, tripId);
  }

  static Future<void> clearActiveTripId() async {
    await _prefs?.remove(_keyActiveTripId);
  }

  static String? getActiveTripId() {
    return _prefs?.getString(_keyActiveTripId);
  }

  /// Device choices that outlive a session (owner brief: the driver's
  /// appearance choice survives logout). Never removed by [clearAll].
  static const keptAcrossSessions = {'driver_appearance_mode_v1'};

  /// Clears this install's session data, keeping [keptAcrossSessions].
  static Future<void> clearAll() async {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final key in prefs.getKeys().toList()) {
      if (!keptAcrossSessions.contains(key)) await prefs.remove(key);
    }
  }
}
