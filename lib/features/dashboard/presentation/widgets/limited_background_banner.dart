import 'package:flutter/material.dart';

import '../../../../ui/driver_home_view.dart';
import '../../../../ui/sg_l10n.dart';
import 'background_location_disclosure_sheet.dart';

/// Shown on the home when the driver is online with foreground-only location.
class LimitedBackgroundBanner extends StatelessWidget {
  const LimitedBackgroundBanner({super.key});

  @override
  Widget build(BuildContext context) => HomeNotice(
    sgL10n(context).homeNoticeLimitedBackground,
    actionLabel: sgL10n(context).homeNoticeUpgrade,
    onAction: () => BackgroundLocationDisclosureSheet.show(context),
  );
}