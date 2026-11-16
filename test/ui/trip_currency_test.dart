/// 16 Nov, trip 226 on the emulator: a US trip showed "₹28", "You earn ₹27"
/// and "₹28.20" because the app held India's config. Money follows the trip.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/market/market_config.dart';
import 'package:saaradhigo_driver/core/market/market_config_store.dart';
import 'package:saaradhigo_driver/ui/driver_home_view.dart';
import 'package:saaradhigo_driver/ui/driver_trip_views.dart';
import 'package:saaradhigo_driver/ui/incoming_offer_card.dart';

import '../support/driver_ui_fixtures.dart';

void main() {
  setUp(() => MarketConfigStore.instance.debugSet(MarketConfig.builtIn));

  test('a USD offer reads in dollars and miles on an India config', () {
    final o = OfferData.fromPayload({
      ...sampleOfferWithEarning,
      'currency': 'USD',
      'estimated_fare': '28.20',
      'earning': '26.70',
    });
    expect(o.fare, r'$28');
    expect(o.earning, r'$27');
    expect(o.fare, isNot(contains('₹')));
  });

  test('an INR offer is unchanged', () {
    final o = OfferData.fromPayload(sampleOfferWithEarning);
    expect(o.fare, '₹248');
    expect(o.earning, '₹198');
  });

  test('trip screens: the exact amount in the trip currency', () {
    expect(exactMoney('28.20', currency: 'USD'), r'$28.20');
    expect(exactMoney('28', currency: 'USD'), r'$28');
    expect(exactMoney('150'), '₹150');
    expect(wholeMoney('1234.4', currency: 'USD'), r'$1,234');
  });
}
