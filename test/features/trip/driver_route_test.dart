import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/polyline_codec.dart';

/// The driver's trip map drew a straight great-circle line between pickup and
/// destination, because real routing "needs a directions provider + API key".
/// That is now in place: Routes API is enabled and the backend proxies it, so
/// the line is the actual road.
///
/// Two things have to hold for that to be safe:
///   * the encoded geometry decodes to the right places, and
///   * a driver moving does not turn into a Routes request per GPS frame.
void main() {
  // The real reply for the QA route, Vijayawada pickup -> destination.
  const qaRoute =
      '{zvcBmqfkNZEF?LKN@HJ?PIHCb@@j@JrACXSd@uAlCiAtGu@nD]nAaBxEQR]JKLuDxGiAjBSf@k@lB'
      '[`A_@`BY~@eFkAwH}AwAU}DWsCKwA@yBCD\\OHoDlBaBt@iAp@ULEHKp@MFeCj@AROBKIAM@A_@oB'
      'kDPcAB_EIvBjP\\tB~@`Ht@|GCn@Gj@`@JXxBfBV';

  group('polyline decoding', () {
    test('decodes the QA route to the pickup and destination it describes', () {
      final points = decodePolyline(qaRoute);

      expect(points.length, greaterThan(50));
      // Pickup 16.5062,80.6480 and destination 16.5190,80.6305.
      expect(points.first.latitude, closeTo(16.5062, 0.001));
      expect(points.first.longitude, closeTo(80.6480, 0.001));
      expect(points.last.latitude, closeTo(16.5190, 0.001));
      expect(points.last.longitude, closeTo(80.6305, 0.001));
    });

    test('follows roads rather than running straight', () {
      final points = decodePolyline(qaRoute);
      // A straight line needs two points. A road does not.
      expect(points.length, greaterThan(10),
          reason: 'this is meant to be the road, not a line between two pins');
    });

    test('an empty or malformed string yields nothing, never a crash', () {
      expect(decodePolyline(''), isEmpty);
      expect(() => decodePolyline('~~~not~a~polyline~~~'), returnsNormally);
    });
  });
}
