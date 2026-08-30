import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/data_sources/trip_remote_data_source.dart';
import '../../data/data_sources/trip_status_consumer.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/trip_repository.dart';
import 'trip_session_notifier.dart';
import 'trip_session_state.dart';

export 'trip_session_state.dart';

/// Builds a [TripStatusConsumer] bound to a specific trip. A factory because a
/// consumer is created per trip and disposed when it settles; overridden in
/// tests to inject a fake.
typedef TripStatusConsumerFactory = TripStatusConsumer Function(int tripId);

final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  return TripRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(ref.watch(tripRemoteDataSourceProvider));
});

final tripStatusConsumerFactoryProvider = Provider<TripStatusConsumerFactory>((
  ref,
) {
  return (tripId) => TripStatusConsumer(
    tripId: tripId,
    tokenReader: SecureStorageService.getAccessToken,
  );
});

final tripSessionNotifierProvider =
    NotifierProvider<TripSessionNotifier, TripSessionState>(
      TripSessionNotifier.new,
    );
