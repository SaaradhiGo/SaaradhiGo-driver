import 'package:latlong2/latlong.dart';

/// Google's encoded-polyline format.
///
/// Written out rather than taking a dependency: the algorithm is twenty
/// lines, it has not changed since 2008, and the rider app already carries
/// `flutter_polyline_points` for the same job. One more package to track for
/// this would not earn its keep.
///
/// The backend returns `routes[0].overview_polyline.points` in exactly this
/// encoding — Routes API emits the same format the legacy Directions API did,
/// which is why the server could change provider without any client noticing.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      if (index >= encoded.length) return points;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    result = 0;
    shift = 0;
    do {
      if (index >= encoded.length) return points;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
