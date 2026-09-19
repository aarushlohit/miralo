import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/theme_provider.dart';
import 'miralo_avatar.dart';

/// MIRALO AI Sidebar Drawer — Clean ChatGPT-inspired design.
///
/// Key spec compliance:
/// - No "PRIVATE WORKSPACE" section header
/// - No unlock dialog in sidebar (secret is entered via AI composer)
/// - Contacts appear only after vault.isPrivateUnlocked
/// - Neutral "Contacts" section label only
/// - No Naughty Mode visible
/// - No flame icons
/// - Monochrome icons with blue accent for actions
/// - Avatar uses MiraloAvatar (deterministic blue, never amber/yellow)
class AppSidebarDrawer extends StatelessWidget {
  final bool isPersistent;
  final VoidCallback? onClose;

  const AppSidebarDrawer({
    super.key,
    this.isPersistent = false,
    this.onClose,
  });

  void _close(BuildContext context) {
    if (isPersistent) {
      onClose?.call();
    } else {
      Navigator.pop(context);
    }
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
                  icon: Icons.search_rounded,
                  color: textPrimary,
                  bg: iconBg,
                  tooltip: 'Search chats',
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(context, AppRoutes.home);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                // Close button (non-persistent)
                if (!isPersistent)
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
                    border: Border.all(color: border, width: 0.8),
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

                // Search chats
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Search chats',
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(context, AppRoutes.home);
                  },
                ),

                // Library
                _NavItem(
                  icon: Icons.auto_stories_outlined,
                  label: 'Library',
                  trailing: !vault.isLibraryUnlocked
                      ? Icon(Icons.lock_outline,
                          size: 14, color: textMuted)
                      : null,
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(
                      context,
                      vault.isLibraryUnlocked
                          ? AppRoutes.library
                          : AppRoutes.libraryLocked,
                    );
                  },
                ),

                // Settings
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    _close(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),

                // ── Pinned section ───────────────────────────────────
                if (ai.pinnedChats.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('PINNED', textMuted),
                  ...ai.pinnedChats.map((chat) => _ConvItem(
                        title: chat.title,
                        icon: Icons.push_pin_outlined,
                        onTap: () {
                          ai.openChat(chat.id);
                          _close(context);
                          Navigator.pushNamed(context, AppRoutes.chat);
                        },
                      )),
                ],

                // ── Recent section ───────────────────────────────────
                if (ai.recentChats.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('RECENT', textMuted),
                  ...ai.recentChats.take(8).map((chat) => _ConvItem(
                        title: chat.title,
                        onTap: () {
                          ai.openChat(chat.id);
                          _close(context);
                          Navigator.pushNamed(context, AppRoutes.chat);
                        },
                      )),
                ],

                // ── Private contacts (only after unlock) ─────────────
                // NO "PRIVATE WORKSPACE" label. Neutral "Contacts" only.
                if (vault.isPrivateUnlocked &&
                    privateChat.contacts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('CONTACTS', textMuted),
                  ...privateChat.contacts.map((contact) {
                    final displayName =
                        vault.hideMode.isEnabled &&
                                vault.hideMode.hidePrivateChatNames
                            ? 'Contact'
                            : contact.displayName;

                    return _ContactItem(
                      name: displayName,
                      isOnline: contact.isOnline,
                      unread: contact.unreadCount,
                      onTap: () {
                        privateChat.setActiveChat(contact.id);
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.privateChat);
                      },
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

                // Name + plan
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
                          user?.email ?? '',
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

    if (isPersistent) {
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
  final String title;
  final IconData? icon;
  final VoidCallback onTap;

  const _ConvItem({required this.title, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 8),
        child: Row(
          children: [
            Icon(icon ?? Icons.chat_bubble_outline_rounded,
                size: 16, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodySmall(color: textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
  final VoidCallback onTap;

  const _ContactItem({
    required this.name,
    required this.isOnline,
    required this.unread,
    required this.onTap,
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                    isOnline ? 'Online' : 'Last seen recently',
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(unread.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
