import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi, I\'m waiting near the north gate of the mall.',
      'time': '10:42 AM',
      'isDriver': false,
    },
    {
      'text': 'Got it. I\'m taking the turn now, will be there in 2 mins.',
      'time': '10:43 AM',
      'isDriver': true,
    },
    {
      'text': 'Great, I\'m wearing a blue jacket.',
      'time': '10:44 AM',
      'isDriver': false,
    },
  ];

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'time': '10:45 AM',
        'isDriver': true,
      });
    });

    if (customText == null) {
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Ananya S.',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.primary),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.errorContainer.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.sos, color: AppColors.onErrorContainer, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.containerMargin),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Today',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  final msg = _messages[index - 1];
                  final isDriver = msg['isDriver'] as bool;

                  return Align(
                    alignment: isDriver ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.stackMd),
                            decoration: BoxDecoration(
                              color: isDriver
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isDriver ? 16 : 4),
                                bottomRight: Radius.circular(isDriver ? 4 : 16),
                              ),
                              border: isDriver
                                  ? null
                                  : Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Text(
                              msg['text'],
                              style: AppTypography.bodyLg.copyWith(
                                color: isDriver ? AppColors.onPrimary : AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'],
                            style: AppTypography.dataMono.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Replies & Message Input
            GlassPanel(
              borderRadius: 0,
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick reply chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickReply("I've arrived"),
                        const SizedBox(width: 8),
                        _buildQuickReply("I'm stuck in traffic"),
                        const SizedBox(width: 8),
                        _buildQuickReply("OK"),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),

                  // Text field and send button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Message Ananya...',
                              hintStyle: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send, color: AppColors.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
