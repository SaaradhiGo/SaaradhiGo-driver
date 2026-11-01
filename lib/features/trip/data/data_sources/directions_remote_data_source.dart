import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/polyline_codec.dart';
import '../../../../core/utils/app_logger.dart';

/// The road between two points, for DRAWING.
///
/// The Google key lives on the server and is never shipped in this app: the
/// backend proxies Routes API, caches each answer for five minutes on the
/// coordinate pair, and rate-limits per user. This client just asks it.
abstract class DirectionsRemoteDataSource {
  /// Decoded road geometry, or an empty list when there is no usable route.
  Future<List<LatLng>> routeBetween(LatLng origin, LatLng destination);
}

class DirectionsRemoteDataSourceImpl implements DirectionsRemoteDataSource {
  DirectionsRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<List<LatLng>> routeBetween(LatLng origin, LatLng destination) async {
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.mapsDirections,
        data: {
          'origin_lat': origin.latitude,
          'origin_lng': origin.longitude,
          'dest_lat': destination.latitude,
          'dest_lng': destination.longitude,
        },
      );

      final body = response.data;
      final payload = (body is Map && body['data'] is Map)
          ? body['data'] as Map
          : (body is Map ? body : const {});

      final routes = payload['routes'];
      if (routes is! List || routes.isEmpty) return const [];

      final first = routes.first;
      if (first is! Map) return const [];

      final overview = first['overview_polyline'];
      final encoded = (overview is Map ? overview['points'] : null);
      if (encoded is! String || encoded.isEmpty) return const [];

      return decodePolyline(encoded);
    } catch (e) {
      // A missing route is a missing line, not a broken trip screen. The
      // markers and the live driver position do not depend on this.
      AppLogger.w('Route lookup failed: ${e.runtimeType}');
      return const [];
    }
  }
}
