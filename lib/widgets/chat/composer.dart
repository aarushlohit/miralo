import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/routes/app_routes.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import 'attachment_sheet.dart';

/// Unified Composer used for both AI Chat and Private Chat.
/// - Supports text + max 1 image attachment preview in AI mode.
/// - Supports live voice dictation via SpeechToText.
/// - Allows images in Private mode (converts to Base64).
/// - Silently intercepts secret passcode in AI mode to unlock private vault.
/// - Intercepts '/urgent' and '/clear' locally in Private mode.
class Composer extends StatefulWidget {
  final bool isPrivate;
  final ValueChanged<String>? onSubmitted;
  final Function(String text, String? base64Image)? onSubmittedWithImage;
  final Function(String base64Image, String fileName)? onImageAttached;
  final TextEditingController? controller;
  final String? hintText;
  final bool isSubmitting;

  const Composer({
    super.key,
    this.isPrivate = false,
    this.onSubmitted,
    this.onSubmittedWithImage,
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
  String? _attachedImageBase64;
  String? _attachedImageName;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

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
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
    }
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);
      try {
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _controller.text = result.recognizedWords;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                _hasText = _controller.text.trim().isNotEmpty;
              });
            }
          },
        );
      } catch (e) {
        if (mounted) setState(() => _isListening = false);
      }
    }
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _controller.removeListener(_onTextChanged);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedImageBase64 == null) return;

    if (!widget.isPrivate) {
      // ─── AI MODE PASSCODE INTERCEPTION ───
      final vault = Provider.of<VaultProvider>(context, listen: false);
      if (vault.verifyPasscode(text)) {
        // Silently intercept secret passcode: NEVER send to AI, NEVER save to chat history!
        vault.unlockPrivate(text);
        _controller.clear();
        setState(() {
          _attachedImageBase64 = null;
          _attachedImageName = null;
        });
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
      if (lower == '/logout') {
        // Intercept /logout command: Lock everything and return to AI Chat immediately
        _controller.clear();
        final vault = Provider.of<VaultProvider>(context, listen: false);
        vault.lockAll();

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out of private workspace.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      } else if (lower == '/urgent') {
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
      } else if (lower == '/naughty') {
        // Intercept /naughty command: Send random lovey-dovey Truth or Dare!
        _controller.clear();
        final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
        final dares = [
          "Truth 💕: What was your very first impression of me?",
          "Dare 🔥: Send a cute voice note saying something sweet.",
          "Truth 💓: What is one secret thing that always makes you smile about me?",
          "Dare 💋: Hold my gaze for 10 seconds without laughing!",
          "Truth 💖: What is your favorite memory of us together?",
          "Dare 💫: Give me a soft compliment right now.",
        ];
        dares.shuffle();
        final picked = dares.first;
        privateChat.sendTextMessage(picked);
        return;
      }
    }

    // Submit normal message
    final img = _attachedImageBase64;
    if (widget.onSubmittedWithImage != null) {
      widget.onSubmittedWithImage!(text, img);
    } else {
      widget.onSubmitted?.call(text);
    }
    _controller.clear();
    setState(() {
      _attachedImageBase64 = null;
      _attachedImageName = null;
    });
  }

  void _showAttachmentSheet() {
    AttachmentSheet.show(
      context,
      onImageSelected: (urlOrBase64, name) {
        if (widget.isPrivate) {
          widget.onImageAttached?.call(urlOrBase64, name);
        } else {
          setState(() {
            _attachedImageBase64 = urlOrBase64;
            _attachedImageName = name;
          });
        }
      },
      onDocumentSelected: (docUrlOrBase64, name, size) {
        if (widget.isPrivate) {
          final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
          privateChat.sendMediaMessage(
            type: 'document',
            mediaUrl: docUrlOrBase64.startsWith('http') ? docUrlOrBase64 : null,
            imageBase64: docUrlOrBase64.startsWith('http') ? null : docUrlOrBase64,
            fileName: name,
            fileSize: size,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attached document: $name ($size)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
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

    final canSend = _hasText || _attachedImageBase64 != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiraloSpacing.md,
        vertical: MiraloSpacing.xs,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Max 1 Attached Image Preview Chip
            if (_attachedImageBase64 != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222222) : const Color(0xFFEBECEF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF282828) : const Color(0xFFD0D4DC),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        base64Decode(_attachedImageBase64!),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        _attachedImageName ?? 'Image attached',
                        style: MiraloTypography.bodySmall(color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _attachedImageBase64 = null;
                          _attachedImageName = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        child: Icon(Icons.close_rounded, size: 14, color: textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // Input Row
            Container(
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
                  // Image attachment button (Camera / Gallery) - Max 1 in AI mode, available in both
                  IconButton(
                    icon: Icon(
                      widget.isPrivate
                          ? Icons.add_photo_alternate_outlined
                          : Icons.add_rounded,
                    ),
                    color: _attachedImageBase64 != null ? MiraloColors.accent : textMuted,
                    iconSize: 22,
                    onPressed: _showAttachmentSheet,
                    tooltip: widget.isPrivate ? 'Share Image' : 'Attach Image (Max 1)',
                  ),

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

                  // Microphone voice dictation button
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 20,
                      color: _isListening ? Colors.redAccent : textMuted,
                    ),
                    onPressed: _toggleListening,
                    tooltip: _isListening ? 'Stop dictating' : 'Voice dictation',
                  ),

                  // Send button
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: widget.isSubmitting
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: MiraloColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.stop_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                final ai = Provider.of<AiChatProvider>(context, listen: false);
                                ai.stopStreaming();
                              },
                              tooltip: 'Stop response',
                            ),
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: canSend
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
                                color: canSend
                                    ? Colors.white
                                    : textMuted,
                              ),
                              onPressed: canSend ? _handleSend : null,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
