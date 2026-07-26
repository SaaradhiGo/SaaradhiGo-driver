import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = 'en',
    this.pushEnabled = true,
  });

  final ThemeMode themeMode;

  /// Phase-0 ships English. Telugu and Hindi are the next two for the
  /// Hyderabad + AP cities; the setting is persisted now so switching later
  /// is a localisation delivery, not a data-model change.
  final String locale;

  final bool pushEnabled;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? pushEnabled,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final store = ref.read(localStoreProvider);
    return SettingsState(
      themeMode: _parseTheme(store.themeMode),
      locale: store.locale,
      pushEnabled: store.pushEnabled,
    );
  }

  static ThemeMode _parseTheme(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(localStoreProvider).setThemeMode(mode.name);
  }

  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await ref.read(localStoreProvider).setLocale(locale);
  }

  /// Local mute only. Safety and payout notifications are not switchable —
  /// the backend's NotificationPreference model refuses to turn those off,
  /// and the app must not imply otherwise.
  Future<void> setPushEnabled(bool enabled) async {
    state = state.copyWith(pushEnabled: enabled);
    await ref.read(localStoreProvider).setPushEnabled(enabled);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
