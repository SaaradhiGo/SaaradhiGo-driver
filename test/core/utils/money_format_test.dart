import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/utils/money_format.dart';

void main() {
  group('money_format', () {
    test('symbols come from the currency the API names', () {
      expect(currencySymbol('INR'), '\u20B9');
      expect(currencySymbol('usd'), '\$');
      expect(currencySymbol('EUR'), 'EUR ');
      expect(currencySymbol(null), '');
    });

    test('formatMoney and formatThreshold', () {
      expect(formatMoney(30, 'USD'), '\$30.00');
      expect(formatMoney(8200, 'INR'), '\u20B98200.00');
      expect(formatThreshold(500, 'INR'), '\u20B9500');
      expect(formatThreshold(1, 'USD'), '\$1');
      expect(formatThreshold(1.5, 'USD'), '\$1.50');
      expect(formatMoney(5, null), '5.00');
    });
  });
}
