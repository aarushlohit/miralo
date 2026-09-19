import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../core/routes/app_routes.dart';
import 'attachment_sheet.dart';

/// Private composer — identical shape to AiComposer.
/// Intercepts /clear and /urgent slash commands before send.
class PrivateComposer extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback? onAttach;

  const PrivateComposer({
    super.key,
    required this.onSend,
    this.onAttach,
  });

  @override
  State<PrivateComposer> createState() => _PrivateComposerState();
}

class _PrivateComposerState extends State<PrivateComposer>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // ── /clear command ───────────────────────────────────────────
    if (text == '/clear') {
      _controller.clear();
      _showClearConfirmation();
      return;
    }

    // ── /urgent command ──────────────────────────────────────────
    if (text == '/urgent') {
      _controller.clear();
      _handleUrgent();
      return;
    }

    _controller.clear();
    widget.onSend(text);
  }

  void _showClearConfirmation() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary;
        final textColor = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        final subColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusSheet)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
              AppSpacing.md, AppSpacing.screenH, AppSpacing.xxl),
          child: SafeArea(
            top: false,
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
                Text('Clear this conversation?',
                    style: AppTypography.heading3(color: textColor)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'All messages will be permanently removed.',
                  style: AppTypography.bodySmall(color: subColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final chat = Provider.of<PrivateChatProvider>(
                          context, listen: false);
                      chat.clearActiveChat();
                    },
                    child: Text('Clear messages',
                        style: AppTypography.button(color: AppColors.danger)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel',
                        style: AppTypography.button(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleUrgent() {
    // Lock all private content
    final vault = Provider.of<VaultProvider>(context, listen: false);
    vault.emergencyLockEverything();

    // Navigate to last AI chat or empty chat with fallback question
    final ai = Provider.of<AiChatProvider>(context, listen: false);

    // Smooth transition ~200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (ai.activeChat != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.chat,
          (r) => r.settings.name == AppRoutes.home || r.isFirst,
        );
      } else {
        // Open home, prefill with fallback question
        ai.createNewChat();
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (r) => r.isFirst,
          arguments: {'prefill': 'What is an API?'},
        );
      }
    });
  }

  void _showAttachmentSheet() {
    if (widget.onAttach != null) {
      widget.onAttach!();
      return;
    }
    AttachmentSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceElevated;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hintColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm,
          AppSpacing.screenH, AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(AppSpacing.composerRadius),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.add_rounded, size: 22, color: iconColor),
                  tooltip: 'Attach',
                  onPressed: _showAttachmentSheet,
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    style: AppTypography.body(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: AppTypography.body(color: hintColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      filled: false,
                    ),
                  ),
                ),
              ),
              if (_hasText)
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 18),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Bar(height: 8 + _waveController.value * 6),
                          const SizedBox(width: 2.5),
                          _Bar(height: 14 - _waveController.value * 5),
                          const SizedBox(width: 2.5),
                          _Bar(height: 10 + _waveController.value * 7),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  const _Bar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
