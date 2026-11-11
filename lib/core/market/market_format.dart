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

/// The symbol for an amount: the API's own currency when it named one,
/// otherwise the market's.
String symbolFor(String? apiCurrency) {
  final code = (apiCurrency ?? '').trim().toUpperCase();
  if (code.isEmpty) return marketSymbol();
  if (code == 'INR') return '₹';
  if (code == 'USD') return r'$';
  return '$code ';
}
