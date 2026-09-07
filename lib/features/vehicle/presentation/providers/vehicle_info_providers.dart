import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/vehicles_remote_data_source.dart';
import '../../data/repositories/vehicles_repository_impl.dart';
import '../../domain/repositories/vehicles_repository.dart';
import 'vehicle_info_notifier.dart';
import 'vehicle_info_state.dart';

export 'vehicle_info_notifier.dart';
export 'vehicle_info_state.dart';

final vehiclesRemoteDataSourceProvider = Provider<VehiclesRemoteDataSource>((
  ref,
) {
  return VehiclesRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  return VehiclesRepositoryImpl(ref.watch(vehiclesRemoteDataSourceProvider));
});

final vehicleInfoNotifierProvider =
    NotifierProvider<VehicleInfoNotifier, VehicleInfoState>(() {
      return VehicleInfoNotifier();
    });
