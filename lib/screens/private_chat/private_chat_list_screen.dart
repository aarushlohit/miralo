import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/private_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/chat/image_viewer.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_avatar.dart';
import '../../widgets/common/miralo_empty_state.dart';
import '../../widgets/common/miralo_logo.dart';
import '../../widgets/common/miralo_segmented_tabs.dart';

import '../../widgets/private_chat/add_friend_sheet.dart';

/// Private Chat List Screen with Chats and Images tabs.
class PrivateChatListScreen extends StatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  State<PrivateChatListScreen> createState() =>
      _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends State<PrivateChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _showSearch = false;
  int _selectedTabIndex = 0; // 0: Chats, 1: Images

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final chat = Provider.of<PrivateChatProvider>(context, listen: false);
      chat.initUserSession(
        auth.currentUser!.id,
        username: auth.currentUser?.username,
        email: auth.currentUser?.email,
      );
    }
  }

  void _showAddFriend(BuildContext context, PrivateChatProvider chat, AuthProvider auth, {int initialTab = 0}) {
    AddFriendSheet.show(context, initialTab: initialTab);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final chat = Provider.of<PrivateChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);


    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    // ── Locked state ─────────────────────────────────────────────
    if (!vault.isPrivateUnlocked) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              MiraloAppBar(
                leading: MiraloCircularIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 16,
                  onPressed: () => Navigator.pop(context),
                ),
                title: '',
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MiraloLogo(size: 64),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Private Workspace',
                            style: AppTypography.heading2(
                                color: textPrimary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Type your secret phrase into the AI composer to access your private conversations.',
                          style: AppTypography.body(color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border:
                                Border.all(color: borderColor, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  size: 14, color: AppColors.accent),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Protected by Miralo Vault',
                                  style: AppTypography.caption(
                                      color: AppColors.accent)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Go back',
                              style: AppTypography.bodyMedium(
                                  color: textMuted)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Unlocked state ────────────────────────────────────────────
    final contacts = chat.allConversations.where((c) {
      if (_query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_query.toLowerCase()) ||
          c.username.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // MiraloAppBar
            MiraloAppBar(
              leading: MiraloCircularIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
              title: 'Private Space',
              actions: [
                if (_selectedTabIndex == 0) ...[
                  MiraloCircularIconButton(
                    icon: Icons.search_rounded,
                    iconSize: 18,
                    onPressed: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _query = '';
                        _searchCtrl.clear();
                      }
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  MiraloCircularIconButton(
                    icon: Icons.person_add_alt_1_rounded,
                    iconSize: 18,
                    onPressed: () => _showAddFriend(context, chat, auth),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.accent),
                    tooltip: 'Chat Backup & Export',
                    onSelected: (val) async {
                      if (val == 'backup') {
                        final ok = await chat.triggerCloudAutoBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Cloud auto-backup updated successfully!' : 'Backup notice: Local state synced.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else if (val == 'export') {
                        final bytes = await chat.exportChatsToZip();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(bytes != null ? 'Chat exported as ZIP (${(bytes.length / 1024).toStringAsFixed(1)} KB)!' : 'Export failed'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else if (val == 'import') {
                        final ok = await chat.importChatsFromZipFile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Chat backup restored from ZIP!' : 'Import cancelled or invalid ZIP'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'backup',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_sync_outlined, size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('Cloud Auto-Backup'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.folder_zip_outlined, size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('Export Chat (.zip)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.unarchive_outlined, size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('Import Chat (.zip)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                MiraloCircularIconButton(
                  icon: Icons.lock_outline_rounded,
                  iconSize: 18,
                  onPressed: () {
                    vault.lockPrivate();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            // Segmented Tab Switcher (Chats vs Images)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: MiraloSegmentedTabs(
                tabs: const ['Chats', 'Images'],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (idx) => setState(() => _selectedTabIndex = idx),
              ),
            ),

            // Content Area
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildChatsTab(context, chat, vault, contacts, bg, textPrimary, textSecondary, textMuted, borderColor, iconBg, surface)
                  : _buildChatImagesTab(context, chat, isDark, textPrimary, textSecondary, textMuted, borderColor, surface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab(
    BuildContext context,
    PrivateChatProvider chat,
    VaultProvider vault,
    List<dynamic> contacts,
    Color bg,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color borderColor,
    Color iconBg,
    Color surface,
  ) {
    return Column(
      children: [
        // Search bar
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _showSearch
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSpacing.composerRadius),
                border: Border.all(color: borderColor, width: 0.6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.search, size: 16, color: textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: _showSearch,
                      style: AppTypography.bodySmall(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search contacts',
                        hintStyle: AppTypography.bodySmall(color: textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close, size: 14, color: textMuted),
                      onPressed: () => setState(() {
                        _query = '';
                        _searchCtrl.clear();
                      }),
                    ),
                ],
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        // Pending friend requests banner
        if (chat.pendingFriendRequests.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: InkWell(
              onTap: () => _showAddFriend(context, chat, Provider.of<AuthProvider>(context, listen: false), initialTab: 1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${chat.pendingFriendRequests.length} Pending Invitation${chat.pendingFriendRequests.length > 1 ? 's' : ''}',
                            style: AppTypography.bodySmall(color: textPrimary).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Tap to review incoming invitations',
                            style: AppTypography.caption(color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Review',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Contact list
        Expanded(
          child: contacts.isEmpty
              ? MiraloEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: _query.isEmpty ? 'No contacts' : 'No results',
                  subtitle: _query.isEmpty
                      ? 'Add a contact to start chatting privately.'
                      : 'No contacts matching "$_query".',
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.xl),
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1, indent: 76),
                  itemBuilder: (_, i) {
                    final contact = contacts[i];
                    final isHidden = vault.hideMode.isEnabled;

                    final displayName = isHidden && vault.hideMode.hidePrivateChatNames
                        ? 'Contact ${i + 1}'
                        : contact.displayName;

                    final lastMessageObj = chat.getLastMessageForContact(contact.id);
                    final lastMsg = isHidden && vault.hideMode.hideMessagePreviews
                        ? '••••••••••'
                        : (lastMessageObj != null
                            ? (lastMessageObj.type == 'image'
                                ? '📷 Photo'
                                : (lastMessageObj.type == 'voice'
                                    ? '🎤 Voice note'
                                    : lastMessageObj.text))
                            : 'Tap to start conversation');

                    return InkWell(
                      onTap: () {
                        chat.setActiveChat(contact.id);
                        Navigator.pushNamed(context, AppRoutes.privateChat);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                             isHidden && vault.hideMode.hideProfilePicture
                                 ? Container(
                                     width: 44,
                                     height: 44,
                                     decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                                     child: const Icon(Icons.shield_outlined, size: 22, color: AppColors.accent),
                                   )
                                 : contact.isGroup
                                     ? Container(
                                         width: 50,
                                         height: 50,
                                         decoration: BoxDecoration(
                                           color: AppColors.accent.withValues(alpha: 0.15),
                                           shape: BoxShape.circle,
                                         ),
                                         child: const Icon(Icons.group_rounded, color: AppColors.accent, size: 26),
                                       )
                                     : MiraloAvatar(
                                         name: contact.displayName,
                                         imageUrl: contact.avatarUrl,
                                         size: 50,
                                         isOnline: contact.isOnline,
                                       ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: AppTypography.bodyMedium(color: textPrimary)
                                              .copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text('10:30', style: AppTypography.caption(color: textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (contact.isGroup && lastMsg.toLowerCase().contains('@all'))
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColors.accent.withValues(alpha: 0.4),
                                              width: 0.6,
                                            ),
                                          ),
                                          child: const Text(
                                            '@all',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          lastMsg,
                                          style: AppTypography.bodySmall(
                                            color: contact.unreadCount > 0 ? textPrimary : textSecondary,
                                          ).copyWith(
                                            fontWeight: contact.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (contact.unreadCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${contact.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatImagesTab(
    BuildContext context,
    PrivateChatProvider chat,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color borderColor,
    Color surface,
  ) {
    final images = chat.allChatImages;
    final library = Provider.of<LibraryProvider>(context, listen: false);

    if (images.isEmpty) {
      return const MiraloEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No Chat Images',
        subtitle: 'Photos and images received in your private chats will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${images.length} ${images.length == 1 ? 'Image' : 'Images'} from chats',
                style: AppTypography.caption(color: textSecondary),
              ),
              Text(
                'Tap to view • Long press for options',
                style: AppTypography.caption(color: textMuted).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imgMsg = images[index];
              return GestureDetector(
                onTap: () {
                  ImageViewer.show(
                    context,
                    imageBase64: imgMsg.imageBase64,
                    imageUrl: imgMsg.mediaUrl,
                    title: imgMsg.fileName ?? 'Chat Image',
                  );
                },
                onLongPress: () => _showImageOptionsSheet(context, imgMsg, chat, library, isDark),
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: borderColor, width: 0.6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageThumbnail(imgMsg, textMuted),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _showImageOptionsSheet(context, imgMsg, chat, library, isDark),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.more_vert, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImageOptionsSheet(
    BuildContext context,
    PrivateMessageModel imgMsg,
    PrivateChatProvider chat,
    LibraryProvider library,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded, color: AppColors.accent),
                title: Text('View Full Image', style: AppTypography.bodyMedium(color: textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ImageViewer.show(
                    context,
                    imageBase64: imgMsg.imageBase64,
                    imageUrl: imgMsg.mediaUrl,
                    title: imgMsg.fileName ?? 'Chat Image',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: AppColors.accent),
                title: Text('Move to Library (Vault)', style: AppTypography.bodyMedium(color: textPrimary)),
                subtitle: Text(
                  'Encrypts & moves to vault (Removes from chat)',
                  style: AppTypography.caption(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  chat.moveMessageToPrivateVault(imgMsg, library);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Moved to Library Vault (Removed from chat).'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined, color: AppColors.accent),
                title: Text('Save to Library (Copy)', style: AppTypography.bodyMedium(color: textPrimary)),
                subtitle: Text(
                  'Saves encrypted copy to vault while keeping in chat',
                  style: AppTypography.caption(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  chat.saveMessageToLibrary(imgMsg, library);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved copy to Library Vault.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: Text('Delete Image', style: AppTypography.bodyMedium(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  chat.deleteMessage(imgMsg.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image deleted from chat.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(PrivateMessageModel msg, Color textMuted) {
    if (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(msg.imageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: textMuted)),
        );
      } catch (_) {}
    }
    if (msg.mediaUrl != null && msg.mediaUrl!.startsWith('http')) {
      return Image.network(
        msg.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: textMuted)),
      );
    }
    return Center(child: Icon(Icons.image_outlined, color: textMuted, size: 28));
  }
}

