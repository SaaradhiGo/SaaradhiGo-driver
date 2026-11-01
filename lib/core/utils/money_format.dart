/// Money text in the currency the API names, never a symbol chosen by the app.
///
/// The backend sends the currency with every amount that depends on the
/// driver's country (the withdrawal balance carries `currency`). The app used to
/// print a rupee sign for everyone; a US driver saw "Minimum withdrawal is
/// \u20B9500" beside a dollar balance.
library;

const Map<String, String> _symbols = {
  'INR': '\u20B9',
  'USD': '\$',
};

/// The symbol for an ISO code: `INR` -> rupee sign, `USD` -> `$`. Another code
/// is shown as the code and a space (`EUR 5.00`); no code gives no symbol.
String currencySymbol(String? currency) {
  final code = (currency ?? '').trim().toUpperCase();
  if (code.isEmpty) return '';
  return _symbols[code] ?? '$code ';
}

/// `symbol` + `amount` to [decimals] places.
String formatMoney(double amount, String? currency, {int decimals = 2}) =>
    '${currencySymbol(currency)}${amount.toStringAsFixed(decimals)}';

/// A threshold such as a minimum: no decimals when it is a whole number.
String formatThreshold(double amount, String? currency) =>
    formatMoney(amount, currency, decimals: amount == amount.roundToDouble() ? 0 : 2);
