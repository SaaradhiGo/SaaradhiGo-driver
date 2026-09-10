import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_provider.dart';
import 'offline_banner.dart';

/// App-wide wrapper placed as `MaterialApp.builder`.
///
/// Watches platform connectivity and, while the device is offline, renders the
/// persistent "No Internet Connection. Retrying…" strip above every route
/// (docs/14_ERROR_HANDLING.md:11) without losing the active route's state.
///
/// Layout keeps the Navigator in a constant parent/child position — the banner
/// slot is always present (it just collapses to zero height online) — so toggling
/// connectivity never destroys the current route stack.
class AppConnectivityHost extends ConsumerWidget {
  const AppConnectivityHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineNetworkProvider);

    // While offline the banner owns the status-bar inset; hand the Navigator a
    // top-padding-free MediaQuery so child Scaffolds/AppBars do not double-pad.
    final media = MediaQuery.of(context);
    final navigatorMedia = online
        ? media
        : media.copyWith(
            padding: media.padding.copyWith(top: 0),
            viewPadding: media.viewPadding.copyWith(top: 0),
          );

    return Column(
      children: [
        _BannerSlot(showBanner: !online),
        Expanded(
          child: MediaQuery(data: navigatorMedia, child: child),
        ),
      ],
    );
  }
}

class _BannerSlot extends StatelessWidget {
  const _BannerSlot({required this.showBanner});

  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    // Return the same widget type at this position regardless of state so the
    // element (and the sibling Navigator below) is preserved across toggles.
    if (!showBanner) return const SizedBox.shrink();
    return const OfflineBanner();
  }
}
