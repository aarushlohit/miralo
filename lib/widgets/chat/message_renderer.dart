import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';
import 'image_viewer.dart';

/// Unified Message Renderer used by BOTH AI Chat and Private Chat.
/// Uses neutral surfaces matching ChatGPT/Apple standards.
/// Strictly NO bright blue bubbles, NO WhatsApp styling, NO romantic gradients.
class MessageRenderer extends StatelessWidget {
  final String id;
  final String text;
  final bool isMe;
  final String? senderName;
  final DateTime createdAt;
  final String? imageBase64;
  final String? imageUrl;
  final String? status;
  final Map<String, int>? reactions;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSaveToLibrary;
  final VoidCallback? onDelete;

  const MessageRenderer({
    super.key,
    required this.id,
    required this.text,
    required this.isMe,
    this.senderName,
    required this.createdAt,
    this.imageBase64,
    this.imageUrl,
    this.status,
    this.reactions,
    this.onReactionTap,
    this.onLongPress,
    this.onSaveToLibrary,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Neutral message surfaces — identical geometry and neutral palette
    final bg = isMe
        ? (isDark ? MiraloColors.darkSurfaceElevated : MiraloColors.lightSurfaceSecondary)
        : (isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary);

    final border = isMe
        ? (isDark ? MiraloColors.darkBorderHighlight : MiraloColors.lightBorderHighlight)
        : (isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder);

    final textPrimary = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;

    final textMuted = isDark
        ? MiraloColors.darkTextMuted
        : MiraloColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MiraloSpacing.md,
        vertical: MiraloSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: Border.all(
                  color: isDark
                      ? (isMe ? const Color(0x12FFFFFF) : const Color(0x0CFFFFFF))
                      : border,
                  width: 0.6,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MiraloSpacing.md,
                      vertical: MiraloSpacing.sm + 2,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Optional sender name for group / contact context
                        if (!isMe && senderName != null && senderName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: MiraloSpacing.xxs),
                            child: Text(
                              senderName!,
                              style: MiraloTypography.labelMedium(
                                color: MiraloColors.accent,
                              ),
                            ),
                          ),

                        // Render Image if present
                        if (imageBase64 != null || imageUrl != null)
                          _buildImageAttachment(context),

                        // Render text
                        if (text.isNotEmpty)
                          SelectableText(
                            text,
                            style: MiraloTypography.bodyLarge(color: textPrimary)
                                .copyWith(height: 1.45),
                          ),

                        const SizedBox(height: MiraloSpacing.xxs),

                        // Timestamp and status
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(createdAt),
                              style: MiraloTypography.bodySmall(color: textMuted),
                            ),
                            if (isMe && status != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                status == 'read'
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 14,
                                color: status == 'read'
                                    ? MiraloColors.accent
                                    : textMuted,
                              ),
                            ],
                          ],
                        ),

                        // Reactions row
                        if (reactions != null && reactions!.isNotEmpty)
                          _buildReactionsRow(context, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageAttachment(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MiraloSpacing.xs),
      child: ClipRRect(
        borderRadius: MiraloRadius.r12,
        child: GestureDetector(
          onTap: () {
            ImageViewer.show(
              context,
              imageBase64: imageBase64,
              imageUrl: imageUrl,
              title: 'Image',
            );
          },
          child: _renderImage(),
        ),
      ),
    );
  }

  Widget _renderImage() {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64!);
        return Image.memory(
          bytes,
          width: 240,
          height: 180,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: 240,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildImagePlaceholder(),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 240,
      height: 160,
      color: MiraloColors.darkSurfaceSecondary,
      child: const Center(
        child: Icon(Icons.image_outlined, color: MiraloColors.darkTextMuted, size: 36),
      ),
    );
  }

  Widget _buildReactionsRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: MiraloSpacing.xs),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions!.entries.map((entry) {
          return InkWell(
            onTap: () => onReactionTap?.call(entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? MiraloColors.darkSurfaceSecondary
                    : MiraloColors.lightSurfaceTertiary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 13)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '${entry.value}',
                      style: MiraloTypography.bodySmall(
                        color: isDark
                            ? MiraloColors.darkTextSecondary
                            : MiraloColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
