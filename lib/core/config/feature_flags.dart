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
  final raw = dotenv.maybeGet(key);
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
