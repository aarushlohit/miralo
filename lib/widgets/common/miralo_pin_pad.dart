import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Numeric PIN pad used for Library Vault and private credential entry.
class MiraloPinPad extends StatefulWidget {
  final int pinLength;
  final String? title;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onComplete;
  final VoidCallback? onBiometric;
  final String? errorText;
  final bool showBiometric;

  const MiraloPinPad({
    super.key,
    this.pinLength = 4,
    this.title,
    this.onCompleted,
    this.onComplete,
    this.onBiometric,
    this.errorText,
    this.showBiometric = true,
  });

  @override
  State<MiraloPinPad> createState() => MiraloPinPadState();
}

class MiraloPinPadState extends State<MiraloPinPad> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length >= widget.pinLength) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    if (_pin.length == widget.pinLength) {
      (widget.onCompleted ?? widget.onComplete)?.call(_pin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void reset() => setState(() => _pin = '');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final dotFill = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final dotEmpty = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final btnBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final btnBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pinLength, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? dotFill : Colors.transparent,
                border: Border.all(
                  color: filled ? dotFill : dotEmpty,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),

        // Error message
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(widget.errorText!,
              style: AppTypography.caption(color: AppColors.danger)),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Keypad
        ...([
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['bio', '0', 'del'],
        ]).map((row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key == 'bio') {
                    return _PadKey(
                      onTap: widget.showBiometric ? widget.onBiometric : null,
                      bg: Colors.transparent,
                      border: Colors.transparent,
                      child: widget.showBiometric && widget.onBiometric != null
                          ? Icon(Icons.fingerprint, color: mutedColor, size: 26)
                          : const SizedBox(),
                    );
                  } else if (key == 'del') {
                    return _PadKey(
                      onTap: _onDelete,
                      bg: Colors.transparent,
                      border: Colors.transparent,
                      child: Icon(Icons.backspace_outlined,
                          color: textColor, size: 20),
                    );
                  } else {
                    return _PadKey(
                      onTap: () => _onDigit(key),
                      bg: btnBg,
                      border: btnBorder,
                      child: Text(key,
                          style: AppTypography.heading2(color: textColor)),
                    );
                  }
                }).toList(),
              ),
            )),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color bg;
  final Color border;

  const _PadKey(
      {required this.child,
      this.onTap,
      required this.bg,
      required this.border});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 0.8),
        ),
        child: Center(child: child),
      ),
    );
  }
}
