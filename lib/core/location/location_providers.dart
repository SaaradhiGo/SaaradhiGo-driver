import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'geolocator_adapter.dart';
import 'location_notifier.dart';
import 'location_service.dart';
import 'location_state.dart';

export 'location_service.dart' show LocationAvailability, LocationTrackingMode;
export 'location_state.dart';

final geolocatorAdapterProvider = Provider<GeolocatorAdapter>((ref) {
  return const GeolocatorAdapterImpl();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(geolocatorAdapterProvider));
});

final locationNotifierProvider =
    NotifierProvider<LocationNotifier, LocationState>(() {
      return LocationNotifier();
    });

/// Coordinate-only projection of [locationNotifierProvider].
///
/// The raw stream fires far more often than the map needs. Widgets that only
/// render a marker watch this so they rebuild on coordinate changes rather than
/// on every heading/accuracy tick. docs/12_ARCHITECTURE.md:421.
final driverPositionProvider = Provider<LatLng?>((ref) {
  return ref.watch(locationNotifierProvider).positionOrNull;
});

/// True when the last fix is stale or the stream errored but a position is
/// still being displayed.
final weakGpsProvider = Provider<bool>((ref) {
  final state = ref.watch(locationNotifierProvider);
  return state is LocationStateTracking && state.weakSignal;
});
