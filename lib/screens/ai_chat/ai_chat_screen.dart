import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
import '../../widgets/chat/ai_composer.dart';
import '../../widgets/chat/ai_message_bubble.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_empty_state.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  void _showModelSelector(BuildContext context, AiChatProvider ai) {
    final models = ai.availableModels;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.sm),
              child: Text('AI Model',
                  style: AppTypography.heading3(color: textColor)),
            ),
            Divider(height: 0.6, thickness: 0.6, color: border),
            ...models.map((m) {
              final selected = ai.selectedModel == m;
              return InkWell(
                onTap: () {
                  ai.selectModel(m);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m,
                          style: AppTypography.bodyMedium(color: textColor)
                              .copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_rounded,
                            size: 18, color: AppColors.accent)
                      else
                        Icon(Icons.circle_outlined,
                            size: 18, color: mutedColor),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ai = Provider.of<AiChatProvider>(context);
    final chat = ai.activeChat;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: MiraloAppBar(
        leadingIcon: Icons.arrow_back_ios_new,
        leadingTooltip: 'Back',
        onLeadingTap: () => Navigator.pop(context),
        titleWidget: GestureDetector(
          onTap: () => _showModelSelector(context, ai),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(MiraloDimensions.composerRadius),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ai.selectedModel,
                    style: AppTypography.bodySmall(color: textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: textSecondary),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.share_outlined, size: 16, color: textPrimary),
              tooltip: 'Share chat',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Chat link copied.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz, size: 18, color: textPrimary),
              onSelected: (val) {
                if (val == 'delete' && chat != null) {
                  ai.deleteConversation(chat.id);
                  Navigator.pop(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete conversation',
                      style: AppTypography.body(color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: chat == null || chat.messages.isEmpty
                  ? const MiraloEmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Start a conversation',
                      subtitle:
                          'Ask MIRALO AI anything. Your conversation stays private.',
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: chat.messages.length,
                      itemBuilder: (_, i) {
                        final msg = chat.messages[i];
                        return AiMessageBubble(
                          message: msg,
                          onLike: (liked) => ai.likeMessage(msg.id, liked),
                          onRegenerate: i == chat.messages.length - 1
                              ? () => ai.regenerateLast()
                              : null,
                        );
                      },
                    ),
            ),

            // Composer with secret interception
            AiComposer(
              isStreaming: ai.isStreaming,
              onSend: (prompt) => ai.sendPrompt(prompt),
            ),
          ],
        ),
      ),
    );
  }
}
