import 'package:flutter/material.dart';

import '../../../../ui/driver_home_view.dart';
import 'background_location_disclosure_sheet.dart';

/// Shown on the home when the driver is online with foreground-only location.
class LimitedBackgroundBanner extends StatelessWidget {
  const LimitedBackgroundBanner({super.key});

  @override
  Widget build(BuildContext context) => HomeNotice(
    'Keep the app open to receive rides, or allow background location.',
    actionLabel: 'Upgrade',
    onAction: () => BackgroundLocationDisclosureSheet.show(context),
  );
}