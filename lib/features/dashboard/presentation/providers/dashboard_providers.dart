import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/driver_location_consumer.dart';
import 'availability_notifier.dart';
import 'availability_state.dart';

export 'availability_state.dart';

/// Builds a fresh [DriverLocationConsumer].
///
/// A factory rather than a singleton because a consumer is created per online
/// session and disposed on going offline. Overridden in tests to inject a fake.
typedef DriverLocationConsumerFactory = DriverLocationConsumer Function();

final driverLocationConsumerFactoryProvider =
    Provider<DriverLocationConsumerFactory>((ref) {
      return () => DriverLocationConsumer(
        // Refreshed if it has expired. Reading storage directly left a driver
        // whose access token lapsed unable to go online at all.
        tokenReader: ref.read(socketAccessTokenProvider),
        // Read at connect time (and on every reconnect) so the socket never
        // opens with a stale coordinate.
        positionReader: () => ref.read(locationNotifierProvider).positionOrNull,
      );
    });

final availabilityNotifierProvider =
    NotifierProvider<AvailabilityNotifier, AvailabilityState>(() {
      return AvailabilityNotifier();
    });
