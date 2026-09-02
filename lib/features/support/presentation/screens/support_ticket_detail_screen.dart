import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/support_message_model.dart';
import '../../../../domain/models/support_ticket_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/support_providers.dart';

/// Support Ticket Detail (`/support/ticket/:id`).
///
/// Renders the ticket status header plus the conversation thread between the
/// driver and support. The driver can reply and, once resolved, close the
/// ticket. [SupportTicketDetailNotifier] drives loading/refresh/reply/close.
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(supportTicketDetailNotifierProvider.notifier)
          .open(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(supportTicketDetailNotifierProvider.notifier).sendReply(text);
    _replyController.clear();
  }

  void _confirmClose() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'Close ticket',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          'Closing this ticket ends the conversation. You can open a new one '
          'from Help & Support if the issue is not resolved.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(supportTicketDetailNotifierProvider.notifier)
                  .closeTicket();
            },
            child: Text(
              'Close Ticket',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportTicketDetailNotifierProvider);
    final error = state.errorMessage;
    final ticket = state.ticket;
    final canClose = ticket != null && _isOpenForReplies(ticket.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Ticket #${widget.ticketId}',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onBackground,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (canClose && !state.isClosing)
            TextButton(
              onPressed: _confirmClose,
              child: Text(
                'Close',
                style: AppTypography.labelCaps.copyWith(color: AppColors.error),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(child: _buildBody(state, error)),
    );
  }

  Widget _buildBody(SupportTicketDetailState state, String? error) {
    if (state.isLoading && state.ticket == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null && state.ticket == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
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
                onPressed: () => ref
                    .read(supportTicketDetailNotifierProvider.notifier)
                    .open(widget.ticketId),
              ),
            ],
          ),
        ),
      );
    }

    final ticket = state.ticket;
    if (ticket == null) {
      return const SizedBox.shrink();
    }

    final canReply = _isOpenForReplies(ticket.status);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            onRefresh: () async {
              await ref
                  .read(supportTicketDetailNotifierProvider.notifier)
                  .open(widget.ticketId);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.margin),
              children: [
                if (error != null) ...[
                  GlassPanel(
                    borderColor: AppColors.error.withValues(alpha: 0.4),
                    child: Text(
                      error,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _StatusHeader(ticket: ticket),
                const SizedBox(height: AppSpacing.lg),
                if (ticket.description?.trim().isNotEmpty ?? false)
                  _buildDescription(ticket),
                if (ticket.messages.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final message in ticket.messages)
                    _ThreadBubble(message: message),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (state.isClosing)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        if (canReply)
          _ReplyComposer(
            controller: _replyController,
            isSending: state.isSendingReply,
            onSend: _sendReply,
          ),
      ],
    );
  }

  Widget _buildDescription(SupportTicketModel ticket) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR REPORT',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ticket.description ?? '',
            style: AppTypography.bodyLg.copyWith(color: AppColors.onBackground),
          ),
        ],
      ),
    );
  }

  bool _isOpenForReplies(String? status) {
    final normalized = (status ?? '').toUpperCase();
    switch (normalized) {
      case 'RESOLVED':
      case 'CLOSED':
        return false;
      case 'OPEN':
      case 'IN_PROGRESS':
        return true;
      default:
        // Unknown status from a future backend — allow replying to be safe.
        return status == null || status.trim().isEmpty;
    }
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.ticket});

  final SupportTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final subject = ticket.subject?.trim();
    final category = ticket.category?.trim();
    final title = (subject == null || subject.isEmpty)
        ? (category == null || category.isEmpty ? 'Support Request' : category)
        : subject;
    final status = _normalize(ticket.status);

    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null && category != title) ...[
                  Text(
                    category.toUpperCase(),
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                if (ticket.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(ticket.createdAt!),
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _TicketStatusBadge(status: status, raw: ticket.status),
        ],
      ),
    );
  }

  String _normalize(String? status) => (status ?? '').toUpperCase();

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
    return 'Created on $month ${local.day}, ${local.year}';
  }
}

class _TicketStatusBadge extends StatelessWidget {
  const _TicketStatusBadge({required this.status, required this.raw});

  final String status;
  final String? raw;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'RESOLVED':
      case 'CLOSED':
        return StatusBadge(text: status, status: BadgeStatus.success);
      case 'OPEN':
      case 'IN_PROGRESS':
        return const StatusBadge(
          text: 'IN PROGRESS',
          status: BadgeStatus.pending,
        );
      default:
        final display = (raw == null || raw!.trim().isEmpty)
            ? 'PENDING'
            : status;
        return StatusBadge(text: display);
    }
  }
}

class _ThreadBubble extends StatelessWidget {
  const _ThreadBubble({required this.message});

  final SupportMessageModel message;

  bool get _isDriver => message.senderRole == 'driver';

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            message.body ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final isMine = _isDriver;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLg),
                  topRight: const Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(isMine ? AppSpacing.radiusLg : 4),
                  bottomRight: Radius.circular(
                    isMine ? 4 : AppSpacing.radiusLg,
                  ),
                ),
                border: isMine
                    ? null
                    : Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    isMine ? 'You' : 'Support Agent',
                    style: AppTypography.labelCaps.copyWith(
                      color: isMine
                          ? AppColors.darkText.withValues(alpha: 0.7)
                          : AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.body ?? '',
                    style: AppTypography.bodyLg.copyWith(
                      color: isMine
                          ? AppColors.darkText
                          : AppColors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: AppTypography.dataMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
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
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${months[local.month - 1]} ${local.day}, '
        '$displayHour:$minute $period';
  }
}

class _ReplyComposer extends ConsumerWidget {
  const _ReplyComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm,
        AppSpacing.margin,
        MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onBackground,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a reply…',
                  hintStyle: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        color: AppColors.darkText,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: AppColors.darkText,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
