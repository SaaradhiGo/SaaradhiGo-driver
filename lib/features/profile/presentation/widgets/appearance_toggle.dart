import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/appearance_controller.dart';
import '../../../../ui/sg_l10n.dart';
import '../../../../ui/sg_widgets.dart';

/// The sun/moon button in the home header. It shows what is on screen (a
/// sun by day, a moon at night) and a tap locks the other one; Profile ->
/// Appearance offers Light, Dark and Automatic again. The choice persists.
class AppearanceToggle extends ConsumerWidget {
  const AppearanceToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final dark =
        ref.watch(appearanceControllerProvider).brightness == Brightness.dark;
    return SgMapButton(
      key: const Key('home_theme_toggle'),
      icon: dark ? SgIcons.moon : SgIcons.sun,
      label: l.appearanceToggle(dark ? l.appearanceLight : l.appearanceDark),
      onTap: () => ref
          .read(appearanceControllerProvider.notifier)
          .setMode(dark ? AppearanceMode.light : AppearanceMode.dark),
    );
  }
}
