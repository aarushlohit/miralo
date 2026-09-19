import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Rounded text field with optional leading icon and label.
class MiraloTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool showToggleObscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  const MiraloTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.showToggleObscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
    this.maxLines = 1,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<MiraloTextField> createState() => _MiraloTextFieldState();
}

class _MiraloTextFieldState extends State<MiraloTextField> {
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill =
        isDark ? AppColors.darkSurfaceInput : AppColors.lightSurfaceInput;
    final hint = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final text =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!,
              style: AppTypography.label(color: text)
                  .copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.showToggleObscure ? _obscured : widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          maxLines: (widget.obscureText || widget.showToggleObscure)
              ? 1
              : widget.maxLines,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: AppTypography.body(color: text),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.body(color: hint),
            filled: true,
            fillColor: fill,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 18, color: iconColor)
                : null,
            suffixIcon: widget.showToggleObscure
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: iconColor,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            errorText: widget.errorText,
            errorStyle: AppTypography.caption(color: AppColors.danger),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: BorderSide(color: border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide:
                  const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
