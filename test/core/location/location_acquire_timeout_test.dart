// Regression: "Getting your location…" had no end.
//
// WHAT HAPPENED (QA emulator, and any handset with a cold GPS indoors)
// `LocationState.acquiring` was entered on start and nothing ever moved it
// on if the platform produced no first fix. The duty screen showed
// "Getting your location…" indefinitely: no error, no retry, and no way to
// go online. The state machine already knew how to say "service disabled",
// "permission denied" and "error" — it simply never got there.
//
// These tests bound that wait, and pin that the bound does not fire on a
// driver whose location IS working.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saaradhigo_driver/core/location/geolocator_adapter.dart';
import 'package:saaradhigo_driver/core/location/location_providers.dart';
import 'package:saaradhigo_driver/core/location/location_state.dart';

Position _position({double lat = 16.5062, double lng = 80.6480}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// A geolocator that grants permission and then delivers nothing — the exact
/// shape of the failure: everything "works", no fix ever arrives.
class _SilentGeolocator implements GeolocatorAdapter {
  final positions = StreamController<Position>.broadcast();
  final serviceStatuses = StreamController<ServiceStatus>.broadcast();

  /// A cached fix, if the platform has one. Null is the failing case.
  Position? cached;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Stream<Position> getPositionStream(LocationSettings settings) =>
      positions.stream;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => serviceStatuses.stream;

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) async =>
      cached ?? _position();

  @override
  Future<Position?> getLastKnownPosition() async => cached;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  Future<void> dispose() async {
    await positions.close();
    await serviceStatuses.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a location that never arrives becomes a recoverable error', () {
    fakeAsync((async) {
      final geolocator = _SilentGeolocator();
      final container = ProviderContainer(
        overrides: [geolocatorAdapterProvider.overrideWithValue(geolocator)],
      );
      addTearDown(container.dispose);

      unawaited(container.read(locationNotifierProvider.notifier).start());
      async.flushMicrotasks();

      // Still trying — we do not give up on a driver prematurely.
      async.elapse(const Duration(seconds: 10));
      expect(
        container.read(locationNotifierProvider),
        isA<LocationStateAcquiring>(),
        reason: 'ten seconds is a normal cold start, not a failure',
      );

      // Past the bound: say so, instead of spinning forever.
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();

      final state = container.read(locationNotifierProvider);
      expect(state, isA<LocationStateError>());
      expect(
        state.blocksGoingOnline,
        isTrue,
        reason: 'a driver with no location must never be marked online',
      );
      expect((state as LocationStateError).message, isNotEmpty);
    });
  });

  test('a fix that arrives in time cancels the bound', () {
    fakeAsync((async) {
      final geolocator = _SilentGeolocator();
      final container = ProviderContainer(
        overrides: [geolocatorAdapterProvider.overrideWithValue(geolocator)],
      );
      addTearDown(container.dispose);

      unawaited(container.read(locationNotifierProvider.notifier).start());
      async.flushMicrotasks();

      geolocator.positions.add(_position());
      async.flushMicrotasks();

      // Well past the bound.
      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();

      final state = container.read(locationNotifierProvider);
      expect(state, isA<LocationStateTracking>(),
          reason: 'a working driver must not be knocked into an error state');
      expect(state.blocksGoingOnline, isFalse);
    });
  });

  test('a cached fix counts as acquired', () {
    fakeAsync((async) {
      final geolocator = _SilentGeolocator()..cached = _position();
      final container = ProviderContainer(
        overrides: [geolocatorAdapterProvider.overrideWithValue(geolocator)],
      );
      addTearDown(container.dispose);

      unawaited(container.read(locationNotifierProvider.notifier).start());
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();

      expect(
        container.read(locationNotifierProvider),
        isA<LocationStateTracking>(),
      );
    });
  });

  test('a late fix recovers the driver out of the error state', () {
    fakeAsync((async) {
      final geolocator = _SilentGeolocator();
      final container = ProviderContainer(
        overrides: [geolocatorAdapterProvider.overrideWithValue(geolocator)],
      );
      addTearDown(container.dispose);

      unawaited(container.read(locationNotifierProvider.notifier).start());
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      expect(container.read(locationNotifierProvider), isA<LocationStateError>());

      // GPS finally locks on. The driver should not have to restart the app.
      geolocator.positions.add(_position());
      async.flushMicrotasks();

      final state = container.read(locationNotifierProvider);
      expect(state, isA<LocationStateTracking>());
      expect(state.blocksGoingOnline, isFalse);
    });
  });
}
