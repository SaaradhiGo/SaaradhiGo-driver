import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/network/connectivity_provider.dart';
import 'package:saaradhigo_driver/shared/widgets/app_connectivity_host.dart';
import 'package:saaradhigo_driver/shared/widgets/offline_banner.dart';

void main() {
  Widget harness(bool online) => ProviderScope(
    overrides: [isOnlineNetworkProvider.overrideWithValue(online)],
    child: MaterialApp(
      builder: (context, child) =>
          AppConnectivityHost(child: child ?? const SizedBox.shrink()),
      home: const Scaffold(body: Center(child: Text('ROUTE'))),
    ),
  );

  testWidgets('hides the offline banner when online', (tester) async {
    await tester.pumpWidget(harness(true));
    expect(find.byType(OfflineBanner), findsNothing);
    expect(find.text('ROUTE'), findsOneWidget);
  });

  testWidgets('shows the persistent banner while offline', (tester) async {
    await tester.pumpWidget(harness(false));
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.textContaining('No Internet Connection'), findsOneWidget);
    // Route content is still present (no blank screen).
    expect(find.text('ROUTE'), findsOneWidget);
  });

  testWidgets('keeps the route tree when connectivity toggles', (tester) async {
    await tester.pumpWidget(harness(true));
    expect(find.text('ROUTE'), findsOneWidget);

    await tester.pumpWidget(harness(false));
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('ROUTE'), findsOneWidget);

    await tester.pumpWidget(harness(true));
    expect(find.byType(OfflineBanner), findsNothing);
    expect(find.text('ROUTE'), findsOneWidget);
  });
}
