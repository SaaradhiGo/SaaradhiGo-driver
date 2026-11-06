import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/maps/placeholder_maps_provider.dart';
import 'package:saaradhigo_driver/core/maps/sg_map.dart';
import 'package:saaradhigo_driver/ui/driver_home_view.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';
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

  await load('AnekLatin', ['AnekLatin.ttf']);
  await load('AnekTelugu', ['AnekTelugu.ttf']);
  await load('AnekDevanagari', ['AnekDevanagari.ttf']);
  await load('Cinzel', ['Cinzel-SemiBold.ttf']);
}

Widget homeFrame({
  bool online = false,
  String? statusLabel,
  HomeBlocker? blocker,
  VoidCallback? onGoOnline,
  VoidCallback? onGoOffline,
  String? earnings,
  String? commission,
}) =>
    DriverHomeView(
      map: SgMap(
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
      earnings: earnings ?? '₹1,240',
      commission: commission,
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

final _tripMap = SgMap(
  provider: kPlaceholderMaps,
  initialCenter: LatLng(17.44, 78.38),
  markers: [
    SgMarker(
      id: 'me',
      point: LatLng(17.44, 78.38),
      icon: SgIconMarker(Icons.navigation_rounded, SgColors.gold500, size: 28),
      anchor: Offset(0.5, 0.5),
    ),
  ],
);

/// Stand-in for the SOS hold button, which needs the app's providers.
Widget sosStandIn() => SizedBox(
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(color: SgColors.danger, shape: BoxShape.circle),
        child: Center(child: Text('SOS')),
      ),
    );

Widget toPickupFrame({VoidCallback? onArrived, VoidCallback? onCancel}) =>
    DriverTripScaffold(
      map: _tripMap,
      topActions: sosStandIn(),
      mapButton: NavigateButton(onTap: () {}),
      sheet: ToPickupSheet(
        riderName: 'Raja Kumar',
        riderRating: 4.8,
        pickupAddress: 'Ameerpet Metro Station, Gate 2',
        awayLine: '1.2 km · 4 min',
        onArrived: onArrived ?? () {},
        onCancel: onCancel ?? () {},
        onMessage: () {},
      ),
    );

Widget inTripFrame({VoidCallback? onComplete}) => DriverTripScaffold(
      map: _tripMap,
      topActions: sosStandIn(),
      mapButton: NavigateButton(onTap: () {}),
      sheet: InTripSheet(
        destination: 'Hitech City, Madhapur',
        riderName: 'Raja Kumar',
        leftLine: '8.4 km · 20 min',
        fare: '₹248',
        payment: 'Cash',
        onComplete: onComplete ?? () {},
      ),
    );

Widget completeFrame({bool cash = true, VoidCallback? onConfirmCash}) =>
    TripCompleteView(
      title: 'Trip complete',
      riderName: 'Raja Kumar',
      amount: '₹248',
      amountCaption: 'Fare',
      cashToCollect: cash ? '₹248' : null,
      paidLine: cash ? null : 'Paid by UPI',
      facts: [
        ('Distance', '8.4 km'),
        ('Time', '21 min'),
        ('Payment', cash ? 'Cash' : 'UPI'),
      ],
      onConfirmCash: onConfirmCash ?? () {},
      onDone: () {},
      onRate: () {},
    );
