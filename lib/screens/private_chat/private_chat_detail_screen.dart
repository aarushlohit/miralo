import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../models/private_contact_model.dart';
import '../../models/private_message_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/chat/chat_header.dart';
import '../../widgets/chat/chat_scaffold.dart';
import '../../widgets/chat/composer.dart';
import '../../widgets/chat/message_actions.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/chat/message_renderer.dart';
import '../../widgets/chat/reaction_sheet.dart';

/// Private Chat Screen
/// Uses the exact same Chat UI components as AI Chat:
/// - ChatScaffold
/// - ChatHeader (Back, Editable display name e.g. 'Mira', More menu with 'Return to Chat')
/// - MessageList
/// - MessageRenderer (neutral surfaces, zero romantic/messaging styling)
/// - Composer (images only converted to Base64, /urgent and /clear interception)
/// - ReactionSheet & MessageActionsSheet
class PrivateChatDetailScreen extends StatefulWidget {
  const PrivateChatDetailScreen({super.key});

  @override
  State<PrivateChatDetailScreen> createState() => _PrivateChatDetailScreenState();
}

class _PrivateChatDetailScreenState extends State<PrivateChatDetailScreen> {
  String? _replyToText;

  void _quickExit(BuildContext context) {
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final ai = Provider.of<AiChatProvider>(context, listen: false);

    // Lock private access & clear private state
    vault.lockAll();

    // Return to last AI conversation, or prefill 'What is an API?' if no active chat
    if (ai.activeChat == null) {
      ai.prefillPrompt('What is an API?');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.aiChat,
        (route) => false,
      );
    }
  }

  void _showMoreMenu(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel? contact,
  ) {
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

              // Preferred label: Return to Chat
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded,
                    color: MiraloColors.accent, size: 22),
                title: Text(
                  'Return to Chat',
                  style: MiraloTypography.bodyMedium(color: MiraloColors.accent)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickExit(context);
                },
              ),

              // Edit display name
              if (contact != null)
                ListTile(
                  leading: Icon(Icons.edit_outlined,
                      color: textPrimary, size: 22),
                  title: Text(
                    'Edit display name',
                    style: MiraloTypography.bodyMedium(color: textPrimary),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDisplayNameDialog(context, chat, contact);
                  },
                ),

              // Clear conversation
              ListTile(
                leading: Icon(Icons.clear_all_rounded,
                    color: textPrimary, size: 22),
                title: Text(
                  'Clear conversation',
                  style: MiraloTypography.bodyMedium(color: textPrimary),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  chat.clearActiveChat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation cleared.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // Delete contact
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
                  chat.deleteCurrentChat();
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

  void _showEditDisplayNameDialog(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel contact,
  ) {
    final controller = TextEditingController(text: contact.displayName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? MiraloColors.darkSurfacePrimary
            : MiraloColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: MiraloRadius.r20),
        title: Text(
          'Edit display name',
          style: MiraloTypography.titleMedium(
            color: isDark
                ? MiraloColors.darkTextPrimary
                : MiraloColors.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: MiraloTypography.bodyMedium(
            color: isDark
                ? MiraloColors.darkTextPrimary
                : MiraloColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Display name',
            hintStyle: MiraloTypography.bodyMedium(
              color: isDark
                  ? MiraloColors.darkTextMuted
                  : MiraloColors.lightTextMuted,
            ),
            filled: true,
            fillColor: isDark
                ? MiraloColors.darkSurfaceSecondary
                : MiraloColors.lightSurfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: MiraloRadius.r12,
              borderSide: BorderSide(
                color: isDark
                    ? MiraloColors.darkBorder
                    : MiraloColors.lightBorder,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: MiraloTypography.labelMedium(
                color: isDark
                    ? MiraloColors.darkTextMuted
                    : MiraloColors.lightTextMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                chat.updateContactDisplayName(contact.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: MiraloTypography.labelMedium(color: MiraloColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    PrivateMessageModel msg,
    PrivateChatProvider chat,
    LibraryProvider library,
  ) {
    MessageActionsSheet.show(
      context,
      text: msg.text,
      onReact: () {
        ReactionSheet.show(
          context,
          onSelectEmoji: (emoji) => chat.toggleReaction(msg.id, emoji),
        );
      },
      onReply: () {
        setState(() {
          _replyToText = msg.text.isNotEmpty
              ? msg.text
              : (msg.type == 'image' ? '[Photo Attachment]' : '[Media]');
        });
      },
      onSaveToLibrary: () {
        chat.saveMessageToLibrary(msg, library);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Library'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onMoveToVault: () {
        chat.moveMessageToPrivateVault(msg, library);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moved to Private Vault'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onDelete: () => chat.deleteMessage(msg.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = Provider.of<PrivateChatProvider>(context);
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final contact = chat.activeContact;
    final messages = chat.activeMessages;

    final displayName = contact?.displayName ?? 'Mira';
    final subtitle = contact?.isOnline == true ? 'Active recently' : (contact?.lastSeenText ?? '');

    return ChatScaffold(
      header: ChatHeader(
        isPrivate: true,
        title: displayName,
        subtitle: subtitle,
        onBack: () => Navigator.pop(context),
        onEditDisplayName: contact != null
            ? () => _showEditDisplayNameDialog(context, chat, contact)
            : null,
        onMoreOptions: () => _showMoreMenu(context, chat, contact),
      ),
      body: MessageList(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return MessageRenderer(
            id: msg.id,
            text: msg.text,
            isMe: msg.isMe,
            senderName: msg.isMe ? null : displayName,
            createdAt: msg.createdAt,
            imageBase64: msg.imageBase64,
            imageUrl: msg.mediaUrl,
            type: msg.type,
            fileName: msg.fileName,
            fileSize: msg.fileSize,
            status: msg.status,
            replyToText: msg.replyToText,
            reactions: msg.reactions,
            onReactionTap: (emoji) => chat.toggleReaction(msg.id, emoji),
            onLongPress: () => _showMessageOptions(context, msg, chat, library),
          );
        },
      ),
      composer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active reply/retag bar banner if selected
          if (_replyToText != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: MiraloSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E7EB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(left: BorderSide(color: MiraloColors.accent, width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: MiraloColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to: "$_replyToText"',
                      style: MiraloTypography.bodySmall(
                        color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyToText = null),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ],
              ),
            ),
          Composer(
            isPrivate: true,
            hintText: 'Message $displayName...',
            onSubmitted: (text) {
              chat.sendTextMessage(text, replyToText: _replyToText);
              if (_replyToText != null) setState(() => _replyToText = null);
            },
            onImageAttached: (base64OrUrl, fileName) {
              chat.sendMediaMessage(
                type: 'image',
                mediaUrl: base64OrUrl.startsWith('http') ? base64OrUrl : null,
                imageBase64: base64OrUrl.startsWith('http') ? null : base64OrUrl,
                fileName: fileName,
                fileSize: '1.2 MB',
              );
            },
          ),
        ],
      ),
    );
  }
}
