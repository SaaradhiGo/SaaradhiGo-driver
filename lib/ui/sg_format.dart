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
/// market's). Whole units unless the amount has paise/cents and [whole] is
/// false. Null when [raw] is missing or does not parse: nothing is invented.
String? sgMoney(Object? raw, {String? currency, bool whole = true}) {
  if (raw == null) return null;
  final market = MarketConfigStore.instance.current;
  final value = raw is num
      ? raw.toDouble()
      : double.tryParse(
          market.stripSymbol('$raw').replaceAll(',', '').trim(),
        );
  if (value == null) return null;
  final code = (currency == null || currency.trim().isEmpty)
      ? market.currencyCode
      : currency.trim().toUpperCase();
  final hasFraction = (value - value.truncateToDouble()).abs() > 0.004;
  final f = NumberFormat.simpleCurrency(
    locale: sgNumberLocale(code),
    name: code,
    decimalDigits: whole || !hasFraction ? 0 : 2,
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
