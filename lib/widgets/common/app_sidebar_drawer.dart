import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/ai_chat_model.dart';
import '../../models/private_contact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/theme_provider.dart';
import '../private_chat/add_friend_sheet.dart';
import 'miralo_avatar.dart';

/// MIRALO AI Sidebar Drawer — Clean ChatGPT-inspired design.
///
/// Upgraded Features:
/// - Real-time chat search & filtering directly in the drawer.
/// - 3-dots button & long-press on every chat: Pin/Unpin, Rename, Delete.
/// - Minimum 1-chat guarantee supported.
/// - Library item with lock icon and passcode / system lock gating.
/// - Pure monochrome / blue accent aesthetic.
class AppSidebarDrawer extends StatefulWidget {
  final bool isPersistent;
  final VoidCallback? onClose;

  const AppSidebarDrawer({
    super.key,
    this.isPersistent = false,
    this.onClose,
  });

  @override
  State<AppSidebarDrawer> createState() => _AppSidebarDrawerState();
}

class _AppSidebarDrawerState extends State<AppSidebarDrawer> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _close(BuildContext context) {
    if (widget.isPersistent) {
      widget.onClose?.call();
    } else {
      Navigator.pop(context);
    }
  }

  void _showChatOptions(BuildContext context, AiChatProvider ai, AiChatModel chat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
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
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  chat.title,
                  style: AppTypography.heading3(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              title: Text(
                chat.isPinned ? 'Unpin chat' : 'Pin chat',
                style: AppTypography.bodyMedium(color: textPrimary),
              ),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                ai.togglePin(chat.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 20),
              title: Text(
                'Rename chat',
                style: AppTypography.bodyMedium(color: textPrimary),
              ),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ai, chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
              title: Text(
                'Delete chat',
                style: AppTypography.bodyMedium(color: AppColors.danger),
              ),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                ai.deleteConversation(chat.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat removed.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AiChatProvider ai, AiChatModel chat) {
    final controller = TextEditingController(text: chat.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename Conversation', style: AppTypography.heading3(color: textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium(color: textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ai.renameConversation(chat.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivateChatOptions(
    BuildContext context,
    PrivateChatProvider privateChat,
    PrivateContactModel contact,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
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
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  contact.displayName,
                  style: AppTypography.heading3(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.accent, size: 20),
              title: Text('Clear messages', style: AppTypography.bodyMedium(color: textPrimary)),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                privateChat.clearConversationMessages(contact.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cleared messages with ${contact.displayName}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              title: Text(
                'Delete Chat',
                style: AppTypography.bodyMedium(color: Colors.red),
              ),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: bg,
                    title: Text('Delete Chat?', style: AppTypography.heading3(color: textPrimary)),
                    content: Text(
                      'Are you sure you want to delete this chat with ${contact.displayName}? This cannot be undone.',
                      style: AppTypography.body(color: textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dCtx);
                          privateChat.deleteConversation(contact.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted chat with ${contact.displayName}')),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final ai = Provider.of<AiChatProvider>(context);
    final privateChat = Provider.of<PrivateChatProvider>(context);
    final vault = Provider.of<VaultProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final user = auth.currentUser;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

    final pinnedList = ai.filteredPinnedChats;
    final recentList = ai.filteredRecentChats;

    Widget content = SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
            child: Row(
              children: [
                // MIRALO wordmark
                Expanded(
                  child: Text(
                    'MIRALO AI',
                    style: AppTypography.wordmark(color: textPrimary),
                  ),
                ),
                // Search button
                _CircleIconBtn(
                  icon: _isSearching ? Icons.search_off_rounded : Icons.search_rounded,
                  color: _isSearching ? AppColors.accent : textPrimary,
                  bg: iconBg,
                  tooltip: _isSearching ? 'Exit search' : 'Search chats',
                  onTap: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ai.setSearchQuery('');
                      }
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                // Close button (non-persistent)
                if (!widget.isPersistent)
                  _CircleIconBtn(
                    icon: Icons.close_rounded,
                    color: textSecondary,
                    bg: iconBg,
                    tooltip: 'Close',
                    onTap: () => _close(context),
                  ),
              ],
            ),
          ),

          // ── Real-time Search Input Field (when searching) ───────
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTypography.bodyMedium(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: AppTypography.bodyMedium(color: textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ai.setSearchQuery('');
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    ai.setSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),
            ),

          // ── Nav list ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              children: [
                // + New chat (highlighted capsule button per reference)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
                    border: Border.all(color: border, width: 0.6),
                  ),
                  child: InkWell(
                    onTap: () {
                      ai.createNewChat();
                      _close(context);
                      Navigator.pushNamed(context, AppRoutes.home);
                    },
                    borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'New chat',
                            style: AppTypography.bodyMedium(color: textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search chats toggle
                _NavItem(
                  icon: Icons.search_rounded,
                  label: _isSearching ? 'Close search' : 'Search chats',
                  onTap: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ai.setSearchQuery('');
                      }
                    });
                  },
                ),

                // Library & Private Features — ONLY visible after secret passcode entered & unlocked
                if (vault.isPrivateUnlocked || vault.isLibraryUnlocked) ...[
                  _NavItem(
                    icon: Icons.person_add_outlined,
                    label: 'Add Friend',
                    onTap: () {
                      _close(context);
                      AddFriendSheet.show(context);
                    },
                  ),
                  _NavItem(
                    icon: Icons.group_add_outlined,
                    label: 'New Group',
                    onTap: () {
                      _close(context);
                      AddFriendSheet.show(context, initialTab: 2);
                    },
                  ),
                  if (vault.isPrivateUnlocked)
                    _NavItem(
                      icon: Icons.photo_library_outlined,
                      label: 'Images',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (privateChat.allChatImages.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${privateChat.allChatImages.length}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Icon(Icons.lock_outline_rounded,
                              size: 16, color: AppColors.accent),
                        ],
                      ),
                      onTap: () {
                        _close(context);
                        vault.lockLibrary();
                        Navigator.pushNamed(context, AppRoutes.libraryLocked,
                            arguments: AppRoutes.images);
                      },
                    ),
                  _NavItem(
                    icon: Icons.auto_stories_outlined,
                    label: 'Library',
                    trailing: const Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppColors.accent),
                    onTap: () {
                      _close(context);
                      vault.lockLibrary();
                      Navigator.pushNamed(context, AppRoutes.libraryLocked);
                    },
                  ),
                  _NavItem(
                    icon: Icons.shield_outlined,
                    label: 'Blacksheep',
                    trailing: vault.intruderLogs.isNotEmpty
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.danger,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          )
                        : null,
                    onTap: () {
                      _close(context);
                      Navigator.pushNamed(context, AppRoutes.blacksheep);
                    },
                  ),
                ],

                // Settings
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),

                // Search empty state
                if (_isSearching &&
                    pinnedList.isEmpty &&
                    recentList.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 24),
                    child: Center(
                      child: Text(
                        'No chats matching "${_searchController.text}"',
                        style: AppTypography.caption(color: textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],

                // ── Pinned section ───────────────────────────────────
                if (pinnedList.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('PINNED', textMuted),
                  ...pinnedList.map((chat) => _ConvItem(
                        chat: chat,
                        icon: Icons.push_pin_outlined,
                        onTap: () {
                          ai.openChat(chat.id);
                          _close(context);
                          Navigator.pushNamed(context, AppRoutes.chat);
                        },
                        onOptionsTap: () => _showChatOptions(context, ai, chat),
                      )),
                ],

                // ── Recent section ───────────────────────────────────
                if (recentList.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('RECENT', textMuted),
                  ...recentList.take(12).map((chat) => _ConvItem(
                        chat: chat,
                        onTap: () {
                          ai.openChat(chat.id);
                          _close(context);
                          Navigator.pushNamed(context, AppRoutes.chat);
                        },
                        onOptionsTap: () => _showChatOptions(context, ai, chat),
                      )),
                ],

                // ── Private chats & DMs (only after secret unlock) ──────
                if (vault.isPrivateUnlocked &&
                    (privateChat.allConversations.isNotEmpty ||
                        privateChat.pendingFriendRequests.isNotEmpty)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionLabel('CHATS & DMS', textMuted),
                        if (privateChat.pendingFriendRequests.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${privateChat.pendingFriendRequests.length} new',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (privateChat.pendingFriendRequests.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _close(context);
                        AddFriendSheet.show(context, initialTab: 1);
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_unread_outlined, color: AppColors.accent, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${privateChat.pendingFriendRequests.length} Friend Invitation${privateChat.pendingFriendRequests.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.accent, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ...privateChat.allConversations.map((contact) {
                    final isFriend = privateChat.contacts.any((c) => c.id == contact.id);
                    final displayName =
                        vault.hideMode.isEnabled &&
                                vault.hideMode.hidePrivateChatNames
                            ? 'Contact'
                            : contact.displayName;

                    final lastMsg = privateChat.getLastMessageForContact(contact.id);
                    final subtitle = !isFriend
                        ? 'Pending request'
                        : (contact.isOnline
                            ? 'Online'
                            : (lastMsg != null && lastMsg.text.isNotEmpty
                                ? lastMsg.text
                                : 'Encrypted chat'));

                    return _ContactItem(
                      name: displayName,
                      isOnline: contact.isOnline,
                      unread: contact.unreadCount,
                      subtitle: subtitle,
                      onTap: () {
                        privateChat.setActiveChat(contact.id);
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.privateChat);
                      },
                      onOptionsTap: () => _showPrivateChatOptions(context, privateChat, contact),
                    );
                  }),
                ],

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),

          // ── Bottom dock ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: border, width: 0.6)),
            ),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(context, AppRoutes.settingsProfile);
                  },
                  child: MiraloAvatar(
                    name: user?.displayName ?? 'User',
                    size: 36,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Name + email/username
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _close(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vault.hideMode.isEnabled &&
                                  vault.hideMode.hideUsername
                              ? 'User'
                              : (user?.displayName ?? 'User'),
                          style: AppTypography.bodyMedium(color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.username != null && user!.username.isNotEmpty
                              ? '@${user.username}'
                              : (user?.email ?? ''),
                          style: AppTypography.caption(color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Theme toggle
                _CircleIconBtn(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: textSecondary,
                  bg: Colors.transparent,
                  tooltip: 'Toggle theme',
                  onTap: () => theme.toggleTheme(),
                ),

                // Settings
                _CircleIconBtn(
                  icon: Icons.settings_outlined,
                  color: textSecondary,
                  bg: Colors.transparent,
                  tooltip: 'Settings',
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isPersistent) {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
              right: BorderSide(color: border, width: 0.6)),
        ),
        child: content,
      );
    }

    return Drawer(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.82,
      child: content,
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconBtn(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 4),
      child: Text(label, style: AppTypography.labelSmall(color: color)),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium(color: textPrimary)),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _ConvItem extends StatelessWidget {
  final AiChatModel chat;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  const _ConvItem({
    required this.chat,
    this.icon,
    required this.onTap,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: onTap,
      onLongPress: onOptionsTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon ?? (chat.isPinned ? Icons.push_pin_outlined : Icons.chat_bubble_outline_rounded),
              size: 16,
              color: chat.isPinned ? AppColors.accent : iconColor,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                chat.title,
                style: AppTypography.bodySmall(color: textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded, size: 16),
              color: iconColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onOptionsTap,
              tooltip: 'Options',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final String name;
  final bool isOnline;
  final int unread;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onOptionsTap;

  const _ContactItem({
    required this.name,
    required this.isOnline,
    required this.unread,
    this.subtitle,
    required this.onTap,
    this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: onTap,
      onLongPress: onOptionsTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 8),
        child: Row(
          children: [
            MiraloAvatar(name: name, size: 28, isOnline: isOnline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: AppTypography.bodySmall(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    subtitle ?? (isOnline ? 'Online' : 'Last seen recently'),
                    style: AppTypography.caption(color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread > 0) ...[
              Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (onOptionsTap != null)
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 16),
                color: textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: onOptionsTap,
                tooltip: 'Options',
              ),
          ],
        ),
      ),
    );
  }
}

