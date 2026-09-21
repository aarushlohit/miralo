import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_avatar.dart';
import '../../widgets/common/miralo_empty_state.dart';
import '../../widgets/common/miralo_logo.dart';

import '../../widgets/private_chat/add_friend_sheet.dart';

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
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddFriend(BuildContext context, PrivateChatProvider chat, AuthProvider auth) {
    AddFriendSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final chat = Provider.of<PrivateChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (auth.currentUser != null) {
      chat.initUserSession(auth.currentUser!.id);
    }

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
    final contacts = chat.contacts.where((c) {
      if (_query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_query.toLowerCase());
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
              title: 'Chats',
              actions: [
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

            // Search bar
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _showSearch
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
                    AppSpacing.md, AppSpacing.sm),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.composerRadius),
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
                          style:
                              AppTypography.bodySmall(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search contacts',
                            hintStyle: AppTypography.bodySmall(
                                color: textMuted),
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
                      padding: const EdgeInsets.only(
                          top: 4, bottom: AppSpacing.xl),
                      itemCount: contacts.length,
                      separatorBuilder: (context, index) => Divider(
                          color: borderColor, height: 1, indent: 76),
                      itemBuilder: (_, i) {
                        final contact = contacts[i];
                        final isHidden = vault.hideMode.isEnabled;

                        final displayName =
                            isHidden && vault.hideMode.hidePrivateChatNames
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
                            Navigator.pushNamed(
                                context, AppRoutes.privateChat);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            child: Row(
                              children: [
                                isHidden &&
                                        vault.hideMode.hideProfilePicture
                                    ? Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                            color: iconBg,
                                            shape: BoxShape.circle),
                                        child: const Icon(
                                            Icons.shield_outlined,
                                            size: 22,
                                            color: AppColors.accent),
                                      )
                                    : MiraloAvatar(
                                        name: contact.displayName,
                                        size: 50,
                                        isOnline: contact.isOnline,
                                      ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: AppTypography.bodyMedium(
                                                      color: textPrimary)
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text('10:30',
                                              style: AppTypography.caption(
                                                  color: textMuted)),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lastMsg,
                                              style: AppTypography.bodySmall(
                                                color: contact.unreadCount > 0
                                                    ? textPrimary
                                                    : textSecondary,
                                              ).copyWith(
                                                fontWeight:
                                                    contact.unreadCount > 0
                                                        ? FontWeight.w500
                                                        : FontWeight.w400,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (contact.unreadCount > 0)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  left: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10),
                                              ),
                                              child: Text(
                                                '${contact.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w700,
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
        ),
      ),
    );
  }
}
