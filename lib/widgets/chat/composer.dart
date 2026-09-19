import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import 'attachment_sheet.dart';

/// Unified Composer used for both AI Chat and Private Chat.
/// - Enforces text-only in AI mode (NO attachments).
/// - Allows images only in Private mode (converts to Base64).
/// - Silently intercepts secret passcode ('1234') in AI mode to unlock private vault.
/// - Intercepts '/urgent' and '/clear' locally in Private mode.
class Composer extends StatefulWidget {
  final bool isPrivate;
  final ValueChanged<String>? onSubmitted;
  final Function(String base64Image, String fileName)? onImageAttached;
  final TextEditingController? controller;
  final String? hintText;
  final bool isSubmitting;

  const Composer({
    super.key,
    this.isPrivate = false,
    this.onSubmitted,
    this.onImageAttached,
    this.controller,
    this.hintText,
    this.isSubmitting = false,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _controller;
  bool _internalController = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _internalController = true;
    }
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!widget.isPrivate) {
      // ─── AI MODE PASSCODE INTERCEPTION ───
      final vault = Provider.of<VaultProvider>(context, listen: false);
      if (vault.verifyPasscode(text)) {
        // Silently intercept secret passcode: NEVER send to AI, NEVER save to chat history!
        vault.unlockPrivate(text);
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Private contacts unlocked.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    } else {
      // ─── PRIVATE MODE COMMAND INTERCEPTION ───
      final lower = text.toLowerCase();
      if (lower == '/urgent') {
        // Quick exit to AI chat with fallback prompt
        _controller.clear();
        final vault = Provider.of<VaultProvider>(context, listen: false);
        final ai = Provider.of<AiChatProvider>(context, listen: false);
        vault.lockAll();

        if (ai.activeChat == null) {
          ai.prefillPrompt('What is an API?');
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.aiChat,
            (route) => false,
          );
        }
        return;
      } else if (lower == '/clear') {
        // Clear private chat locally & in Firebase RTDB immediately
        _controller.clear();
        final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
        privateChat.clearActiveChat();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation cleared.'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    // Submit normal message
    widget.onSubmitted?.call(text);
    _controller.clear();
  }

  void _showAttachmentSheet() {
    AttachmentSheet.show(
      context,
      onImageSelected: (base64, name) {
        widget.onImageAttached?.call(base64, name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? MiraloColors.darkSurfaceInput
        : MiraloColors.lightSurfaceInput;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;
    final textPrimary = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final textMuted = isDark
        ? MiraloColors.darkTextMuted
        : MiraloColors.lightTextMuted;

    final hint = widget.hintText ??
        (widget.isPrivate ? 'Message...' : 'Ask anything...');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiraloSpacing.md,
        vertical: MiraloSpacing.xs,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(MiraloRadius.composer),
            border: Border.all(
              color: isDark ? const Color(0x12FFFFFF) : border,
              width: 0.6,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Media button: STRICTLY IMAGES ONLY in Private Mode; Hidden in AI Mode
              if (widget.isPrivate)
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  color: textMuted,
                  iconSize: 22,
                  onPressed: _showAttachmentSheet,
                  tooltip: 'Share Image',
                )
              else
                const SizedBox(width: MiraloSpacing.md),

              // Text input field
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 1,
                  style: MiraloTypography.bodyMedium(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: MiraloTypography.bodyMedium(color: textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),

              // Forward arrow send button
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MiraloColors.accent,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? MiraloColors.accent
                              : (isDark
                                  ? MiraloColors.darkSurfaceSecondary
                                  : MiraloColors.lightSurfaceSecondary),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            size: 20,
                            color: _hasText
                                ? Colors.white
                                : textMuted,
                          ),
                          onPressed: _hasText ? _handleSend : null,
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
