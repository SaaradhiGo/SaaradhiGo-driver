/// Display helpers for the earnings screens.
///
/// The fee rule: the app shows the commission rate and any fee exactly as the
/// API returned it. A value the API did not send is not shown at all. There is
/// no fallback rate and no "0.00" stand-in.
library;

import '../../../core/market/market_config_store.dart';

/// "15%" for a rate the API sent, or null when it did not.
///
/// When the settlements in the period were charged at different rates the API
/// sets `commission_percent_mixed` and sends the effective rate, so the label
/// says "avg".
String? commissionRateLabel(num? percent, {bool? mixed}) {
  if (percent == null) return null;
  final text = percent == percent.roundToDouble()
      ? percent.toInt().toString()
      : percent.toString();
  return mixed == true ? '$text% avg' : '$text%';
}

/// Net earnings as a 2-decimal string, or null when either side is unknown.
String? netFromGrossAndCommission(String? gross, String? commission) {
  final g = _parse(gross);
  final c = _parse(commission);
  if (g == null || c == null) return null;
  return (g - c).toStringAsFixed(2);
}

/// Average net per trip, or null when it cannot be computed honestly.
String? averageNetPerTrip(String? net, int trips) {
  final n = _parse(net);
  if (n == null || trips <= 0) return null;
  return (n / trips).toStringAsFixed(0);
}

double? _parse(String? raw) {
  if (raw == null) return null;
  return double.tryParse(MarketConfigStore.instance.current.stripSymbol(raw));
}

/// True when the API sent an amount and it is above zero. The money-phase lines
/// (promo paid by SaaradhiGo, rewards, tax and fees collected) are hidden for an
/// absent or zero value, so a market or a period with none looks exactly as it
/// did before they existed.
bool isPositiveAmount(String? raw) {
  final v = _parse(raw);
  return v != null && v > 0;
}

/// The words under a reward line: no commission, tax not configured, paid in
/// the weekly payout. The first two are the API's own values
/// (`incentive_commission`, `incentive_tax`); the payout line is fixed policy.
String rewardNote({String? commission, String? tax}) {
  final parts = <String>[
    if (commission != null && commission.trim().isNotEmpty)
      commission.trim().toLowerCase() == 'none'
          ? 'No commission'
          : 'Commission: ${commission.trim()}',
    if (tax != null && tax.trim().isNotEmpty) 'Tax: ${tax.trim()}',
    'Paid in your weekly payout',
  ];
  return parts.join(' \u00b7 ');
}
