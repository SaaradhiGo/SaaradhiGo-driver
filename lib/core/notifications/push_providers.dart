/// Providers for the push stack.
///
/// The transport is a separate provider from everything above it so a test
/// can override it with a fake. That is the only reason this file exists:
/// `firebase_messaging` throws `MissingPluginException` in a test binding, so
/// without an override point the login flow, the token registration and the
/// offer coordinator would all be untestable.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/trip/presentation/providers/trip_providers.dart';
import '../network/dio_client.dart';
import 'firebase_push_transport.dart';
import 'push_registrar.dart';
import 'push_transport.dart';
import 'ride_offer_coordinator.dart';

/// The FCM seam. Overridden in tests with a fake.
final pushTransportProvider = Provider<PushTransport>((ref) {
  final transport = FirebasePushTransport();
  ref.onDispose(transport.dispose);
  return transport;
});

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(
    transport: ref.watch(pushTransportProvider),
    dioClient: ref.watch(dioClientProvider),
  );
  ref.onDispose(registrar.dispose);
  return registrar;
});

final rideOfferCoordinatorProvider = Provider<RideOfferCoordinator>((ref) {
  final coordinator = RideOfferCoordinator(
    transport: ref.watch(pushTransportProvider),
    // Read, not watched: the question is asked at the instant an offer
    // arrives, and the coordinator must not be rebuilt every time a trip
    // changes state -- that would drop its deduplication memory.
    hasActiveTrip: () {
      final session = ref.read(tripSessionNotifierProvider);
      return session.isActive;
    },
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
