import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/maps/placeholder_maps_provider.dart';
import 'package:saaradhigo_driver/core/maps/sg_map.dart';
import 'package:saaradhigo_driver/ui/driver_home_view.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';

const kPlaceholderMaps = PlaceholderMapsProvider();

Widget sgApp(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: sgDarkTheme(),
      home: Scaffold(backgroundColor: SgColors.bg000, body: child),
    );

void setPhoneSurface(dynamic tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
}

/// flutter test draws every font as Ahem blocks unless told otherwise.
Future<void> loadSgFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  await load('Manrope', ['Manrope.ttf']);
  await load('CormorantGaramond', ['CormorantGaramond.ttf']);
}

Widget homeFrame({
  bool online = false,
  String? statusLabel,
  HomeBlocker? blocker,
  VoidCallback? onGoOnline,
  VoidCallback? onGoOffline,
}) =>
    DriverHomeView(
      map: const SgMap(
        provider: kPlaceholderMaps,
        initialCenter: LatLng(17.44, 78.38),
        markers: [
          SgMarker(
            id: 'me',
            point: LatLng(17.44, 78.38),
            icon: SgIconMarker(Icons.circle, SgColors.pickup, size: 20),
            anchor: Offset(0.5, 0.5),
          ),
        ],
      ),
      online: online,
      statusLabel: statusLabel ?? (online ? 'Online' : 'Offline'),
      earnings: '₹1,240',
      trips: 6,
      onlineFor: online ? const Duration(hours: 1, minutes: 12) : null,
      blocker: blocker,
      onMenu: () {},
      onEarnings: () {},
      onGoOnline: onGoOnline ?? () {},
      onGoOffline: onGoOffline ?? () {},
    );

const sampleOffer = <String, dynamic>{
  'type': 'ride_request',
  'trip_id': 19,
  'rider_name': 'Raja Kumar',
  'pickup_address': 'Ameerpet Metro Station',
  'destination_address': 'Hitech City, Madhapur',
  'pickup_lat': 17.385,
  'pickup_lng': 78.4867,
  'destination_lat': 17.44,
  'destination_lng': 78.38,
  'estimated_fare': '247.80',
  'distance_km': 8.4,
  'duration_min': 20,
  'pickup_distance_km': 1.2,
  'pickup_eta_min': 4,
  'vehicle_type': 'sedan',
  'payment_method': 'cash',
};
