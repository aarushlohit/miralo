import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Settings-style list tile with leading icon, title, optional subtitle,
/// and trailing chevron or custom widget.
class MiraloListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final bool showDivider;
  final bool destructive;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const MiraloListTile({
    super.key,
    this.leadingIcon,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.showDivider = false,
    this.destructive = false,
    this.onTap,
    this.padding,
  });

  IconData? get _effectiveIcon => icon ?? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = destructive
        ? AppColors.danger
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final subColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconCol = destructive
        ? AppColors.danger
        : (iconColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));
    final chevronColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final tile = InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH, vertical: 13),
        child: Row(
          children: [
            if (_effectiveIcon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Icon(_effectiveIcon, size: 17, color: iconCol),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.bodyMedium(color: textColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTypography.caption(color: subColor)),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (trailing == null && showChevron)
              Icon(Icons.chevron_right_rounded, size: 18, color: chevronColor),
          ],
        ),
      ),
    );

    if (showDivider) {
      final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          Divider(
            height: 0.6,
            thickness: 0.6,
            color: border,
            indent: AppSpacing.screenH + 32 + AppSpacing.md,
          ),
        ],
      );
    }
    return tile;
  }
}

/// Section header for settings groups
class MiraloSectionHeader extends StatelessWidget {
  final String title;
  const MiraloSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall(
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}

/// Grouped card that wraps a list of MiraloListTiles with dividers
class MiraloSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final String? header;

  const MiraloSettingsGroup({
    super.key,
    required this.children,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) MiraloSectionHeader(header!),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: border, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 0.6,
                      thickness: 0.6,
                      color: border,
                      indent: AppSpacing.screenH + 32 + AppSpacing.md,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
