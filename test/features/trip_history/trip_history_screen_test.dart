import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/domain/models/trip_model.dart';
import 'package:saaradhigo_driver/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/providers/trip_history_providers.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/screens/trip_history_screen.dart';
import 'package:saaradhigo_driver/features/trip_history/presentation/widgets/trip_history_card.dart';

class FakeTripHistoryRepository implements TripHistoryRepository {
  List<TripModel> trips = [
    const TripModel(
      id: 1,
      status: TripStatus.completed,
      riderName: 'Rahul Sharma',
      finalFare: '480',
      pickupAddress: 'Taj Mahal Palace',
      destinationAddress: 'BKC',
      distanceKm: 8.4,
      durationMin: 22,
    ),
    const TripModel(
      id: 2,
      status: TripStatus.cancelled,
      riderName: 'Priya Desai',
      pickupAddress: 'Andheri West',
      destinationAddress: 'Juhu Beach',
      cancellationReason: 'Rider cancelled',
    ),
  ];

  @override
  Future<List<TripModel>> getDriverHistory({
    String? status,
    DateTimeRange? dateRange,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (status == 'completed') {
      return trips.where((t) => t.status == TripStatus.completed).toList();
    }
    if (status == 'cancelled') {
      return trips.where((t) => t.status == TripStatus.cancelled).toList();
    }
    return trips;
  }

  @override
  Future<TripModel> getTripDetails(int tripId) async {
    return trips.firstWhere((t) => t.id == tripId);
  }
}

Widget _buildHarness(FakeTripHistoryRepository repository) {
  return ProviderScope(
    overrides: [tripHistoryRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: TripHistoryScreen()),
  );
}

void main() {
  testWidgets('renders trips, header, and filter chips', (tester) async {
    final repo = FakeTripHistoryRepository();

    await tester.pumpWidget(_buildHarness(repo));
    await tester.pumpAndSettle();

    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Date Range'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Cancelled'), findsNWidgets(2));

    expect(find.byType(TripHistoryCard), findsNWidgets(2));
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Priya Desai'), findsOneWidget);
    expect(find.text('₹480'), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget);
  });

  testWidgets('filters list when tapping Completed chip', (tester) async {
    final repo = FakeTripHistoryRepository();

    await tester.pumpWidget(_buildHarness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();

    expect(find.byType(TripHistoryCard), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Priya Desai'), findsNothing);
  });

  testWidgets('renders empty state when no trips match filter', (tester) async {
    final repo = FakeTripHistoryRepository();
    repo.trips = [];

    await tester.pumpWidget(_buildHarness(repo));
    await tester.pumpAndSettle();

    expect(find.byType(TripHistoryCard), findsNothing);
    expect(find.text('No Recent Trips'), findsOneWidget);
  });
}
