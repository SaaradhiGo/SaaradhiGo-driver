/// Tolerant JSON decoders shared by domain models that mirror backend money
/// and id fields.
///
/// The API docs state most monetary values arrive as decimal strings
/// (`"1500.00"`), while wallet balances arrive as floats. In practice the
/// earnings endpoints also emit numbers, and a strict `as String` / `as num`
/// cast throws a `TypeError`, which takes the whole earnings dashboard down
/// with it. These converters coerce either representation to the model's
/// declared Dart type instead of crashing.
library;

/// Coerces a JSON value to a fixed-two-decimal money string (`"0.00"` fallback).
String moneyFromJson(dynamic value) {
  if (value == null) return '0.00';
  if (value is num) return value.toStringAsFixed(2);
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? '0.00' : trimmed;
}

/// Coerces a JSON value to a non-null int (`0` fallback).
int intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? 0;
}

/// Coerces a JSON value to a nullable int (`null` fallback).
int? nullableIntFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

/// Coerces a JSON value to a non-null num (`0` fallback).
num numFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString().trim()) ?? 0;
}

/// Coerces a JSON value to a non-null double (`0.0` fallback).
double doubleFromJson(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0.0;
}

/// Coerces a JSON value to a bool (`false` fallback).
bool boolFromJson(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value.toString().trim().toLowerCase() == 'true';
}
