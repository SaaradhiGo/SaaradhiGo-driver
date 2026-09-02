import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/sos_alert_model.dart';
import '../../../../domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_providers.dart';

/// Drives the SOS trigger and the single trusted emergency contact (Safety
/// Center). [raiseSos] posts the alert (optionally tied to an active trip) at
/// the driver's current coordinates; [updateEmergencyContact] persists the
/// contact through `PATCH /auth/update/` and mirrors it into the live auth
/// state + secure storage so it is reflected immediately everywhere the
/// emergency-contact provider reads it.
class SosNotifier extends Notifier<SosState> {
  late SupportRepository _repository;

  @override
  SosState build() {
    _repository = ref.watch(supportRepositoryProvider);
    return const SosState();
  }

  /// Posts an SOS alert for [tripId] (when one is active) at the supplied
  /// [latitude]/[longitude]. On success the confirmation message is shown.
  Future<void> raiseSos({
    int? tripId,
    required double latitude,
    required double longitude,
  }) async {
    if (state.isRaising) return;
    state = state.copyWith(isRaising: true, errorMessage: null);
    try {
      final alert = await _repository.raiseSos(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
      );
      state = SosState(
        confirmationMessage: _confirmationFor(alert),
        contactSavedMessage: null,
      );
    } catch (e) {
      AppLogger.w('SOS raise failed', e);
      state = state.copyWith(
        isRaising: false,
        errorMessage:
            'Could not send the alert. Please call the local '
            'emergency number and try again.',
      );
    }
  }

  /// Saves [value] as the driver's single emergency contact. Backend success is
  /// authoritative; the auth user state is updated locally (without waiting for
  /// a profile round-trip) so the saved value is immediately visible.
  Future<void> updateEmergencyContact(String value) async {
    if (state.isSavingContact) return;
    final trimmed = value.trim();
    state = state.copyWith(
      isSavingContact: true,
      errorMessage: null,
      contactSavedMessage: null,
    );
    try {
      await _repository.updateEmergencyContact(trimmed);
      await _mirrorEmergencyContactIntoAuth(trimmed);
      state = state.copyWith(
        isSavingContact: false,
        contactSavedMessage: 'Emergency contact saved.',
      );
    } catch (e) {
      AppLogger.w('Emergency contact save failed', e);
      state = state.copyWith(
        isSavingContact: false,
        errorMessage: 'Could not save the emergency contact. Try again.',
      );
    }
  }

  Future<void> _mirrorEmergencyContactIntoAuth(String value) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final current = authState.user;
    if (current == null) return;
    final updated = UserModel(
      id: current.id,
      phoneNumber: current.phoneNumber,
      role: current.role,
      fullName: current.fullName,
      email: current.email,
      avatar: current.avatar,
      isUpdated: current.isUpdated,
      fcmToken: current.fcmToken,
      emergencyContact: value,
    );
    await ref.read(authNotifierProvider.notifier).updateUser(updated);
  }

  String _confirmationFor(SosAlertModel alert) {
    final alertId = alert.id > 0 ? '#${alert.id}' : '';
    final base =
        'Your alert was sent to our safety team. '
        'Help is on the way.';
    return alertId.isEmpty ? base : '$base (Reference $alertId)';
  }

  void acknowledgeError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void clearConfirmation() {
    if (state.confirmationMessage == null &&
        state.contactSavedMessage == null) {
      return;
    }
    state = state.copyWith(
      confirmationMessage: null,
      contactSavedMessage: null,
    );
  }
}
