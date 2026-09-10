import 'package:geolocator/geolocator.dart';

/// Thin seam over the `geolocator` static API.
///
/// `geolocator` exposes everything through statics on [Geolocator], which are
/// impossible to stub. Everything in the app talks to this interface instead so
/// that permission and stream behaviour can be driven from unit tests.
abstract class GeolocatorAdapter {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<Position?> getLastKnownPosition();

  Future<Position> getCurrentPosition(LocationSettings settings);

  Stream<Position> getPositionStream(LocationSettings settings);

  Stream<ServiceStatus> getServiceStatusStream();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class GeolocatorAdapterImpl implements GeolocatorAdapter {
  const GeolocatorAdapterImpl();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position?> getLastKnownPosition() => Geolocator.getLastKnownPosition();

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) =>
      Geolocator.getCurrentPosition(locationSettings: settings);

  @override
  Stream<Position> getPositionStream(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings);

  @override
  Stream<ServiceStatus> getServiceStatusStream() =>
      Geolocator.getServiceStatusStream();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
