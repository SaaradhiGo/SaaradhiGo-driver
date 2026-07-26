import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../duty/presentation/duty_controller.dart';
import '../../trip/presentation/trip_controller.dart';
import '../domain/safety_repository.dart';

@immutable
class SosState {
  const SosState({this.isSending = false, this.raisedId, this.error});

  final bool isSending;

  /// Non-null once ops has the event. The UI switches to "help is on the
  /// way" on this, not on the button tap.
  final int? raisedId;
  final Object? error;

  bool get isRaised => raisedId != null;
}

/// Raises an SOS.
///
/// Attaches the live trip id and the last GPS fix without asking the driver
/// for anything: someone pressing this button is in trouble and should not be
/// filling in a form. The server acknowledges in about a second and fans out
/// push + SMS asynchronously.
class SosController extends Notifier<SosState> {
  @override
  SosState build() => const SosState();

  Future<bool> raise({String eventType = 'panic', String? note}) async {
    state = const SosState(isSending: true);
    try {
      final position = ref.read(dutyControllerProvider).lastPosition;
      final trip = ref.read(tripControllerProvider).trip;

      final id = await ref.read(safetyRepositoryProvider).raiseSos(
            eventType: eventType,
            tripId: trip?.id,
            lat: position?.latitude,
            lng: position?.longitude,
            accuracyM: position?.accuracy,
            note: note,
          );
      state = SosState(raisedId: id);
      return true;
    } on Object catch (e) {
      state = SosState(error: e);
      return false;
    }
  }

  void reset() => state = const SosState();
}

final sosControllerProvider =
    NotifierProvider<SosController, SosState>(SosController.new);

final supportTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicket>>((ref) {
  return ref.watch(safetyRepositoryProvider).fetchTickets();
});

final supportTicketProvider =
    FutureProvider.autoDispose.family<SupportTicket, int>((ref, id) {
  return ref.watch(safetyRepositoryProvider).fetchTicket(id);
});
