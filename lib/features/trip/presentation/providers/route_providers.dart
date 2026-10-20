import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/directions_remote_data_source.dart';

final directionsDataSourceProvider = Provider<DirectionsRemoteDataSource>((ref) {
  return DirectionsRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

/// One leg of a journey, identified coarsely on purpose.
///
/// THE DRIVER MOVING MUST NOT BUY ROUTES. The driver's position updates every
/// few seconds; if that were part of this key, every GPS frame would become a
/// Routes request. Coordinates are rounded to three decimal places — about
/// 110 m — so the driver has to make real progress before another lookup is
/// worth doing, and the server's five-minute cache absorbs the rest.
class RouteLeg {
  RouteLeg(LatLng origin, LatLng destination)
      : originLat = _round(origin.latitude),
        originLng = _round(origin.longitude),
        destLat = _round(destination.latitude),
        destLng = _round(destination.longitude);

  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;

  LatLng get origin => LatLng(originLat, originLng);
  LatLng get destination => LatLng(destLat, destLng);

  @override
  bool operator ==(Object other) =>
      other is RouteLeg &&
      other.originLat == originLat &&
      other.originLng == originLng &&
      other.destLat == destLat &&
      other.destLng == destLng;

  @override
  int get hashCode => Object.hash(originLat, originLng, destLat, destLng);

  @override
  String toString() => '$originLat,$originLng->$destLat,$destLng';
}

/// The road geometry for a leg.
///
/// A `family` keyed on the rounded leg, so Riverpod caches per leg and a
/// rebuild with an unchanged leg reuses the answer instead of asking again.
/// An empty list means "no route to draw" — the caller shows markers only
/// rather than inventing a line between the points.
final routeForLegProvider =
    FutureProvider.family<List<LatLng>, RouteLeg>((ref, leg) async {
  // Hold the result so a brief rebuild does not re-request; the server cache
  // is five minutes, and a leg that stops being watched can be dropped.
  final link = ref.keepAlive();
  Future<void>.delayed(const Duration(minutes: 5), link.close);

  return ref
      .watch(directionsDataSourceProvider)
      .routeBetween(leg.origin, leg.destination);
});
