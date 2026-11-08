import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags resolved from environment configuration (.env).
///
/// Flags are read lazily via [Provider] so tests can override them with
/// `ProviderScope(overrides: [...])` without touching dotenv.
final presignedUploadsFlagProvider = Provider<bool>((ref) {
  return _readBoolFlag('PRESIGNED_UPLOADS', defaultValue: true);
});

bool _readBoolFlag(String key, {required bool defaultValue}) {
  // dotenv may never have been initialised -- `.env` is not a bundled asset
  // any more, so a device build has nothing to load. An uninitialised
  // `maybeGet` throws, which would have taken out every flag read.
  final raw = _rawFlag(key);
  if (raw == null || raw.trim().isEmpty) {
    return defaultValue;
  }
  final normalized = raw.trim().toLowerCase();
  if (normalized == '1' || normalized == 'true') {
    return true;
  }
  if (normalized == '0' || normalized == 'false') {
    return false;
  }
  return defaultValue;
}

/// The raw flag value from dotenv, or null. Never throws.
String? _rawFlag(String key) {
  try {
    return dotenv.isInitialized ? dotenv.maybeGet(key) : null;
  } on Object {
    return null;
  }
}

/// Signed-in designs (2026-11-08): parts of the driver earnings design that
/// wait on the API or on a product decision. All off.
class DriverDesignFlags {
  DriverDesignFlags._();

  /// "Tips" row: needs a tips amount from the earnings API (none today).
  static const tipsRow = false;

  /// "Withdraw ₹X" button: no new in-app money flow tonight; the existing
  /// withdrawal screen stays under "All earnings and payouts".
  static const withdrawButton = false;

  /// "To bank account ending 1234": needs the payout account's last digits
  /// from the balance API.
  static const bankLast4 = false;
}
