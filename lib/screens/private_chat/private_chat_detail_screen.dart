import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/private_contact_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/chat/private_composer.dart';
import '../../widgets/chat/private_message_bubble.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_avatar.dart';
import '../../widgets/common/miralo_empty_state.dart';

class PrivateChatDetailScreen extends StatelessWidget {
  const PrivateChatDetailScreen({super.key});

  void _showChatMenu(BuildContext context, PrivateChatProvider chat,
      VaultProvider vault) {
    final contact = chat.activeContact;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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

            // View contact
            _SheetTile(
              icon: Icons.info_outline_rounded,
              label: 'Contact details',
              textColor: textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                _showContactInfo(context, chat);
              },
            ),

            // Edit display name
            if (contact != null)
              _SheetTile(
                icon: Icons.edit_outlined,
                label: 'Edit display name',
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDisplayNameDialog(context, chat, contact);
                },
              ),

            // Media
            _SheetTile(
              icon: Icons.perm_media_outlined,
              label: 'Shared media',
              textColor: textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.images);
              },
            ),

            // Mute
            _SheetTile(
              icon: Icons.notifications_off_outlined,
              label: 'Mute notifications',
              textColor: textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notifications muted for 8 hours.')),
                );
              },
            ),

            Divider(height: 0.6, thickness: 0.6, color: border),

            // Return to Chat (Emergency Exit)
            _SheetTile(
              icon: Icons.arrow_back_rounded,
              label: 'Return to Chat',
              textColor: textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                vault.lockPrivate();
                final ai = Provider.of<AiChatProvider>(context, listen: false);
                ai.createNewChat();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (r) => false,
                  arguments: {'prefill': 'What is an API?'},
                );
              },
            ),

            // Lock private
            _SheetTile(
              icon: Icons.lock_outline,
              label: 'Lock private workspace',
              textColor: textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                vault.lockPrivate();
                Navigator.pop(context);
              },
            ),

            // Delete (destructive)
            _SheetTile(
              icon: Icons.delete_outline,
              label: 'Clear conversation',
              textColor: AppColors.danger,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteChat(context, chat);
              },
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showContactInfo(BuildContext context, PrivateChatProvider chat) {
    final contact = chat.activeContact;
    if (contact == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg,
              AppSpacing.screenH, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiraloAvatar(name: contact.displayName, size: 64,
                  isOnline: contact.isOnline),
              const SizedBox(height: AppSpacing.md),
              Text(contact.displayName,
                  style: AppTypography.heading2(color: textPrimary)),
              const SizedBox(height: 4),
              Text('@${contact.username}',
                  style: AppTypography.body(color: textMuted)),
              const SizedBox(height: 4),
              Text(
                contact.isOnline ? 'Online now' : contact.lastSeenText,
                style: AppTypography.caption(
                    color: contact.isOnline
                        ? AppColors.onlineGreen
                        : textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'End-to-end local security active.\nMessages are stored privately on this device.',
                style: AppTypography.caption(color: textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Done',
                    style: AppTypography.bodyMedium(color: AppColors.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChat(BuildContext context, PrivateChatProvider chat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md,
              AppSpacing.screenH, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Delete chat?',
                  style: AppTypography.heading3(color: textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'All messages will be permanently removed. This cannot be undone.',
                style: AppTypography.body(color: textSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    foregroundColor: AppColors.danger,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius)),
                  ),
                  onPressed: () {
                    chat.deleteCurrentChat();
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text('Delete all messages',
                      style: AppTypography.button(color: AppColors.danger)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: AppTypography.button(color: textSub)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDisplayNameDialog(
      BuildContext context, PrivateChatProvider chat, PrivateContactModel contact) {
    final controller = TextEditingController(text: contact.displayName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Edit Display Name',
            style: AppTypography.heading3(color: textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter contact name',
            hintStyle: AppTypography.body(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.bodyMedium(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                chat.updateContactDisplayName(contact.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style: AppTypography.button(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = Provider.of<PrivateChatProvider>(context);
    final vault = Provider.of<VaultProvider>(context);
    final contact = chat.activeContact;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

    if (contact == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg),
        body: const MiraloEmptyState(
          icon: Icons.person_outline,
          title: 'No chat selected',
          subtitle: 'Go back and select a contact.',
        ),
      );
    }

    final isHiddenName =
        vault.hideMode.isEnabled && vault.hideMode.hidePrivateChatNames;
    final displayName = isHiddenName ? 'Contact' : contact.displayName;
    final isHiddenPic =
        vault.hideMode.isEnabled && vault.hideMode.hideProfilePicture;
    final messages = chat.activeMessages;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bespoke MiraloAppBar ─────────────────────────────
            MiraloAppBar(
              leading: MiraloCircularIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
              titleWidget: GestureDetector(
                onTap: () => _showContactInfo(context, chat),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isHiddenPic
                        ? Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: iconBg, shape: BoxShape.circle),
                            child: const Icon(Icons.shield_outlined,
                                size: 15, color: AppColors.accent),
                          )
                        : MiraloAvatar(
                            name: contact.displayName,
                            size: 30,
                            isOnline: contact.isOnline,
                          ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: MiraloTypography.heading3(color: textPrimary),
                        ),
                        Text(
                          contact.isOnline ? 'Online' : contact.lastSeenText,
                          style: MiraloTypography.caption(
                            color: contact.isOnline
                                ? AppColors.onlineGreen
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                MiraloCircularIconButton(
                  icon: Icons.more_horiz_rounded,
                  onPressed: () => _showChatMenu(context, chat, vault),
                ),
              ],
            ),

            // ── Messages ────────────────────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? MiraloEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: displayName,
                      subtitle: 'Say hi to start a private conversation.',
                      action: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.lightSurfaceSecondary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 12, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text('End-to-end private',
                                style: AppTypography.caption(
                                    color: AppColors.accent)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        return PrivateMessageBubble(
                          message: msg,
                          isMe: msg.isMe,
                          onReact: (emoji) =>
                              chat.toggleReaction(msg.id, emoji),
                          onDelete: () => chat.deleteMessage(msg.id),
                        );
                      },
                    ),
            ),

            // ── Private Composer with /clear and /urgent ─────────
            PrivateComposer(
              onSend: (text) => chat.sendTextMessage(text),
              onAttach: () => AttachmentSheetHelper.show(context, chat),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu tile helper ─────────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.textColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.bodyMedium(color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ─── Attachment helper ────────────────────────────────────────────────────────

class AttachmentSheetHelper {
  static void show(BuildContext context, PrivateChatProvider chat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) {
        final actions = [
          _AttachAction(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: () {
                Navigator.pop(ctx);
                chat.sendMediaMessage(
                    type: 'image', mediaUrl: 'camera_shot', text: 'Photo');
              }),
          _AttachAction(
              icon: Icons.photo_library_outlined,
              label: 'Photos',
              onTap: () {
                Navigator.pop(ctx);
                chat.sendMediaMessage(
                    type: 'image',
                    mediaUrl: 'mock_photo',
                    text: 'Photo from Gallery');
              }),
          _AttachAction(
              icon: Icons.insert_drive_file_outlined,
              label: 'Files',
              onTap: () {
                Navigator.pop(ctx);
                chat.sendMediaMessage(
                    type: 'file',
                    mediaUrl: '',
                    fileName: 'Document.pdf',
                    fileSize: '1.4 MB',
                    text: 'Document.pdf');
              }),
        ];

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.lg +
                    MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions.map((a) {
                    return GestureDetector(
                      onTap: a.onTap,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                            child: Icon(a.icon, size: 26, color: textColor),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(a.label,
                              style: AppTypography.caption(color: subColor)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: AppTypography.bodyMedium(color: subColor)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttachAction(
      {required this.icon, required this.label, required this.onTap});
}
