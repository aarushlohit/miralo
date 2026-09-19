import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../providers/ai_chat_provider.dart';
import '../../widgets/chat/ai_message_bubble.dart';
import '../../widgets/chat/chat_header.dart';
import '../../widgets/chat/chat_scaffold.dart';
import '../../widgets/chat/composer.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/common/miralo_empty_state.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  void _showModelSelector(BuildContext context, AiChatProvider ai) {
    final models = ai.availableModels;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MiraloColors.darkSurfacePrimary
        : MiraloColors.lightSurfacePrimary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;
    final textColor = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final mutedColor = isDark
        ? MiraloColors.darkTextMuted
        : MiraloColors.lightTextMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MiraloRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: MiraloSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MiraloSpacing.lg,
                0,
                MiraloSpacing.lg,
                MiraloSpacing.sm,
              ),
              child: Text(
                'AI Model',
                style: MiraloTypography.titleMedium(color: textColor),
              ),
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
                    horizontal: MiraloSpacing.lg,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m,
                          style: MiraloTypography.bodyMedium(color: textColor)
                              .copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_rounded,
                            size: 18, color: MiraloColors.accent)
                      else
                        Icon(Icons.circle_outlined,
                            size: 18, color: mutedColor),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: MiraloSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, AiChatProvider ai) {
    final chat = ai.activeChat;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MiraloColors.darkSurfacePrimary
        : MiraloColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MiraloRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MiraloSpacing.lg,
            vertical: MiraloSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: textPrimary, size: 22),
                title: Text(
                  'Share conversation',
                  style: MiraloTypography.bodyMedium(color: textPrimary),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation link copied.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              if (chat != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: MiraloColors.danger, size: 22),
                  title: Text(
                    'Delete conversation',
                    style: MiraloTypography.bodyMedium(
                        color: MiraloColors.danger),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    ai.deleteConversation(chat.id);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: MiraloSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = Provider.of<AiChatProvider>(context);
    final chat = ai.activeChat;

    return ChatScaffold(
      header: ChatHeader(
        isPrivate: false,
        modelName: ai.selectedModel,
        onBack: () => Navigator.pop(context),
        onModelSelectorTap: () => _showModelSelector(context, ai),
        onMoreOptions: () => _showMoreMenu(context, ai),
      ),
      body: chat == null || chat.messages.isEmpty
          ? const Center(
              child: MiraloEmptyState(
                icon: Icons.auto_awesome_outlined,
                title: 'Start a conversation',
                subtitle:
                    'Ask MIRALO AI anything. Your conversation stays private.',
              ),
            )
          : MessageList(
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
      composer: Composer(
        isPrivate: false,
        isSubmitting: ai.isStreaming,
        hintText: 'Ask anything...',
        onSubmitted: (prompt) => ai.sendPrompt(prompt),
      ),
    );
  }
}
