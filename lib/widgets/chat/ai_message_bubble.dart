import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/ai_chat_model.dart';

import '../common/miralo_logo.dart';

/// ChatGPT-style AI message bubble.
/// AI messages: full-width, left-aligned, no bubble — just text on background.
/// User messages: right-aligned soft container, neutral surface.
class AiMessageBubble extends StatelessWidget {
  final AiMessageModel message;
  final VoidCallback? onRegenerate;
  final Function(bool liked)? onLike;
  final Function(String editedText)? onEdit;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onLike,
    this.onEdit,
  });

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return _isUser
        ? _UserMessage(message: message, onEdit: onEdit)
        : _AiMessage(message: message, onLike: onLike, onRegenerate: onRegenerate);
  }
}

// ─── User message ─────────────────────────────────────────────────────────────

class _UserMessage extends StatelessWidget {
  final AiMessageModel message;
  final Function(String editedText)? onEdit;
  const _UserMessage({required this.message, this.onEdit});


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkMsgUser : AppColors.lightMsgUser;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xs, AppSpacing.screenH, AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.imageBase64 != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: Image.memory(
                            base64Decode(message.imageBase64!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                        ),
                      ),
                      if (message.text.isNotEmpty) const SizedBox(height: AppSpacing.xs + 4),
                    ],
                    if (message.text.isNotEmpty)
                      Text(message.text, style: AppTypography.body(color: textColor)),
                  ],
                ),
              ),
              if (onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: InkWell(
                    onTap: () => onEdit?.call(message.text),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 13, color: mutedColor),
                          const SizedBox(width: 3),
                          Text('Edit', style: AppTypography.caption(color: mutedColor)),
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

// ─── AI message ───────────────────────────────────────────────────────────────

class _AiMessage extends StatelessWidget {
  final AiMessageModel message;
  final Function(bool)? onLike;
  final VoidCallback? onRegenerate;

  const _AiMessage(
      {required this.message, this.onLike, this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final actionColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final text = message.text;
    final isEmpty = text.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MIRALO logo mark + label
          Row(
            children: [
              MiraloLogo(
                size: 20,
                showGlow: false,
                showSparkle: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('MIRALO AI',
                  style: AppTypography.label(color: mutedColor)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Message content
          if (isEmpty)
            _StreamingIndicator(isDark: isDark)
          else
            _MessageContent(text: text, textColor: textColor, isDark: isDark),

          // Action row
          if (!isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ActionRow(
              message: message,
              onLike: onLike,
              onRegenerate: onRegenerate,
              actionColor: actionColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _StreamingIndicator extends StatefulWidget {
  final bool isDark;
  const _StreamingIndicator({required this.isDark});

  @override
  State<_StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<_StreamingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: 0.4 + _c.value * 0.6,
        child: Container(
          width: 8,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─── Message content with full Markdown rendering ───────────────────────────

class _MessageContent extends StatelessWidget {
  final String text;
  final Color textColor;
  final bool isDark;

  const _MessageContent(
      {required this.text, required this.textColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _FormattedText(text: text, textColor: textColor);
  }
}

class _FormattedText extends StatelessWidget {
  final String text;
  final Color textColor;

  const _FormattedText({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: AppTypography.body(color: textColor).copyWith(height: 1.45),
        h1: AppTypography.heading1(color: textColor).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        h2: AppTypography.heading2(color: textColor).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        h3: AppTypography.heading3(color: textColor).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        h4: AppTypography.bodyMedium(color: textColor).copyWith(fontWeight: FontWeight.w600),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppColors.accent,
          backgroundColor: textColor.withValues(alpha: 0.08),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
        ),
        listBullet: TextStyle(color: textColor, fontSize: 14),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1)),
        ),
      ),
    );
  }
}

// ─── Action row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final AiMessageModel message;
  final Function(bool)? onLike;
  final VoidCallback? onRegenerate;
  final Color actionColor;

  const _ActionRow(
      {required this.message,
      this.onLike,
      this.onRegenerate,
      required this.actionColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Copy
        _ActionBtn(
          icon: Icons.copy_outlined,
          color: actionColor,
          tooltip: 'Copy',
          onTap: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copied to clipboard'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                margin: const EdgeInsets.all(AppSpacing.screenH),
              ),
            );
          },
        ),
        // Like
        _ActionBtn(
          icon: message.liked == true
              ? Icons.thumb_up
              : Icons.thumb_up_outlined,
          color: message.liked == true ? AppColors.accent : actionColor,
          tooltip: 'Good response',
          onTap: () => onLike?.call(true),
        ),
        // Dislike
        _ActionBtn(
          icon: message.liked == false
              ? Icons.thumb_down
              : Icons.thumb_down_outlined,
          color: message.liked == false ? AppColors.accent : actionColor,
          tooltip: 'Bad response',
          onTap: () => onLike?.call(false),
        ),
        // Regenerate
        if (onRegenerate != null)
          _ActionBtn(
            icon: Icons.refresh_rounded,
            color: actionColor,
            tooltip: 'Regenerate',
            onTap: onRegenerate,
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
