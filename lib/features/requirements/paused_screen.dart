import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/market/market_providers.dart';
import '../../ui/sg_format.dart';
import '../../ui/sg_l10n.dart';
import '../../ui/sg_text.dart';
import '../../ui/sg_tokens.dart';
import '../../ui/sg_widgets.dart';
import 'requirements_api.dart';

/// `/paused` (14 Nov, owner): a paused driver reads why, what to do and how to
/// reach support. The router keeps them off Home, so they cannot go online.
class PausedScreen extends ConsumerWidget {
  const PausedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = sgL10n(context);
    final r = ref.watch(requirementsProvider).asData?.value;
    final paused = r?.paused;
    final phone = ref.watch(marketConfigProvider).supportPhone;
    final closed = paused?.permanent == true;
    final since = paused?.since;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: SgSpace.s4, bottom: SgSpace.s1),
      child: Text(
        text,
        style: SgText.body.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    return Scaffold(
      backgroundColor: SgColors.bg000,
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(requirementsProvider.future),
          child: ListView(
            key: const Key('paused_screen'),
            padding: const EdgeInsets.all(SgSpace.s5),
            children: [
              Text(
                closed ? l.pausedClosedTitle : l.pausedTitle,
                key: const Key('paused_title'),
                style: SgText.title,
              ),
              if (paused != null) ...[
                heading(l.pausedWhy),
                Text(
                  paused.reason,
                  key: const Key('paused_reason'),
                  style: SgText.body,
                ),
                if (since != null)
                  Padding(
                    padding: const EdgeInsets.only(top: SgSpace.s1),
                    child: Text(
                      l.pausedSince(sgMarketDate(since.toLocal(), r?.country)),
                      key: const Key('paused_since'),
                      style: SgText.small.copyWith(color: SgColors.inkMuted),
                    ),
                  ),
              ],
              heading(l.pausedWhatToDo),
              Text(
                closed ? l.pausedClosedBody : l.pausedWhatToDoBody,
                style: SgText.body,
              ),
              const SizedBox(height: SgSpace.s5),
              SgPrimaryButton(
                key: const Key('paused_support'),
                label: l.pausedContactSupport,
                onPressed: () => context.push('/support'),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: SgSpace.s2),
                OutlinedButton(
                  key: const Key('paused_call'),
                  onPressed: () => launchUrl(
                    Uri(scheme: 'tel', path: phone),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(l.pausedCallSupport),
                ),
              ],
              const SizedBox(height: SgSpace.s2),
              TextButton(
                key: const Key('paused_earnings'),
                onPressed: () => context.go('/earnings'),
                child: Text(l.navEarnings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
