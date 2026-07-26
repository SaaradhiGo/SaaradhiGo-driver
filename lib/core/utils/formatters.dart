import 'package:intl/intl.dart';

/// Display formatting. India-only for Phase-0: INR, `en_IN` grouping
/// (₹1,23,456 — lakh/crore, not thousands), IST-relative dates.
class Fmt {
  const Fmt._();

  static final NumberFormat _rupees = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _rupeesCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Money from the API arrives as a string (`"245.50"`) because the backend
  /// serialises Decimals as strings deliberately — parsing to double and back
  /// is where rounding drift starts. We parse only at the display boundary.
  static double toAmount(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String money(Object? value) => _rupees.format(toAmount(value));

  static String moneyCompact(Object? value) =>
      _rupeesCompact.format(toAmount(value));

  static String distanceKm(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String duration(Duration d) {
    if (d.inHours > 0) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${d.inHours}h ${minutes}m';
    }
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds}s';
  }

  static String clock(DateTime? dt) =>
      dt == null ? '—' : DateFormat('h:mm a').format(dt.toLocal());

  static String dayAndTime(DateTime? dt) =>
      dt == null ? '—' : DateFormat('d MMM, h:mm a').format(dt.toLocal());

  static String day(DateTime? dt) =>
      dt == null ? '—' : DateFormat('d MMM yyyy').format(dt.toLocal());

  static DateTime? parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// "2 minutes ago" — used on the SOS and history lists where absolute
  /// timestamps read as noise.
  static String relative(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return day(dt);
  }

  /// Renders a phone number for display without exposing more than needed in
  /// screenshots or support tickets.
  static String maskedPhone(String? phone) {
    if (phone == null || phone.length < 4) return '—';
    return '${phone.substring(0, phone.length - 4)}••••';
  }

  static String titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
