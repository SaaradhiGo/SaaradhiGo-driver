/// The driver app's own chrome (signed-in designs, 2026-11-08): a dark top bar
/// with the badge and a DRIVER pill, the same in both themes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'sg_brand.dart';
import 'sg_l10n.dart';
import 'sg_text.dart';
import 'sg_tokens.dart';
import 'sg_widgets.dart';

/// 72px dark bar under the status bar. Home: logo, DRIVER, menu on the right.
/// A tab: [title] (and a back chevron when [onBack] is set).
class DriverTopBar extends StatelessWidget {
  const DriverTopBar({super.key, this.title, this.onMenu, this.onBack});

  final String? title;
  final VoidCallback? onMenu;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = sgL10n(context);
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      key: const Key('driver_top_bar'),
      color: SgNoir.bar,
      padding: EdgeInsets.only(top: top, left: SgSpace.s4, right: SgSpace.s4),
      height: 72 + top,
      child: Row(
        children: [
          if (onBack != null) ...[
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              child: InkWell(
                onTap: onBack,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SgIcon(SgIcons.back, color: SgNoir.ink),
                  ),
                ),
              ),
            ),
          ],
          if (title != null)
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SgText.title.copyWith(color: SgNoir.ink),
              ),
            )
          else ...[
            Semantics(
              label: 'SaaradhiGo',
              image: true,
              child: SvgPicture.asset(
                SgBrandAssets.badgeSmallGold,
                width: 44,
                height: 39,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              key: const Key('driver_badge'),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SgNoir.amber,
                borderRadius: BorderRadius.circular(SgRadius.pill),
              ),
              child: Text(
                l.shellDriverBadge,
                style: SgText.small.copyWith(
                  color: SgNoir.onAmber,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const Spacer(),
          ],
          if (onMenu != null)
            Semantics(
              button: true,
              label: l.commonMenu,
              excludeSemantics: true,
              child: InkWell(
                key: const Key('driver_menu'),
                customBorder: const CircleBorder(),
                onTap: onMenu,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SgNoir.line),
                  ),
                  child: Center(
                    child: SgIcon(
                      '<path d="M4 7h16M4 12h16M4 17h16"/>',
                      color: SgNoir.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A warn card under the top bar: bold line, muted line, chevron.
class DriverWarnCard extends StatelessWidget {
  const DriverWarnCard({
    super.key,
    required this.title,
    this.body,
    this.onTap,
  });

  final String title;
  final String? body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: SgStatus.warnBg,
    borderRadius: BorderRadius.circular(SgRadius.md),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SgRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SgRadius.md),
          border: Border.all(color: SgStatus.warnLine),
        ),
        child: Row(
          children: [
            SgIcon(
              '<circle cx="12" cy="12" r="9"/><path d="M12 7v6M12 16h.01"/>',
              color: SgStatus.warnInk,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SgText.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SgColors.ink,
                    ),
                  ),
                  if (body != null)
                    Text(
                      body!,
                      style: SgText.small.copyWith(color: SgColors.inkMuted),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              SgIcon('<path d="M9 18l6-6-6-6"/>', color: SgColors.ink),
          ],
        ),
      ),
    ),
  );
}
