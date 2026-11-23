/// Small helpers for code that is not a widget (and for widgets that are
/// not worth a provider): the current market's money symbol and phone prefix.
///
/// An amount the API sent WITH a currency (the withdrawal balance) is formatted
/// from that currency instead (core/utils/money_format.dart): the API wins.
library;

import 'market_config_store.dart';

/// The symbol of the configured market's currency; the rupee sign until
/// another market is configured.
String marketSymbol() => MarketConfigStore.instance.current.currencySymbol;

/// An amount in the market's money (owner, 23 Nov): India in whole rupees,
/// half up ("₹176", never "₹176.35"); other currencies keep their cents.
String marketAmount(num value) {
  final inr =
      MarketConfigStore.instance.current.currencyCode.toUpperCase() == 'INR';
  return inr
      ? '${marketSymbol()}${value.round()}'
      : '${marketSymbol()}${value.toStringAsFixed(2)}';
}

/// The symbol for an amount: the API's own currency when it named one,
/// otherwise the market's.
String symbolFor(String? apiCurrency) {
  final code = (apiCurrency ?? '').trim().toUpperCase();
  if (code.isEmpty) return marketSymbol();
  if (code == 'INR') return '₹';
  if (code == 'USD') return r'$';
  return '$code ';
}
