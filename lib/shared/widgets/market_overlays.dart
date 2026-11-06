import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/market/app_headers_interceptor.dart';
import '../../core/market/market_config.dart';
import '../../core/market/market_config_store.dart';
import '../../core/theme/app_colors.dart';
import 'package:saaradhigo_driver/ui/sg_tokens.dart';

/// Blocking screen for 426 APP_UPDATE_REQUIRED. Shown instead of the app; the
/// only way forward is the store link from the response body.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.info, this.onOpenStore});

  final UpdateRequired info;
  final Future<void> Function(String url)? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final url = info.storeUrl;
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update, color: AppColors.primaryText, size: 56),
                const SizedBox(height: 24),
                Text(
                  'Update required',
                  key: Key('update_required_title'),
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  info.message ?? 'Please update the app to continue.',
                  key: const Key('update_required_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryGray,
                    fontSize: 16,
                  ),
                ),
                if (url != null) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('update_required_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.darkText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (onOpenStore != null) {
                          await onOpenStore!(url);
                        } else {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Active maintenance / info notices from app-config. Dismissible unless the
/// notice says it blocks. No notices => renders nothing.
class NoticeBanner extends StatefulWidget {
  const NoticeBanner({super.key, required this.notices});

  final List<AppNotice> notices;

  @override
  State<NoticeBanner> createState() => _NoticeBannerState();

  @visibleForTesting
  static void resetDismissed() => _NoticeBannerState._dismissed.clear();
}

class _NoticeBannerState extends State<NoticeBanner> {
  // Dismissed for this app session; a notice comes back on the next launch.
  static final Set<int> _dismissed = <int>{};

  @override
  Widget build(BuildContext context) {
    final visible = widget.notices
        .where((n) => n.blocking || !_dismissed.contains(n.id))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final n in visible)
          Material(
            key: Key('notice_${n.id}'),
            color: n.severity == 'warning'
                ? SgColors.gold500
                : SgColors.bg300,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                8,
                8,
              ),
              child: Row(
                children: [
                  Icon(
                    n.severity == 'warning'
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                    color: n.severity == 'warning' ? SgColors.onGold : SgColors.ink,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      n.message,
                      style: TextStyle(color: n.severity == 'warning' ? SgColors.onGold : SgColors.ink, fontSize: 13),
                    ),
                  ),
                  if (!n.blocking)
                    IconButton(
                      key: Key('notice_dismiss_${n.id}'),
                      icon: Icon(
                        Icons.close,
                        color: n.severity == 'warning' ? SgColors.onGold : SgColors.ink,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _dismissed.add(n.id)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Wraps the routed app: blocking update screen, and notices at the top.
/// Sits in MaterialApp.router(builder: ...).
class MarketOverlays extends StatelessWidget {
  const MarketOverlays({
    super.key,
    required this.child,
    this.update,
    this.market,
  });

  final Widget child;
  final UpdateRequiredState? update;
  final MarketConfigStore? market;

  @override
  Widget build(BuildContext context) {
    final u = update ?? UpdateRequiredState.instance;
    final m = market ?? MarketConfigStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([u, m]),
      builder: (context, _) {
        final info = u.info;
        final media = MediaQuery.of(context);
        final hasNotices = m.current.notices.isNotEmpty;
        // The structure is the same whether or not there is a notice (or an
        // update screen), so the app's Navigator is never re-parented and keeps
        // its state. The banner takes its height from the top and the app gets
        // the rest; the update screen is stacked over the app, not instead of it.
        return Stack(
          children: [
            Offstage(
              offstage: info != null,
              child: Column(
                children: [
                  NoticeBanner(notices: m.current.notices),
                  Expanded(
                    child: MediaQuery(
                      data: hasNotices
                          ? media.copyWith(
                              padding: media.padding.copyWith(top: 0),
                              viewPadding: media.viewPadding.copyWith(top: 0),
                            )
                          : media,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
            if (info != null) UpdateRequiredScreen(info: info),
          ],
        );
      },
    );
  }
}
