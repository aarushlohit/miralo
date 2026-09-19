import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Attachment bottom sheet — clean, minimal, monochrome icons.
/// Used by both AI composer and private composer.
class AttachmentSheet extends StatelessWidget {
  final bool isPrivate;
  const AttachmentSheet({super.key, this.isPrivate = false});

  static Future<void> show(BuildContext context, {bool isPrivate = false}) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => AttachmentSheet(isPrivate: isPrivate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

    final actions = [
      _AttachAction(
          icon: Icons.camera_alt_outlined, label: 'Camera', color: textColor, bgColor: iconBg),
      _AttachAction(
          icon: Icons.photo_library_outlined, label: 'Photos', color: textColor, bgColor: iconBg),
      _AttachAction(
          icon: Icons.insert_drive_file_outlined, label: 'Files', color: textColor, bgColor: iconBg),
      if (isPrivate)
        _AttachAction(
            icon: Icons.gif_box_outlined, label: 'GIF', color: textColor, bgColor: iconBg),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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

            // Icon grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions
                  .map((a) => _AttachItem(action: a, subColor: subColor))
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: AppTypography.bodyMedium(color: subColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _AttachAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bgColor});
}

class _AttachItem extends StatelessWidget {
  final _AttachAction action;
  final Color subColor;
  const _AttachItem({required this.action, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: action.bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(action.icon, size: 26, color: action.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(action.label,
              style: AppTypography.caption(color: subColor)),
        ],
      ),
    );
  }
}
