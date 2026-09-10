import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/chat_message_model.dart';
import '../../../../shared/widgets/buttons.dart';
import '../providers/support_providers.dart';

/// Live passenger chat for one active trip (`/trip-chat/:tripId`).
///
/// Loads the REST history, then attaches the `TripChatConsumer` socket for live
/// delivery. Driver messages render right in gold; passenger lines render left
/// on a raised surface. The floating SOS button stays available here so help is
/// one tap away even while typing.
class TripChatScreen extends ConsumerStatefulWidget {
  const TripChatScreen({super.key, required this.tripId, this.riderName});

  final int tripId;

  /// Display name for the app bar and hints; the dispatch payload carries only
  /// a name — no photo/phone — so we show a glyph avatar like the trip screens.
  final String? riderName;

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _riderLabel {
    final name = widget.riderName?.trim();
    return (name == null || name.isEmpty) ? 'Passenger' : name;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tripChatNotifierProvider.notifier).open(widget.tripId);
    });
  }

  @override
  void dispose() {
    // Tear the socket down for this room; the consumer is created per screen.
    ref.read(tripChatNotifierProvider.notifier).close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? custom]) {
    final text = (custom ?? _messageController.text).trim();
    if (text.isEmpty) return;
    ref.read(tripChatNotifierProvider.notifier).send(text);
    if (custom == null) {
      _messageController.clear();
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(tripChatNotifierProvider);
    final riderName = _riderLabel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'In-trip chat',
                  style: AppTypography.labelCaps.copyWith(
                    color: chat.connecting
                        ? AppColors.secondary
                        : chat.socketError
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Call rider',
            icon: const Icon(Icons.call_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling is not available for this trip yet.'),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(chat, riderName)),
            _buildComposer(chat),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TripChatState chat, String riderName) {
    // Recoverable chat banner (history-load hiccup or a socket `error` frame).
    if (chat.errorMessage != null) {
      return _ChatErrorBanner(
        tripId: widget.tripId,
        message: chat.errorMessage!,
        onDismiss: () =>
            ref.read(tripChatNotifierProvider.notifier).acknowledgeError(),
      );
    }

    if (chat.isLoadingHistory && chat.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (chat.isEmpty) {
      return _EmptyChat(riderName: riderName);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.margin),
      itemCount: chat.messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: _TodayPill(),
            ),
          );
        }
        final message = chat.messages[index - 1];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildComposer(TripChatState chat) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickReply("I've arrived"),
                const SizedBox(width: AppSpacing.sm),
                _buildQuickReply("I'm stuck in traffic"),
                const SizedBox(width: AppSpacing.sm),
                _buildQuickReply('OK'),
                const SizedBox(width: AppSpacing.sm),
                _buildQuickReply('Please wait a moment'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message $_riderLabel…',
                      hintStyle: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: chat.connecting ? null : () => _send(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chat.connecting
                        ? AppColors.outlineVariant
                        : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: chat.connecting
                        ? AppColors.secondaryGray
                        : AppColors.darkText,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () => _send(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        'Today',
        style: AppTypography.labelCaps.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageModel message;

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

    return Align(
      alignment: _isDriver ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: _isDriver
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _isDriver
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLg),
                  topRight: const Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(
                    _isDriver ? AppSpacing.radiusLg : 4,
                  ),
                  bottomRight: Radius.circular(
                    _isDriver ? 4 : AppSpacing.radiusLg,
                  ),
                ),
                border: _isDriver
                    ? null
                    : Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
              ),
              child: Text(
                message.body ?? '',
                style: AppTypography.bodyLg.copyWith(
                  color: _isDriver
                      ? AppColors.darkText
                      : AppColors.onBackground,
                ),
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
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }
}

class _ChatErrorBanner extends ConsumerWidget {
  const _ChatErrorBanner({
    required this.tripId,
    required this.message,
    required this.onDismiss,
  });

  final int tripId;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'RECONNECT',
              onPressed: () {
                onDismiss();
                ref.read(tripChatNotifierProvider.notifier).open(tripId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.riderName});

  final String riderName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Say hello to $riderName',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Messages sent here are visible to your passenger in real time.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
