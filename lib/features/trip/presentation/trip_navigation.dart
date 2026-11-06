import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/trip_model.dart';
import '../../../ui/driver_trip_views.dart';

/// City speed for the pickup minutes; the backend's PICKUP_ETA_CITY_KMH.
const double kCityKmh = 18;

String tripChatPath(TripModel trip) {
  final name = trip.riderName?.trim();
  return '/trip-chat/${trip.id}'
      '${(name == null || name.isEmpty) ? '' : '?riderName=${Uri.encodeQueryComponent(name)}'}';
}

/// "1.2 km · 4 min" along the road; null until a road came back, so the
/// sheet never shows a straight-line guess as a road distance.
String? roadLine(List<LatLng> road) {
  if (road.length < 2) return null;
  const d = Distance();
  var metres = 0.0;
  for (var i = 1; i < road.length; i++) {
    metres += d.as(LengthUnit.Meter, road[i - 1], road[i]);
  }
  final km = metres / 1000;
  return distanceTimeLine(km, (km / kCityKmh * 60).ceilToDouble());
}

/// Hands the leg to the phone's map app for turn-by-turn.
Future<void> openNavigation(BuildContext context, LatLng to) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${to.latitude},${to.longitude}&travelmode=driving',
  );
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication)
      .catchError((_) => false);
  if (!ok) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('No map app could open the route.')),
    );
  }
}
