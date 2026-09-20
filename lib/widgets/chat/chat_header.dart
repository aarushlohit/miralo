import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Unified Chat Header for both AI Chat and Private Chat.
/// - AI mode: Menu/Back, Compact centered Model Selector pill, More options.
/// - Private mode: Back, Editable display name ('Mira', 'Active recently'), More menu with 'Return to Chat'.
/// - Strictly NO 'Private Chat', 'Secret', 'Girlfriend', 'Romantic', or 'Hidden'.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isPrivate;
  final String? title;
  final String? subtitle;
  final String? modelName;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onModelSelectorTap;
  final VoidCallback? onMoreOptions;
  final VoidCallback? onEditDisplayName;

  const ChatHeader({
    super.key,
    this.isPrivate = false,
    this.title,
    this.subtitle,
    this.modelName,
    this.onBack,
    this.onMenu,
    this.onModelSelectorTap,
    this.onMoreOptions,
    this.onEditDisplayName,
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
          ? GestureDetector(
              onTap: onEditDisplayName,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title ?? 'Chat',
                        style: MiraloTypography.titleMedium(color: textPrimary).copyWith(fontSize: 16),
                      ),
                      if (onEditDisplayName != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined, size: 16, color: textMuted),
                      ],
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: MiraloTypography.bodySmall(color: textMuted),
                    ),
                ],
              ),
            )
          : (onModelSelectorTap != null
              ? InkWell(
                  onTap: onModelSelectorTap,
                  borderRadius: BorderRadius.circular(MiraloRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? MiraloColors.darkSurfaceSecondary
                          : MiraloColors.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(MiraloRadius.pill),
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modelName ?? 'Model',
                          style: MiraloTypography.labelMedium(color: textPrimary).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: textMuted,
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
}
