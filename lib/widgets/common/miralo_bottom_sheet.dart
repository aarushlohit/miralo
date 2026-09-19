import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Standardized rounded bottom sheet with drag handle + optional title.
class MiraloBottomSheet extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const MiraloBottomSheet({
    super.key,
    this.title,
    required this.children,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<Widget> children,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: true,
      isScrollControlled: true,
      builder: (_) => MiraloBottomSheet(title: title, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      padding: padding ??
          EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(title!,
                  style: AppTypography.heading3(color: textColor)),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// A clean action row item for bottom sheets
class MiraloSheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const MiraloSheetAction({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.bodyMedium(color: fg)),
          ],
        ),
      ),
    );
  }
}
