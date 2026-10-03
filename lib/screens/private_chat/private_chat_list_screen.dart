import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/longcat_app_bar.dart';
import '../../widgets/common/longcat_avatar.dart';
import '../../widgets/common/longcat_empty_state.dart';
import '../../widgets/common/longcat_logo.dart';
import '../../widgets/private_chat/add_friend_sheet.dart';
import '../../models/private_contact_model.dart';
import 'group_profile_screen.dart';

/// Private Chat List Screen.
class PrivateChatListScreen extends StatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  State<PrivateChatListScreen> createState() =>
      _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends State<PrivateChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _searchDebounce;
  List<Map<String, String>> _globalResults = [];
  bool _isSearchingGlobal = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
      chat.refreshFriendRequests();
    }
  }

  void _showAddFriend(BuildContext context, PrivateChatProvider chat, AuthProvider auth, {int initialTab = 0}) {
    AddFriendSheet.show(context, initialTab: initialTab);
  }

  void _showContactOptions(BuildContext context, PrivateChatProvider chat, PrivateContactModel contact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
                chat.clearConversationMessages(contact.id);
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
                      'Are you sure you want to delete this chat with ${contact.displayName}? All message history will be removed.',
                      style: AppTypography.body(color: textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dCtx);
                          await chat.deleteConversation(contact.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted chat with ${contact.displayName}')),
                            );
                          }
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

  void _openChatWithUser(
    PrivateChatProvider chat, {
    required String userId,
    required String name,
    required String username,
  }) {
    chat.setActiveChat(userId, displayName: name, username: username);
    Navigator.pushNamed(context, AppRoutes.privateChat);
  }

  void _handleSearchChanged(String v, VaultProvider vault, PrivateChatProvider chat) async {
    try {
      vault.resetInactivityTimer();
    } catch (_) {}

    final trimmed = v.trim();
    final lower = trimmed.toLowerCase();

    // Check /unhide <secretkey> or unhide <secretkey>
    if (lower.startsWith('/unhide') || lower.startsWith('unhide')) {
      final prefixLen = lower.startsWith('/unhide') ? 7 : 6;
      final key = trimmed.length > prefixLen ? trimmed.substring(prefixLen).trim() : '';
      if (key.isNotEmpty) {
        final isMatch = await vault.verifyUnhideKeyAsync(key);
        if (isMatch) {
          vault.unhideChatMessages();
          vault.unhideLibraryContent();
          vault.resetInactivityTimer();
          _searchCtrl.clear();
          if (mounted) {
            setState(() {
              _query = '';
              _globalResults = [];
              _isSearchingGlobal = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Private chats and notes unhidden.'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.accent,
              ),
            );
          }
          return;
        }
      }
    } else if (lower == '/hide' || lower == 'hide') {
      vault.hideChatMessages();
      vault.hideLibraryContent();
      vault.resetInactivityTimer();
      _searchCtrl.clear();
      if (mounted) {
        setState(() {
          _query = '';
          _globalResults = [];
          _isSearchingGlobal = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Private chats and notes hidden.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _query = v;
    });

    if (trimmed.isEmpty) {
      _searchDebounce?.cancel();
      setState(() {
        _globalResults = [];
        _isSearchingGlobal = false;
      });
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _executeGlobalSearch(trimmed, chat);
    });
  }

  void _handleSearchSubmitted(String v, VaultProvider vault, PrivateChatProvider chat) async {
    final trimmed = v.trim();
    final lower = trimmed.toLowerCase();

    if (lower.startsWith('/unhide') || lower.startsWith('unhide')) {
      final prefixLen = lower.startsWith('/unhide') ? 7 : 6;
      final key = trimmed.length > prefixLen ? trimmed.substring(prefixLen).trim() : '';
      final isMatch = key.isNotEmpty && await vault.verifyUnhideKeyAsync(key);
      if (isMatch) {
        vault.unhideChatMessages();
        vault.unhideLibraryContent();
        vault.resetInactivityTimer();
        _searchCtrl.clear();
        if (mounted) {
          setState(() {
            _query = '';
            _globalResults = [];
            _isSearchingGlobal = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Private chats and notes unhidden.'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect secret key.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    _executeGlobalSearch(trimmed, chat);
  }

  Future<void> _executeGlobalSearch(String query, PrivateChatProvider chat) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    setState(() => _isSearchingGlobal = true);

    try {
      final results = await chat.searchUsersByQuery(clean);
      if (mounted) {
        for (var u in results) {
          final id = u['id'];
          if (id != null && id.isNotEmpty) {
            chat.subscribeToUserPresence(id);
          }
        }
        setState(() {
          _globalResults = results;
          _isSearchingGlobal = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearchingGlobal = false);
      }
    }
  }

  Widget _buildSearchBar({
    required BuildContext context,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color iconBg,
    required Color borderColor,
    required VaultProvider vault,
    required PrivateChatProvider chat,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _query.isNotEmpty ? AppColors.accent : borderColor.withValues(alpha: 0.7),
            width: _query.isNotEmpty ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: _query.isNotEmpty ? AppColors.accent : textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: AppTypography.body(color: textPrimary).copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search contacts, @username, or User ID...',
                  hintStyle: AppTypography.body(color: textMuted).copyWith(fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                onChanged: (v) => _handleSearchChanged(v, vault, chat),
                onSubmitted: (v) => _handleSearchSubmitted(v, vault, chat),
              ),
            ),
            if (_isSearchingGlobal)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
              )
            else if (_query.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _query = '';
                    _globalResults = [];
                    _isSearchingGlobal = false;
                  });
                },
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
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
              LongcatAppBar(
                leading: LongcatCircularIconButton(
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
                        const LongcatLogo(size: 64),
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
                              Text('Protected by Longcat Vault',
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
    final cleanQuery = _query.toLowerCase().trim();
    final cleanQueryNoAt = cleanQuery.startsWith('@') ? cleanQuery.substring(1) : cleanQuery;
    final contacts = chat.allConversations.where((c) {
      if (cleanQuery.isEmpty) return true;
      return c.displayName.toLowerCase().contains(cleanQuery) ||
          c.username.toLowerCase().contains(cleanQuery) ||
          (cleanQueryNoAt.isNotEmpty && c.username.toLowerCase().contains(cleanQueryNoAt)) ||
          c.id.toLowerCase().contains(cleanQuery);
    }).toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          vault.hideChatMessages();
          vault.resetInactivityTimer();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          try {
            vault.resetInactivityTimer();
          } catch (_) {}
        },
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // LongcatAppBar
                LongcatAppBar(
                  leading: LongcatCircularIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    size: 36,
                    iconSize: 16,
                    onPressed: () {
                      vault.hideChatMessages();
                      vault.resetInactivityTimer();
                      Navigator.pop(context);
                    },
                  ),
                  title: 'Private Space',
                  actions: [
                    LongcatCircularIconButton(
                      icon: Icons.person_add_alt_1_rounded,
                      size: 36,
                      iconSize: 18,
                      tooltip: 'Add Contact',
                      onPressed: () => _showAddFriend(context, chat, auth),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      tooltip: 'Chat Backup & Export',
                      padding: EdgeInsets.zero,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                        child: const Icon(Icons.cloud_upload_outlined, size: 18, color: AppColors.accent),
                      ),
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
                    const SizedBox(width: 6),
                    LongcatCircularIconButton(
                      icon: Icons.lock_outline_rounded,
                      size: 36,
                      iconSize: 18,
                      tooltip: 'Lock Vault',
                      onPressed: () {
                        vault.lockPrivate();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),

                // Dedicated, clean Search Bar
                _buildSearchBar(
                  context: context,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  iconBg: iconBg,
                  borderColor: borderColor,
                  vault: vault,
                  chat: chat,
                ),

                // Content Area
                Expanded(
                  child: _buildChatsTab(
                context,
                chat,
                vault,
                auth,
                contacts,
                isDark,
                bg,
                textPrimary,
                textSecondary,
                textMuted,
                borderColor,
                iconBg,
                surface,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildChatsTab(
    BuildContext context,
    PrivateChatProvider chat,
    VaultProvider vault,
    AuthProvider auth,
    List<dynamic> contacts,
    bool isDark,
    Color bg,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color borderColor,
    Color iconBg,
    Color surface,
  ) {
    final localContactIds = contacts.map((c) => c.id.toString().toLowerCase()).toSet();
    final localUsernames = contacts.map((c) => c.username.toString().toLowerCase()).toSet();
    final filteredGlobalResults = _globalResults.where((u) {
      final uId = (u['id'] ?? '').toLowerCase();
      final uName = (u['username'] ?? '').toLowerCase();
      return !localContactIds.contains(uId) && !localUsernames.contains(uName);
    }).toList();

    return Column(
      children: [
        if (_query.isNotEmpty)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.xl),
              children: [
                if (contacts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 6),
                    child: Text(
                      'CONVERSATIONS',
                      style: AppTypography.caption(color: textMuted).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...contacts.map((contact) {
                    final isHidden = vault.hideMode.isEnabled;
                    final displayName = isHidden && vault.hideMode.hidePrivateChatNames
                        ? 'Contact'
                        : contact.displayName;

                    final lastMessageObj = chat.getLastMessageForContact(contact.id);
                    final lastMsg = (isHidden && vault.hideMode.hideMessagePreviews) || !vault.isChatMessagesUnhidden
                        ? 'Encrypted chat'
                        : (lastMessageObj != null
                            ? (lastMessageObj.type == 'image'
                                ? '📷 Photo'
                                : (lastMessageObj.type == 'voice'
                                    ? '🎤 Voice note'
                                    : (lastMessageObj.text.isNotEmpty ? lastMessageObj.text : 'Encrypted chat')))
                            : 'Tap to chat');

                    return InkWell(
                      onTap: () {
                        chat.setActiveChat(contact.id, displayName: contact.displayName, username: contact.username);
                        Navigator.pushNamed(context, AppRoutes.privateChat);
                      },
                      onLongPress: () => _showContactOptions(context, chat, contact),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            LongcatAvatar(
                              name: contact.displayName,
                              imageUrl: contact.avatarUrl,
                              size: 46,
                              isOnline: contact.isOnline,
                              showNote: false,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: AppTypography.bodyMedium(color: textPrimary)
                                        .copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastMsg,
                                    style: AppTypography.bodySmall(color: textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            InkWell(
                              onTap: () {
                                chat.setActiveChat(contact.id, displayName: contact.displayName, username: contact.username);
                                Navigator.pushNamed(context, AppRoutes.privateChat);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.accent),
                                    SizedBox(width: 4),
                                    Text('Chat', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (_isSearchingGlobal)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Searching all users on Miralo...',
                          style: AppTypography.caption(color: textMuted),
                        ),
                      ],
                    ),
                  ),
                if (filteredGlobalResults.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.public_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'SEARCH ANYTIME · GLOBAL USERS',
                          style: AppTypography.caption(color: AppColors.accent).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...filteredGlobalResults.map((u) {
                    final uId = u['id'] ?? '';
                    final uName = (u['name'] != null && u['name']!.isNotEmpty) ? u['name']! : (u['username'] ?? 'User');
                    final uUsername = u['username'] ?? '';
                    final isOnline = chat.isUserOnline(uId) || chat.isUserOnline(uUsername);
                    final lastSeen = chat.getUserLastSeen(uId);

                    return InkWell(
                      onTap: () => _openChatWithUser(chat, userId: uId, name: uName, username: uUsername),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            LongcatAvatar(
                              name: uName,
                              imageUrl: u['avatarUrl'],
                              size: 46,
                              isOnline: isOnline,
                              showNote: false,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    uName,
                                    style: AppTypography.bodyMedium(color: textPrimary)
                                        .copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (uUsername.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            '@$uUsername',
                                            style: AppTypography.caption(color: textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      if (uUsername.isNotEmpty)
                                        Text(' · ', style: TextStyle(color: textMuted, fontSize: 11)),
                                      Text(
                                        isOnline ? 'Online' : lastSeen,
                                        style: AppTypography.caption(
                                          color: isOnline ? AppColors.onlineGreen : textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            InkWell(
                              onTap: () => _openChatWithUser(chat, userId: uId, name: uName, username: uUsername),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'Chat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (contacts.isEmpty && filteredGlobalResults.isEmpty && !_isSearchingGlobal)
                  LongcatEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No users found',
                    subtitle: 'No contacts or users matching "$_query".',
                  ),
              ],
            ),
          )
        else ...[
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

          // Notes Tray
          _buildNotesTray(context, chat, auth, isDark, textPrimary, textMuted, surface, borderColor),

          // Contact list
          Expanded(
            child: contacts.isEmpty
                ? LongcatEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No contacts',
                    subtitle: 'Add a contact or search anytime to start chatting privately.',
                  )
                : RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () async {
                      await chat.refreshFriendRequests();
                    },
                    child: ListView.separated(
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
                    final lastMsg = (isHidden && vault.hideMode.hideMessagePreviews) || !vault.isChatMessagesUnhidden
                        ? (contact.isPendingInvitation
                            ? 'New invitation · Tap to review & chat'
                            : (contact.isGroup
                                ? '${contact.memberIds.length} members · Encrypted'
                                : 'Encrypted chat'))
                        : (contact.isPendingInvitation
                            ? 'New invitation · Tap to review & chat'
                            : (lastMessageObj != null
                                ? (lastMessageObj.type == 'image'
                                    ? '📷 Photo'
                                    : (lastMessageObj.type == 'voice'
                                        ? '🎤 Voice note'
                                        : 'Encrypted chat'))
                                : 'Tap to start conversation'));

                    return InkWell(
                      onTap: () {
                        chat.setActiveChat(contact.id);
                        Navigator.pushNamed(context, AppRoutes.privateChat);
                      },
                      onLongPress: () => _showContactOptions(context, chat, contact),
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
                                     ? GestureDetector(
                                         onTap: () {
                                           Navigator.push(
                                             context,
                                             MaterialPageRoute(
                                               builder: (_) => GroupProfileScreen(groupId: contact.id),
                                             ),
                                           );
                                         },
                                         child: LongcatAvatar(
                                           name: contact.displayName,
                                           imageUrl: contact.avatarUrl,
                                           size: 50,
                                         ),
                                       )
                                     : LongcatAvatar(
                                         name: contact.displayName,
                                         imageUrl: contact.avatarUrl,
                                         size: 50,
                                         isOnline: contact.isOnline,
                                         note: contact.note,
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
                                      if (contact.isPendingInvitation)
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
                                            'Invitation',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
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
                                            color: textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ],
    );
  }

  Widget _buildNotesTray(
    BuildContext context,
    PrivateChatProvider chat,
    AuthProvider auth,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color surface,
    Color borderColor,
  ) {
    final contactsWithNotes = chat.contacts.where((c) => c.note != null && c.note!.trim().isNotEmpty).toList();

    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 8, bottom: AppSpacing.xs),
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 22, AppSpacing.md, 4),
        children: [
          // Current User's Note
          GestureDetector(
            onTap: () => _showEditNoteDialog(context, chat),
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LongcatAvatar(
                        name: auth.currentUser?.displayName ?? 'You',
                        imageUrl: auth.currentUser?.avatarUrl,
                        size: 50,
                        note: chat.currentUserNote,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: surface, width: 2),
                          ),
                          child: Icon(
                            chat.currentUserNote != null && chat.currentUserNote!.isNotEmpty
                                ? Icons.edit_rounded
                                : Icons.add_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your note',
                    style: AppTypography.caption(color: textMuted).copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Friends Notes
          ...contactsWithNotes.map((c) {
            return GestureDetector(
              onTap: () {
                chat.setActiveChat(c.id);
                Navigator.pushNamed(context, AppRoutes.privateChat);
              },
              child: Container(
                width: 72,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LongcatAvatar(
                      name: c.displayName,
                      imageUrl: c.avatarUrl,
                      size: 50,
                      isOnline: c.isOnline,
                      note: c.note,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.displayName,
                      style: AppTypography.caption(color: textPrimary).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, PrivateChatProvider chat) {
    final controller = TextEditingController(text: chat.currentUserNote ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share a note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your note will float near your avatar for your contacts to see.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'Share what\'s on your mind...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (chat.currentUserNote != null && chat.currentUserNote!.isNotEmpty)
            TextButton(
              onPressed: () async {
                await chat.updateCurrentUserNote(null);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await chat.updateCurrentUserNote(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
