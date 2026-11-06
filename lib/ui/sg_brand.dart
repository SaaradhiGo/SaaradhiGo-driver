/// Brand marks (Tier 1): the header lockup (badge, small cut, beside
/// "Saaradhi Go" in Cinzel 600) and the full logo for sign-in and splash.
///
/// The badge and logo assets are DRAFTS from the design handoff
/// (design/logos), to be redrawn by an illustrator; swapping the files in
/// assets/brand/ is all a redraw needs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'sg_text.dart';
import 'sg_tokens.dart';

class SgBrandAssets {
  SgBrandAssets._();

  /// Small cut of the badge (33-95 px; used at 32-48 in headers).
  static String get badgeSmall => SgColors.isDark
      ? badgeSmallGold
      : 'assets/brand/badge-small-deep-gold.svg';

  /// The bright gold cut, for the dark basemap in either theme.
  static const badgeSmallGold = 'assets/brand/badge-small-gold.svg';

  /// Full logo: gold on dark, dark gold on light.
  static String get fullLogo => SgColors.isDark
      ? 'assets/brand/saaradhigo-logo-gold.svg'
      : 'assets/brand/saaradhigo-logo-dark-gold.svg';
}

/// Header lockup: badge + "Saaradhi Go" in gold-text. Scales down, never
/// overflows, when the header is tight.
class SgBrandLockup extends StatelessWidget {
  const SgBrandLockup({
    super.key,
    this.badgeSize = 32,
    this.showName = true,
    this.overDarkMap = false,
  });

  final double badgeSize;
  final bool showName;

  /// Drawn straight on the basemap, which stays dark in both themes: use the
  /// bright gold cut and lettering so it reads at noon too.
  final bool overDarkMap;

  @override
  Widget build(BuildContext context) {
    final badge = SvgPicture.asset(
      overDarkMap ? SgBrandAssets.badgeSmallGold : SgBrandAssets.badgeSmall,
      width: badgeSize,
      height: badgeSize,
      excludeFromSemantics: true,
    );
    return Semantics(
      label: 'Saaradhi Go',
      image: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              if (showName) ...[
                SizedBox(width: badgeSize * 0.25),
                Text(
                  'Saaradhi Go',
                  style: SgText.brandLettering(
                    size: badgeSize * 0.56,
                  ).copyWith(color: overDarkMap ? SgColors.gold500 : null),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The full logo, for the sign-in screen and splash.
class SgFullLogo extends StatelessWidget {
  const SgFullLogo({super.key, this.height = 112});

  final double height;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    SgBrandAssets.fullLogo,
    height: height,
    semanticsLabel: 'Saaradhi Go',
  );
}
