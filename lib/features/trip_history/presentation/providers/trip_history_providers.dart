import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/trip_history_remote_data_source.dart';
import '../../data/repositories/trip_history_repository_impl.dart';
import '../../domain/repositories/trip_history_repository.dart';
import 'trip_details_notifier.dart';
import 'trip_history_notifier.dart';
import 'trip_history_state.dart';

export 'trip_details_notifier.dart';
export 'trip_history_notifier.dart';
export 'trip_history_state.dart';

final tripHistoryRemoteDataSourceProvider =
    Provider<TripHistoryRemoteDataSource>((ref) {
      return TripHistoryRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
    });

final tripHistoryRepositoryProvider = Provider<TripHistoryRepository>((ref) {
  return TripHistoryRepositoryImpl(
    ref.watch(tripHistoryRemoteDataSourceProvider),
  );
});

final tripHistoryNotifierProvider =
    NotifierProvider<TripHistoryNotifier, TripHistoryState>(() {
      return TripHistoryNotifier();
    });

final tripDetailsNotifierProvider =
    NotifierProvider<TripDetailsNotifier, TripDetailsState>(
      TripDetailsNotifier.new,
    );
