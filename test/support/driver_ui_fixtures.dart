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

  await load('Inter', ['Inter-Regular.ttf', 'Inter-SemiBold.ttf']);
  await load('NotoSansTelugu', [
    'NotoSansTelugu-Regular.ttf',
    'NotoSansTelugu-SemiBold.ttf',
  ]);
  await load('NotoSansDevanagari', [
    'NotoSansDevanagari-Regular.ttf',
    'NotoSansDevanagari-SemiBold.ttf',
  ]);
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
      onSafety: () {},
      onInbox: () {},
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

/// The offer as the backend sends it once it carries the driver's earning.
const sampleOfferWithEarning = <String, dynamic>{
  ...sampleOffer,
  'earning': '198.24',
  'commission_rate': '20.00',
  'commission_amount': '49.56',
  'rider_rating': 4.8,
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

Widget inTripFrame({VoidCallback? onComplete, bool night = false}) =>
    DriverTripScaffold(
      map: _tripMap,
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: OpenInMapsBanner(onTap: () {})),
              const SizedBox(width: 8),
              sosStandIn(),
            ],
          ),
          if (night) ...[const SizedBox(height: 8), const NightModeChip()],
        ],
      ),
      sheet: InTripSheet(
        destination: 'Hitech City, Madhapur, Hyderabad',
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

const sampleDocsBody = <String, dynamic>{
  'data': {
    'doc_status': 'pending',
    'doc_rejection_reason': 'The licence photo is blurred.',
    'vehicle': {'id': 7},
    'driver_documents': [
      {'key': 'license_front', 'label': 'Driving licence (front)', 'required': true, 'present': true, 'status': 'rejected', 'reason': 'The photo is blurred.'},
      {'key': 'license_back', 'label': 'Driving licence (back)', 'required': true, 'present': true, 'status': 'approved'},
    ],
    'vehicle_documents': [
      {'key': 'rc', 'label': 'Registration (RC)', 'required': true, 'present': true, 'status': 'in_review'},
      {'key': 'insurance', 'label': 'Insurance', 'required': true, 'present': false},
      {'key': 'permit', 'label': 'Permit', 'required': true, 'present': true},
    ],
  },
};

const sampleDailyBody = <String, dynamic>{
  'days': [
    {'date': '2026-11-06', 'trips': 3, 'gross': '428.00', 'commission': '64.00', 'net': '364.00'},
    {'date': '2026-10-31', 'trips': 5, 'gross': '700.00', 'commission': '105.00', 'net': '595.00'},
    {'date': '2026-11-01', 'trips': 0, 'gross': '0', 'commission': '0', 'net': '0'},
    {'date': '2026-11-02', 'trips': 2, 'gross': '300', 'commission': '45', 'net': '255'},
    {'date': '2026-11-03', 'trips': 4, 'gross': '520', 'commission': '78', 'net': '442'},
    {'date': '2026-11-04', 'trips': 6, 'gross': '900', 'commission': '135', 'net': '765'},
    {'date': '2026-11-05', 'trips': 1, 'gross': '150', 'commission': '22.5', 'net': '127.5'},
  ],
};
