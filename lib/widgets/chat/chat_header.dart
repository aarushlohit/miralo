import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Unified Chat Header for both AI Chat and Private Chat.
/// - AI mode: Menu/Back, Compact centered Model Selector pill, More options.
/// - Private mode: Back, Avatar with double-tap panic exit, Editable display name ('Mira', 'Active recently'), More menu with 'Return to Chat'.
/// - Strictly NO 'Private Chat', 'Secret', 'Girlfriend', 'Romantic', or 'Hidden'.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isPrivate;
  final String? title;
  final String? subtitle;
  final String? modelName;
  final String? avatarUrl;
  final String? avatarBase64;
  final bool isGroup;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onModelSelectorTap;
  final VoidCallback? onMoreOptions;
  final VoidCallback? onEditDisplayName;
  final VoidCallback? onDoubleTapAvatar;

  const ChatHeader({
    super.key,
    this.isPrivate = false,
    this.title,
    this.subtitle,
    this.modelName,
    this.avatarUrl,
    this.avatarBase64,
    this.isGroup = false,
    this.onBack,
    this.onMenu,
    this.onModelSelectorTap,
    this.onMoreOptions,
    this.onEditDisplayName,
    this.onDoubleTapAvatar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MiraloColors.darkBackground
        : MiraloColors.lightBackground;
    final textPrimary = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final textMuted = isDark
        ? MiraloColors.darkTextMuted
        : MiraloColors.lightTextMuted;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 60,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.6),
        child: Container(color: border, height: 0.6),
      ),
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
              color: textPrimary,
              onPressed: onBack,
              tooltip: 'Back',
            )
          : (onMenu != null
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 26),
                  color: textPrimary,
                  onPressed: onMenu,
                  tooltip: 'Menu',
                )
              : null),
      title: isPrivate
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: onDoubleTapAvatar,
                  child: _buildAvatar(context, isDark, textPrimary),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: GestureDetector(
                    onTap: onEditDisplayName,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title ?? 'Chat',
                                style: MiraloTypography.titleMedium(color: textPrimary).copyWith(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onEditDisplayName != null) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined, size: 16, color: textMuted),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (subtitle == 'Online') ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34C759),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Text(
                                subtitle!,
                                style: MiraloTypography.bodySmall(
                                  color: subtitle == 'Online'
                                      ? const Color(0xFF34C759)
                                      : textMuted,
                                ).copyWith(
                                  fontWeight: subtitle == 'Online'
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : (onModelSelectorTap != null
              ? InkWell(
                  onTap: onModelSelectorTap,
                  borderRadius: BorderRadius.circular(MiraloRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? MiraloColors.darkSurfaceSecondary
                          : MiraloColors.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(MiraloRadius.pill),
                      border: Border.all(color: border, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modelName ?? 'Model',
                          style: MiraloTypography.labelMedium(color: textPrimary).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: textPrimary,
                        ),
                      ],
                    ),
                  ),
                )
              : Text(
                  title ?? 'MIRALO AI',
                  style: MiraloTypography.titleMedium(color: textPrimary).copyWith(fontSize: 17),
                )),
      actions: [
        if (onMoreOptions != null)
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 26),
            color: textPrimary,
            onPressed: onMoreOptions,
            tooltip: 'Options',
          ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, bool isDark, Color textPrimary) {
    final bg = isDark
        ? MiraloColors.darkSurfaceSecondary
        : MiraloColors.lightSurfaceSecondary;

    Widget child;
    if (isGroup) {
      child = const Icon(
        Icons.groups_rounded,
        size: 20,
        color: MiraloColors.accent,
      );
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          avatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(textPrimary),
        ),
      );
    } else if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(avatarBase64!);
        child = ClipOval(
          child: Image.memory(
            bytes,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(textPrimary),
          ),
        );
      } catch (_) {
        child = _fallbackAvatar(textPrimary);
      }
    } else {
      child = _fallbackAvatar(textPrimary);
    }

    return Tooltip(
      message: 'Double-tap for quick panic exit',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(
            color: isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _fallbackAvatar(Color textPrimary) {
    final initial = (title != null && title!.trim().isNotEmpty)
        ? title!.trim()[0].toUpperCase()
        : 'M';
    return Text(
      initial,
      style: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}
