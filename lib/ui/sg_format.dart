/// Money and dates for the signed-in designs (2026-11-08): intl formats in
/// the user's language, the currency the API (or the market) names.
library;

import 'package:intl/intl.dart';

import '../core/market/market_config_store.dart';
import 'sg_text.dart';

/// The intl locale for the app language; Indian English for rupees in English.
String sgNumberLocale(String currency, [String? languageCode]) {
  final lang = languageCode ?? SgText.languageCode;
  if (lang == 'en' && currency == 'INR') return 'en_IN';
  return lang;
}

/// An amount the API returned, formatted in [currency] (default: the
/// market's). Whole units, or the currency's decimals when [whole] is false.
/// Null when [raw] is missing or does not parse: nothing is invented.
String? sgMoney(Object? raw, {String? currency, bool whole = true}) {
  if (raw == null) return null;
  final market = MarketConfigStore.instance.current;
  final value = raw is num
      ? raw.toDouble()
      : double.tryParse(market.stripSymbol('$raw').replaceAll(',', '').trim());
  if (value == null) return null;
  final code = (currency == null || currency.trim().isEmpty)
      ? market.currencyCode
      : currency.trim().toUpperCase();
  // whole: false keeps the currency's own decimals (₹0.00, ₹631.55).
  final f = NumberFormat.simpleCurrency(
    locale: sgNumberLocale(code),
    name: code,
    decimalDigits: whole ? 0 : null,
  );
  return f.format(whole ? value.roundToDouble() : value);
}

/// "Sun, 8 Nov" (with the year when it is not this year).
String sgDay(DateTime d, {DateTime? now, String? languageCode}) {
  final n = now ?? DateTime.now();
  final lang = languageCode ?? SgText.languageCode;
  final pattern = d.year == n.year ? 'EEE, d MMM' : 'EEE, d MMM y';
  return DateFormat(pattern, lang).format(d);
}

/// "Sun, 8 Nov · 9:12 am" for list rows.
String sgDayTime(DateTime d, {DateTime? now, String? languageCode}) {
  final lang = languageCode ?? SgText.languageCode;
  final time = DateFormat('h:mm a', lang).format(d).toLowerCase();
  return '${sgDay(d, now: now, languageCode: lang)} · $time';
}

/// Driver area v2 (10 Nov): money always with two decimals, in [currency]
/// (the driver's). Null when [raw] does not parse.
String? sgMoney2(Object? raw, {String? currency}) {
  if (raw == null) return null;
  final value = raw is num ? raw.toDouble() : double.tryParse('$raw'.trim());
  if (value == null) return null;
  final code = (currency == null || currency.trim().isEmpty)
      ? MarketConfigStore.instance.current.currencyCode
      : currency.trim().toUpperCase();
  final locale = sgNumberLocale(code);
  final symbol = NumberFormat.simpleCurrency(
    locale: locale,
    name: code,
  ).currencySymbol;
  return NumberFormat.currency(
    locale: locale,
    name: code,
    symbol: symbol,
    decimalDigits: 2,
  ).format(value);
}

/// The market's numeric date: dd/MM/yyyy in India, MM/dd/yyyy in the USA.
String sgMarketDate(DateTime d, String? country) =>
    DateFormat(country == 'US' ? 'MM/dd/yyyy' : 'dd/MM/yyyy').format(d);

/// An ISO date from the API ("2027-03-09", or a full timestamp) in the market's
/// numeric order. The text unchanged when it is not a date; empty for null.
String sgMarketDateText(String? iso, String? country) {
  final raw = (iso ?? '').trim();
  if (raw.isEmpty) return '';
  final d = DateTime.tryParse(raw);
  return d == null ? raw : sgMarketDate(d, country);
}

/// The hint for a date input in the market's order.
String sgDateHint(String? country) =>
    country == 'US' ? 'mm/dd/yyyy' : 'dd/mm/yyyy';
