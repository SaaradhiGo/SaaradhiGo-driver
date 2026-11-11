/// Light or dark, and who decides.
///
/// Automatic (the default): light between local sunrise and sunset, dark from
/// sunset to sunrise. The sun times are computed on the device (sun_times.dart)
/// from the clock and the last GPS fix the app already has; with no fix, the
/// first market city's centre from app-config; with neither, 06:00-18:00 on
/// the device clock. Re-checked every five minutes, on every resume and on
/// each new fix. This adds no permission prompt and never starts location: it
/// only reads what the location stack already produced.
///
/// The driver can force Dark or Light in Profile. The choice is persisted.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/sg_tokens.dart';
import '../location/location_providers.dart';
import '../market/market_config_store.dart';
import 'sun_times.dart';

enum AppearanceMode { automatic, dark, light }

@immutable
class AppearanceState {
  const AppearanceState(this.mode, this.brightness);

  final AppearanceMode mode;

  /// What is on screen now.
  final Brightness brightness;

  SgPalette get palette =>
      brightness == Brightness.dark ? SgPalette.dark : SgPalette.light;

  @override
  bool operator ==(Object other) =>
      other is AppearanceState &&
      other.mode == mode &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(mode, brightness);
}

final appearanceControllerProvider =
    NotifierProvider<AppearanceController, AppearanceState>(
      AppearanceController.new,
    );

class AppearanceController extends Notifier<AppearanceState> {
  static const prefsKey = 'driver_appearance_mode_v1';
  static const recheckEvery = Duration(minutes: 5);

  /// Read before the first frame by [restore], so the app opens in the right
  /// theme without a flash.
  static AppearanceMode _restored = AppearanceMode.automatic;

  /// The clock. Tests replace it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Load the persisted mode. Never throws.
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _restored = _parse(prefs.getString(prefsKey));
    } catch (_) {
      _restored = AppearanceMode.automatic;
    }
  }

  static AppearanceMode _parse(String? raw) => AppearanceMode.values.firstWhere(
    (m) => m.name == raw,
    orElse: () => AppearanceMode.automatic,
  );

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  LatLng? _lastFix;

  @override
  AppearanceState build() {
    _timer = Timer.periodic(recheckEvery, (_) => _recheck());
    _lifecycle = AppLifecycleListener(onResume: _recheck);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    ref.listen<LatLng?>(driverPositionProvider, (_, next) {
      if (next != null) {
        _lastFix = next;
        _recheck();
      }
    });
    _lastFix = ref.read(driverPositionProvider);
    return AppearanceState(_restored, _resolve(_restored));
  }

  /// Force a mode, or go back to automatic. Persisted.
  Future<void> setMode(AppearanceMode mode) async {
    _restored = mode;
    state = AppearanceState(mode, _resolve(mode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, mode.name);
    } catch (_) {
      // The choice still holds for this session.
    }
  }

  void _recheck() {
    final next = AppearanceState(state.mode, _resolve(state.mode));
    if (next != state) state = next;
  }

  Brightness _resolve(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.dark:
        return Brightness.dark;
      case AppearanceMode.light:
        return Brightness.light;
      case AppearanceMode.automatic:
        return isDaytime(clock(), _lastFix ?? _marketCentre())
            ? Brightness.light
            : Brightness.dark;
    }
  }

  static LatLng? _marketCentre() {
    try {
      for (final c in MarketConfigStore.instance.current.cities) {
        if (c.center != null) return c.center;
      }
    } catch (_) {}
    return null;
  }

  /// Day or night at [now] for [place]; the clock fallback when null.
  static bool isDaytime(DateTime now, LatLng? place) => place == null
      ? isDaytimeByClock(now.toLocal())
      : isDaytimeAt(now, place.latitude, place.longitude);
}
