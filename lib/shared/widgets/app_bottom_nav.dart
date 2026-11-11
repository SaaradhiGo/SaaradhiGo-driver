import 'package:flutter/material.dart';

import 'package:saaradhigo_driver/ui/sg_l10n.dart';
import 'package:saaradhigo_driver/ui/sg_text.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';
import 'package:saaradhigo_driver/ui/sg_widgets.dart';

/// Item metadata for the main driver bottom navigation bar.
class AppBottomNavItemData {
  const AppBottomNavItemData({
    required this.route,
    required this.icon,
    required this.label,
  });

  final String route;

  /// SVG path body (24x24, stroked), as in the designs.
  final String icon;
  final String label;
}

/// The driver tab bar (signed-in designs, 2026-11-08): Home, Earnings, Trips,
/// Documents on the dark sheet colour, gold for the active tab. It continues
/// the Home sheet, so the two read as one surface.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<AppBottomNavItemData> items = [
    AppBottomNavItemData(
      route: '/',
      icon: '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>',
      label: 'Home',
    ),
    AppBottomNavItemData(
      route: '/earnings',
      icon: '<rect x="3" y="6" width="18" height="14" rx="2"/>'
          '<path d="M3 10h18M16 15h2"/>',
      label: 'Earnings',
    ),
    AppBottomNavItemData(
      route: '/history',
      icon: '<path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"/>',
      label: 'Trips',
    ),
    AppBottomNavItemData(
      route: '/documents',
      icon: '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 '
          '2-2V9z"/><path d="M14 3v6h6"/>',
      label: 'Documents',
    ),
  ];

  /// The tab's label in the app's language; [items] keeps the English.
  static String _label(AppLocalizations l, AppBottomNavItemData item) =>
      switch (item.route) {
        '/' => l.navHome,
        '/history' => l.navTrips,
        '/earnings' => l.navEarnings,
        '/documents' => l.navDocuments,
        _ => item.label,
      };

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      key: const Key('driver_tab_bar'),
      color: SgNoir.sheet,
      padding: EdgeInsets.fromLTRB(
        SgSpace.s2,
        SgSpace.s1,
        SgSpace.s2,
        SgSpace.s3 + bottomInset,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _Tab(
                key: ValueKey(items[i].route),
                icon: items[i].icon,
                label: _label(l, items[i]),
                active: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? SgNoir.gold : SgNoir.inkMuted;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SgIcon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SgText.small.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
