import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

// ─── Button variants ─────────────────────────────────────────────────────────

enum MiraloButtonVariant { primary, secondary, ghost, destructive }

class MiraloButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MiraloButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final double? height;

  const MiraloButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MiraloButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btn = _buildButton(context, isDark);
    if (expand) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }

  Widget _buildButton(BuildContext context, bool isDark) {
    switch (variant) {
      case MiraloButtonVariant.primary:
        return _PrimaryButton(
            label: label, onPressed: onPressed, icon: icon,
            isLoading: isLoading, height: height);
      case MiraloButtonVariant.secondary:
        return _SecondaryButton(
            label: label, onPressed: onPressed, icon: icon,
            isLoading: isLoading, isDark: isDark, height: height);
      case MiraloButtonVariant.ghost:
        return _GhostButton(
            label: label, onPressed: onPressed, icon: icon,
            isLoading: isLoading, isDark: isDark, height: height);
      case MiraloButtonVariant.destructive:
        return _DestructiveButton(
            label: label, onPressed: onPressed, icon: icon,
            isLoading: isLoading, isDark: isDark, height: height);
    }
  }
}

// ─── Primary ──────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? height;
  const _PrimaryButton(
      {required this.label, this.onPressed, this.icon,
       this.isLoading = false, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
        ),
        child: _content(Colors.white),
      ),
    );
  }

  Widget _content(Color color) {
    if (isLoading) {
      return const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white));
    }
    if (icon != null) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.button(color: color)),
      ]);
    }
    return Text(label, style: AppTypography.button(color: color));
  }
}

// ─── Secondary ────────────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDark;
  final double? height;
  const _SecondaryButton(
      {required this.label, this.onPressed, this.icon,
       this.isLoading = false, required this.isDark, this.height});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return SizedBox(
      height: height ?? 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: bg,
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
        ),
        child: icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(label, style: AppTypography.button(color: fg)),
              ])
            : Text(label, style: AppTypography.button(color: fg)),
      ),
    );
  }
}

// ─── Ghost ────────────────────────────────────────────────────────────────────
class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDark;
  final double? height;
  const _GhostButton(
      {required this.label, this.onPressed, this.icon,
       this.isLoading = false, required this.isDark, this.height});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return SizedBox(
      height: height ?? 52,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
        ),
        child: Text(label, style: AppTypography.button(color: fg)),
      ),
    );
  }
}

// ─── Destructive ──────────────────────────────────────────────────────────────
class _DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDark;
  final double? height;
  const _DestructiveButton(
      {required this.label, this.onPressed, this.icon,
       this.isLoading = false, required this.isDark, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger.withValues(alpha: 0.1),
          foregroundColor: AppColors.danger,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
        ),
        child: Text(label, style: AppTypography.button(color: AppColors.danger)),
      ),
    );
  }
}
