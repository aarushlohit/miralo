import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/vault_provider.dart';

/// AI Composer — the main floating chat input bar.
///
/// CRITICAL:
/// - Intercepts private chat secret BEFORE sending to AI.
///   If text matches vault.privateSecret: silently unlocks and clears without alert.
/// - Text-based only: Does NOT allow images or documents for AI Chat per user specification.
/// - Right-arrow send button matching reference mockup (media_1789817732089.png).
class AiComposer extends StatefulWidget {
  final Function(String prompt) onSend;
  final VoidCallback? onAttach;
  final bool isStreaming;
  final String placeholder;

  const AiComposer({
    super.key,
    required this.onSend,
    this.onAttach,
    this.isStreaming = false,
    this.placeholder = 'Ask MIRALO AI...',
  });

  @override
  State<AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<AiComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Core interception logic — NEVER sends secret to AI
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;

    // ── SECRET INTERCEPTION ─────────────────────────────────────
    final vault = Provider.of<VaultProvider>(context, listen: false);
    if (vault.unlockPrivate(text)) {
      // Valid secret: clear field completely silently, unlock private access, return
      _controller.clear();
      return; // CRITICAL: do not call widget.onSend
    }

    // Normal AI send path
    _controller.clear();
    widget.onSend(text);
  }

  void _showTextOnlyNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'AI Chat is text-optimized. For encrypted files & media, use Library Vault or Private Space.',
          style: TextStyle(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
      ),
    );
  }

  void _showVoiceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceSheet(onDismiss: () => Navigator.pop(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hintColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.xs,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: MiraloDimensions.composerHeight,
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(MiraloDimensions.composerRadius),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Plus button (text-optimized prompt helper / notice)
              _IconBtn(
                icon: Icons.add_rounded,
                color: iconColor,
                tooltip: 'Prompt tools',
                onTap: _showTextOnlyNotice,
              ),

              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: AppTypography.body(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.body(color: hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    filled: false,
                  ),
                ),
              ),

              // Mic button
              _IconBtn(
                icon: Icons.mic_none_rounded,
                color: iconColor,
                tooltip: 'Voice dictation',
                onTap: _showVoiceSheet,
              ),

              // Circular blue send button with RIGHT ARROW
              _SendButton(
                isStreaming: widget.isStreaming,
                hasText: _hasText,
                onTap: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: color),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isStreaming;
  final bool hasText;
  final VoidCallback? onTap;

  const _SendButton({
    required this.isStreaming,
    this.hasText = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = hasText ? AppColors.accent : AppColors.accent.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: isStreaming
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
      ),
    );
  }
}

class _VoiceSheet extends StatelessWidget {
  final VoidCallback onDismiss;
  const _VoiceSheet({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Listening…', style: AppTypography.heading3(color: textColor)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Speak naturally. Tap anywhere to cancel.',
              style: AppTypography.bodySmall(color: subColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
