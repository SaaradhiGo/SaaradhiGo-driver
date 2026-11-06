import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/location/location_providers.dart';
import 'package:saaradhigo_driver/core/theme/appearance_controller.dart';
import 'package:saaradhigo_driver/core/theme/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const hyderabad = LatLng(17.385, 78.4867);

  ProviderContainer container({LatLng? fix}) {
    final c = ProviderContainer(
      overrides: [driverPositionProvider.overrideWithValue(fix)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => AppearanceController.clock = DateTime.now);

  test('automatic is the default: light at noon in Hyderabad', () async {
    await AppearanceController.restore();
    AppearanceController.clock = () => DateTime.utc(2026, 11, 5, 6, 30);
    final s = container(fix: hyderabad).read(appearanceControllerProvider);
    expect(s.mode, AppearanceMode.automatic);
    expect(s.brightness, Brightness.light);
  });

  test('automatic: dark at 21:00 in Hyderabad', () async {
    await AppearanceController.restore();
    AppearanceController.clock = () => DateTime.utc(2026, 11, 5, 15, 30);
    final s = container(fix: hyderabad).read(appearanceControllerProvider);
    expect(s.brightness, Brightness.dark);
  });

  test('a forced mode wins and is persisted', () async {
    await AppearanceController.restore();
    AppearanceController.clock = () => DateTime.utc(2026, 11, 5, 6, 30);
    final c = container(fix: hyderabad);
    await c
        .read(appearanceControllerProvider.notifier)
        .setMode(AppearanceMode.dark);
    expect(c.read(appearanceControllerProvider).brightness, Brightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.prefsKey), 'dark');

    await AppearanceController.restore();
    final again = container(fix: hyderabad).read(appearanceControllerProvider);
    expect(again.mode, AppearanceMode.dark);
  });

  test('no fix and no market city: the 06:00-18:00 clock fallback', () {
    expect(
      AppearanceController.isDaytime(DateTime(2026, 1, 1, 12), null),
      isTrue,
    );
    expect(
      AppearanceController.isDaytime(DateTime(2026, 1, 1, 22), null),
      isFalse,
    );
  });

  test('language persists and only en/te/hi are accepted', () async {
    await LocaleController.restore();
    final c = container();
    expect(c.read(localeControllerProvider), const Locale('en'));
    await c
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('te'));
    expect(c.read(localeControllerProvider), const Locale('te'));
    await LocaleController.restore();
    expect(container().read(localeControllerProvider), const Locale('te'));
    await c
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('fr'));
    expect(c.read(localeControllerProvider), const Locale('en'));
  });
}
