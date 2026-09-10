import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/data_sources/support_remote_data_source.dart';
import '../../data/data_sources/trip_chat_consumer.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../domain/repositories/support_repository.dart';
import 'sos_notifier.dart';
import 'support_state.dart';
import 'support_tickets_notifier.dart';
import 'support_ticket_detail_notifier.dart';
import 'trip_chat_notifier.dart';
import 'trip_chat_state.dart';

export 'sos_notifier.dart';
export 'support_state.dart';
export 'support_tickets_notifier.dart';
export 'support_ticket_detail_notifier.dart';
export 'trip_chat_notifier.dart';
export 'trip_chat_state.dart';

/// Builds a [TripChatConsumer] bound to a specific trip. A factory because a
/// consumer is created per open chat screen and torn down on close; overridden
/// in tests to inject a fake.
typedef TripChatConsumerFactory = TripChatConsumer Function(int tripId);

final supportRemoteDataSourceProvider = Provider<SupportRemoteDataSource>((
  ref,
) {
  return SupportRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(ref.watch(supportRemoteDataSourceProvider));
});

final tripChatConsumerFactoryProvider = Provider<TripChatConsumerFactory>((
  ref,
) {
  return (tripId) => TripChatConsumer(
    tripId: tripId,
    tokenReader: SecureStorageService.getAccessToken,
  );
});

/// One live chat session per open screen instance. The screen calls
/// [TripChatNotifier.open] with its trip id; tests can override the factory.
final tripChatNotifierProvider =
    NotifierProvider<TripChatNotifier, TripChatState>(TripChatNotifier.new);

final supportTicketsNotifierProvider =
    NotifierProvider<SupportTicketsNotifier, SupportTicketsState>(
      SupportTicketsNotifier.new,
    );

final supportTicketDetailNotifierProvider =
    NotifierProvider<SupportTicketDetailNotifier, SupportTicketDetailState>(
      SupportTicketDetailNotifier.new,
    );

final sosNotifierProvider = NotifierProvider<SosNotifier, SosState>(
  SosNotifier.new,
);

/// Exposes the currently known emergency contact. Watches the driver profile
/// (server-authoritative) and falls back to the auth user when the profile has
/// not loaded it yet.
final emergencyContactProvider = Provider<String>((ref) {
  final profileState = ref.watch(driverProfileNotifierProvider);
  final emergency = profileState.maybeMap(
    loaded: (s) => s.profile.user?.emergencyContact,
    orElse: () => null,
  );
  if (emergency != null && emergency.trim().isNotEmpty) return emergency;
  final authState = ref.watch(authNotifierProvider);
  final authEmergency = authState is AuthAuthenticated
      ? authState.user?.emergencyContact
      : null;
  if (authEmergency != null && authEmergency.trim().isNotEmpty) {
    return authEmergency;
  }
  return '';
});
