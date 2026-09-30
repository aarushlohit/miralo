import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/longcat_tokens.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/ai_message_bubble.dart';
import '../../widgets/chat/chat_header.dart';
import '../../widgets/chat/chat_scaffold.dart';
import '../../widgets/chat/composer.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/common/app_sidebar_drawer.dart';
import '../../widgets/common/longcat_empty_state.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  String? _editingMessageId;

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _handleEdit(String messageId, String editedText) {
    setState(() {
      _editingMessageId = messageId;
    });
    _composerController.text = editedText;
    _composerController.selection = TextSelection.collapsed(
      offset: editedText.length,
    );
    _composerFocusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
    });
    _composerController.clear();
  }

  void _showModelSelector(BuildContext context, AiChatProvider ai) {
    final models = ai.availableModels;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? LongcatColors.darkSurfacePrimary
        : LongcatColors.lightSurfacePrimary;
    final border = isDark
        ? LongcatColors.darkBorder
        : LongcatColors.lightBorder;
    final textColor = isDark
        ? LongcatColors.darkTextPrimary
        : LongcatColors.lightTextPrimary;
    final mutedColor = isDark
        ? LongcatColors.darkTextMuted
        : LongcatColors.lightTextMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LongcatRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: LongcatSpacing.md),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LongcatSpacing.lg,
                  0,
                  LongcatSpacing.lg,
                  LongcatSpacing.sm,
                ),
                child: Text(
                  'AI Model',
                  style: LongcatTypography.titleMedium(color: textColor),
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
                      horizontal: LongcatSpacing.lg,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m,
                            style: LongcatTypography.bodyMedium(color: textColor)
                                .copyWith(
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded,
                              size: 18, color: LongcatColors.accent)
                        else
                          Icon(Icons.circle_outlined,
                              size: 18, color: mutedColor),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: LongcatSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, AiChatProvider ai) {
    final chat = ai.activeChat;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? LongcatColors.darkSurfacePrimary
        : LongcatColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? LongcatColors.darkTextPrimary
        : LongcatColors.lightTextPrimary;
    final border = isDark
        ? LongcatColors.darkBorder
        : LongcatColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LongcatRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LongcatSpacing.lg,
            vertical: LongcatSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: LongcatSpacing.md),
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
                  style: LongcatTypography.bodyMedium(color: textPrimary),
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
                      color: LongcatColors.danger, size: 22),
                  title: Text(
                    'Delete conversation',
                    style: LongcatTypography.bodyMedium(
                        color: LongcatColors.danger),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    ai.deleteConversation(chat.id);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: LongcatSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = Provider.of<AiChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = ai.activeChat;

    return ChatScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const AppSidebarDrawer(),
      header: ChatHeader(
        isPrivate: false,
        modelName: ai.selectedModel,
        onBack: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        },
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onModelSelectorTap: () => _showModelSelector(context, ai),
        onMoreOptions: () => _showMoreMenu(context, ai),
      ),
      body: chat == null || chat.messages.isEmpty
          ? const Center(
              child: LongcatEmptyState(
                icon: Icons.auto_awesome_outlined,
                title: 'Start a conversation',
                subtitle:
                    'Ask LONGCAT AI anything. Your conversation stays private.',
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
                      ? () => ai.regenerateLast(isSpecialUser: auth.isSpecialUser)
                      : null,
                  onRetry: msg.isError
                      ? () => ai.retryAssistantMessage(msg.id, isSpecialUser: auth.isSpecialUser)
                      : null,
                  onEdit: msg.role == 'user'
                      ? (editedText) => _handleEdit(msg.id, editedText)
                      : null,
                );
              },
            ),
      composer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editingMessageId != null)
            Container(
              color: LongcatColors.accent.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, size: 16, color: LongcatColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing previous message prompt...',
                      style: LongcatTypography.caption(color: LongcatColors.accent)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close_rounded, size: 16, color: LongcatColors.accent),
                  ),
                ],
              ),
            ),
          Composer(
            isPrivate: false,
            isSubmitting: ai.isStreaming,
            hintText: _editingMessageId != null ? 'Edit prompt...' : 'Ask anything...',
            controller: _composerController,
            focusNode: _composerFocusNode,
            onSubmitted: (prompt) {
              if (_editingMessageId != null) {
                final targetId = _editingMessageId!;
                setState(() => _editingMessageId = null);
                ai.editUserPrompt(targetId, prompt, isSpecialUser: auth.isSpecialUser);
              } else {
                ai.sendPrompt(prompt, isSpecialUser: auth.isSpecialUser);
              }
            },
            onSubmittedWithImage: (prompt, img) {
              setState(() => _editingMessageId = null);
              ai.sendPrompt(prompt,
                  imageBase64: img, isSpecialUser: auth.isSpecialUser);
            },
          ),
        ],
      ),
    );
  }
}
