import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saaradhigo_driver/core/location/location_throttle.dart';

void main() {
  const origin = LatLng(17.3850, 78.4867);
  final startedAt = DateTime.utc(2026, 8, 26, 12);

  test('first sample always passes', () {
    final throttle = LocationThrottle();

    expect(throttle.tryConsume(origin, startedAt), isTrue);
    expect(throttle.lastSent, origin);
  });

  test('blocks a nearby sample inside five seconds', () {
    final throttle = LocationThrottle();
    throttle.recordSent(origin, startedAt);

    const fiveMetersNorth = LatLng(17.385045, 78.4867);
    expect(
      throttle.shouldSend(
        fiveMetersNorth,
        startedAt.add(const Duration(seconds: 4)),
      ),
      isFalse,
    );
  });

  test('passes when distance is greater than ten metres', () {
    final throttle = LocationThrottle();
    throttle.recordSent(origin, startedAt);

    const fifteenMetersNorth = LatLng(17.385135, 78.4867);
    expect(
      throttle.shouldSend(
        fifteenMetersNorth,
        startedAt.add(const Duration(seconds: 1)),
      ),
      isTrue,
    );
  });

  test('passes at the five-second interval while stationary', () {
    final throttle = LocationThrottle();
    throttle.recordSent(origin, startedAt);

    expect(
      throttle.shouldSend(origin, startedAt.add(const Duration(seconds: 5))),
      isTrue,
    );
  });
}
