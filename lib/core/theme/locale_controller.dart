/// The app language: English, Telugu or Hindi. Persisted on the device;
/// English until the driver picks another in Profile.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  static const prefsKey = 'driver_locale_v1';
  static const supported = [Locale('en'), Locale('te'), Locale('hi')];

  static Locale _restored = const Locale('en');

  /// Load the persisted language before the first frame. Never throws.
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _restored = _parse(prefs.getString(prefsKey));
    } catch (_) {
      _restored = const Locale('en');
    }
  }

  static Locale _parse(String? code) => supported.firstWhere(
    (l) => l.languageCode == code,
    orElse: () => const Locale('en'),
  );

  @override
  Locale build() => _restored;

  Future<void> setLocale(Locale locale) async {
    final next = _parse(locale.languageCode);
    _restored = next;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, next.languageCode);
    } catch (_) {
      // Holds for this session.
    }
  }
}
