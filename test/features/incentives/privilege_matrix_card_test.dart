import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaradhigo_driver/core/theme/app_theme.dart';
import 'package:saaradhigo_driver/domain/models/elite_status_model.dart';
import 'package:saaradhigo_driver/features/incentives/presentation/widgets/privilege_matrix_card.dart';

void main() {
  // THE FEE RULE: a commission or fee shown to a driver is the one actually
  // charged. Nothing charges a reduced commission, so the card must not claim
  // one; nothing builds instant payouts either.
  testWidgets('the perks card makes no commission or fee claim', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: PrivilegeMatrixCard(currentTier: EliteTier.diamond),
          ),
        ),
      ),
    );
    expect(find.textContaining('Commission'), findsNothing);
    expect(find.textContaining('commission'), findsNothing);
    expect(find.textContaining('Fee-Free'), findsNothing);
    expect(find.textContaining('10%'), findsNothing);
    expect(find.text('Partner Privileges & Perks'), findsOneWidget);
  });
}
