import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

/// The chime and buzz when an offer card appears.
///
/// The platform side decides from the phone's own settings: sound and
/// vibration in normal mode, vibration only in vibrate mode, nothing in
/// silent mode or Do Not Disturb (Android ringer mode; the iOS switch).
class OfferAlert {
  const OfferAlert([this._channel = const MethodChannel('saaradhigo/alert')]);

  final MethodChannel _channel;

  Future<void> play() async {
    try {
      await _channel.invokeMethod<void>('offer');
    } on MissingPluginException {
      // Tests and platforms without the channel: the card still shows.
    } on PlatformException catch (e) {
      AppLogger.w('Offer alert failed: ${e.message}');
    }
  }
}
