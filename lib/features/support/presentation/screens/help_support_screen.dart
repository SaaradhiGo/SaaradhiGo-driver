import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/support_ticket_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/support_providers.dart';

/// Help & Support Center (`/support`).
///
/// Lists the driver's support tickets ([SupportTicketsNotifier]) with status
/// badges, pull-to-refresh, empty and error states, and a "Report an Incident"
/// shortcut that creates a new ticket (same backend as raising a ticket).
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(supportTicketsNotifierProvider);
      if (state.tickets.isEmpty && !state.isLoading) {
        ref.read(supportTicketsNotifierProvider.notifier).loadTickets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportTicketsNotifierProvider);

    // Auto-retry a failed ticket-list load when connectivity returns
    // (docs/14_ERROR_HANDLING.md:11). Only an errored list is retried — a
    // healthy (even empty) list is never spammed.
    ref.listen<bool>(isOnlineNetworkProvider, (previous, next) {
      if (previous == true || next != true) return;
      final current = ref.read(supportTicketsNotifierProvider);
      if (current.errorMessage != null &&
          !current.isLoading &&
          !current.isRefreshing) {
        ref.read(supportTicketsNotifierProvider.notifier).loadTickets();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Help & Support',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () =>
              ref.read(supportTicketsNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.margin),
            children: [
              const _SupportBanner(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'My Support Tickets',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'Track the incidents and requests you have raised with our '
                'team.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTicketSection(state),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                text: 'REPORT AN INCIDENT',
                onPressed: () => context.push('/report-incident'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketSection(SupportTicketsState state) {
    final error = state.errorMessage;

    if (error != null) {
      return GlassPanel(
        borderColor: AppColors.error.withValues(alpha: 0.4),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'RETRY',
              onPressed: state.isLoading
                  ? null
                  : () => ref
                        .read(supportTicketsNotifierProvider.notifier)
                        .loadTickets(),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.tickets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.tickets.isEmpty) {
      return GlassPanel(
        child: Column(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.onSurfaceVariant,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No support tickets yet',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'When you report an incident or raise a request, it will appear '
              'here so you can track progress.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final ticket in state.tickets)
          _TicketCard(
            ticket: ticket,
            isRefreshing: state.isRefreshing,
            onTap: () => context.push('/support/ticket/${ticket.id}'),
          ),
      ],
    );
  }
}

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priority 24/7 Support',
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Our team typically replies within 24 hours.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  const _TicketCard({
    required this.ticket,
    required this.onTap,
    this.isRefreshing = false,
  });

  final SupportTicketModel ticket;
  final VoidCallback onTap;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ticket.subject?.trim();
    final category = ticket.category?.trim();
    final label = (subject == null || subject.isEmpty)
        ? (category == null || category.isEmpty ? 'Support Request' : category)
        : subject;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: AppColors.primaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusBadge(status: ticket.status),
                        ],
                      ),
                      if (ticket.createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(ticket.createdAt!),
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isRefreshing) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
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

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    return 'Created $month ${local.day}, ${local.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? '').toUpperCase();
    switch (normalized) {
      case 'RESOLVED':
      case 'CLOSED':
        return StatusBadge(text: normalized, status: BadgeStatus.success);
      case 'IN_PROGRESS':
      case 'OPEN':
        return const StatusBadge(
          text: 'IN PROGRESS',
          status: BadgeStatus.pending,
        );
      default:
        final display = (status == null || status!.trim().isEmpty)
            ? 'UNKNOWN'
            : normalized;
        return StatusBadge(text: display);
    }
  }
}
