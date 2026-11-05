import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/directions_remote_data_source.dart';

/// Routes lookups go through the backend proxy. Callers fetch a leg once and
/// re-fetch only off-route (see `RouteFollow`), never per GPS frame.
final directionsDataSourceProvider = Provider<DirectionsRemoteDataSource>((ref) {
  return DirectionsRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});
