import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onLike,
  });

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return _isUser ? _UserMessage(message: message) : _AiMessage(message: message, onLike: onLike, onRegenerate: onRegenerate);
  }
}

// ─── User message ─────────────────────────────────────────────────────────────

class _UserMessage extends StatelessWidget {
  final AiMessageModel message;
  const _UserMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkMsgUser : AppColors.lightMsgUser;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xs, AppSpacing.screenH, AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
            ),
            child: Text(message.text, style: AppTypography.body(color: textColor)),
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

// ─── Message content with code block support ─────────────────────────────────

class _MessageContent extends StatelessWidget {
  final String text;
  final Color textColor;
  final bool isDark;

  const _MessageContent(
      {required this.text, required this.textColor, required this.isDark});

  List<_Segment> _parse(String raw) {
    final segments = <_Segment>[];
    final codeBlockReg = RegExp(r'```(\w*)\n?([\s\S]*?)```', multiLine: true);
    int last = 0;

    for (final match in codeBlockReg.allMatches(raw)) {
      if (match.start > last) {
        segments.add(_Segment.text(raw.substring(last, match.start)));
      }
      segments.add(_Segment.code(match.group(2) ?? '', match.group(1) ?? ''));
      last = match.end;
    }
    if (last < raw.length) {
      segments.add(_Segment.text(raw.substring(last)));
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final segments = _parse(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((s) {
        if (s.isCode) {
          return _CodeBlock(code: s.content, language: s.language, isDark: isDark);
        }
        return _FormattedText(text: s.content, textColor: textColor);
      }).toList(),
    );
  }
}

class _Segment {
  final String content;
  final String language;
  final bool isCode;

  const _Segment.text(this.content)
      : isCode = false,
        language = '';
  const _Segment.code(this.content, this.language) : isCode = true;
}

class _FormattedText extends StatelessWidget {
  final String text;
  final Color textColor;

  const _FormattedText({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    // Simple markdown: **bold** and `inline code`
    return Text.rich(
      _buildSpan(text, textColor),
      style: AppTypography.body(color: textColor),
    );
  }

  TextSpan _buildSpan(String raw, Color color) {
    final spans = <InlineSpan>[];
    // Combine patterns
    final combined = RegExp(r'\*\*(.*?)\*\*|`([^`]+)`');
    int last = 0;

    for (final m in combined.allMatches(raw)) {
      if (m.start > last) {
        spans.add(TextSpan(text: raw.substring(last, m.start)));
      }
      if (m.group(1) != null) {
        // bold
        spans.add(TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (m.group(2) != null) {
        // inline code
        spans.add(TextSpan(
          text: m.group(2),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            backgroundColor: color.withValues(alpha: 0.08),
          ),
        ));
      }
      last = m.end;
    }
    if (last < raw.length) {
      spans.add(TextSpan(text: raw.substring(last)));
    }
    return TextSpan(children: spans);
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final bool isDark;

  const _CodeBlock(
      {required this.code, required this.language, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final labelColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text(language.isEmpty ? 'code' : language,
                    style: AppTypography.caption(color: labelColor)
                        .copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied',
                            style: AppTypography.caption(color: Colors.white)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                        margin: const EdgeInsets.all(AppSpacing.screenH),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined, size: 14, color: labelColor),
                      const SizedBox(width: 4),
                      Text('Copy',
                          style: AppTypography.caption(color: labelColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0.6, thickness: 0.6, color: border),
          // Code body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(code.trim(),
                style: AppTypography.mono(color: textColor)),
          ),
        ],
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
