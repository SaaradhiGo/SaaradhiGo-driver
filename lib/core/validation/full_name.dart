/// The driver's full name, as the sign-up asks for it: trimmed, at least two
/// characters, letters (any script), combining marks, spaces and . ' - only.
library;

final RegExp _allowed = RegExp(r"^[\p{L}\p{M} .'’-]+$", unicode: true);
final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);

/// Null when [value] is acceptable, else the message to show under the field.
String? validateFullName(String? value) {
  final name = (value ?? '').trim();
  if (name.isEmpty) return 'Enter your full name';
  if (name.length < 2) return 'Name must be at least 2 characters';
  if (!_allowed.hasMatch(name) || !_hasLetter.hasMatch(name)) {
    return "Use letters, spaces and . ' - only";
  }
  return null;
}

/// True when the profile carries a usable name. The backend's own check
/// (has_real_name) also refuses a phone number or an email standing in for one.
bool hasUsableName(String? value) {
  final name = (value ?? '').trim();
  if (name.isEmpty || name.contains('@')) return false;
  return RegExp(r'[^0-9+\- ]').hasMatch(name);
}
