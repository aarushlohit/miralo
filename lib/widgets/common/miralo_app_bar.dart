import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// MIRALO AI — Bespoke Navigation Bar
/// Replaces generic Material AppBar with reference-accurate Apple/ChatGPT geometry:
/// - 38–40px circular leading action (hamburger / back)
/// - 18–20px semibold title or custom center widget (e.g. model selector pill)
/// - Circular trailing action or avatar
/// - Clean transparent surface, zero drop shadow
class MiraloAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final VoidCallback? onLeadingTap;
  final IconData? leadingIcon;
  final String? leadingTooltip;
  final List<Widget>? actions;
  final bool showBottomBorder;
  final Color? backgroundColor;

  const MiraloAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.onLeadingTap,
    this.leadingIcon,
    this.leadingTooltip,
    this.actions,
    this.showBottomBorder = false,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.darkBackground : AppColors.lightBackground);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && leadingIcon != null) {
      leadingWidget = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(leadingIcon, color: textPrimary, size: 20),
          onPressed: onLeadingTap,
          tooltip: leadingTooltip,
        ),
      );
    }

    return Container(
      color: bg,
      decoration: showBottomBorder
          ? BoxDecoration(
              color: bg,
              border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            )
          : null,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Row(
            children: [
              // Leading
              if (leadingWidget != null)
                leadingWidget
              else
                const SizedBox(width: 38),

              // Title
              Expanded(
                child: Center(
                  child: titleWidget ??
                      Text(
                        title ?? '',
                        style: AppTypography.wordmark(color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                ),
              ),

              // Actions / Trailing
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              else
                const SizedBox(width: 38),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard circular icon button used in Miralo navigation bars and headers.
class MiraloCircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;

  const MiraloCircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 38,
    this.iconSize = 20,
    this.tooltip,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary);
    final iconColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: iconSize),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

