import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../models/private_message_model.dart';
import '../common/miralo_avatar.dart';

/// Modal bottom sheet displaying all pinned messages in the chat (up to 6).
class PinnedMessagesSheet extends StatelessWidget {
  final List<PrivateMessageModel> pinnedMessages;
  final ValueChanged<PrivateMessageModel> onTapMessage;
  final ValueChanged<PrivateMessageModel>? onUnpinMessage;
  final VoidCallback? onUnpinAll;

  const PinnedMessagesSheet({
    super.key,
    required this.pinnedMessages,
    required this.onTapMessage,
    this.onUnpinMessage,
    this.onUnpinAll,
  });

  static void show(
    BuildContext context, {
    required List<PrivateMessageModel> pinnedMessages,
    required ValueChanged<PrivateMessageModel> onTapMessage,
    ValueChanged<PrivateMessageModel>? onUnpinMessage,
    VoidCallback? onUnpinAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? MiraloColors.darkSurfacePrimary
          : MiraloColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MiraloRadius.bottomSheet),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => PinnedMessagesSheet(
          pinnedMessages: pinnedMessages,
          onTapMessage: onTapMessage,
          onUnpinMessage: onUnpinMessage,
          onUnpinAll: onUnpinAll,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMediaThumbnail(PrivateMessageModel msg) {
    if (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            base64Decode(msg.imageBase64!),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          msg.mediaUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, size: 24),
        ),
      );
    }
    if (msg.type == 'voice' || (msg.fileName != null && msg.fileName!.contains('Voice Note'))) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MiraloColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.mic_rounded, color: MiraloColors.accent, size: 22),
      );
    }
    if (msg.type == 'file' || msg.fileName != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MiraloColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.description_rounded, color: MiraloColors.accent, size: 22),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: MiraloColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.chat_bubble_outline_rounded, color: MiraloColors.accent, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary;
    final textMuted = isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted;
    final border = isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder;
    final surfaceSecondary = isDark ? MiraloColors.darkSurfaceSecondary : MiraloColors.lightSurfaceSecondary;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: MiraloSpacing.sm),
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MiraloSpacing.lg,
              vertical: MiraloSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: MiraloColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pinned Messages',
                  style: MiraloTypography.titleMedium(color: textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: MiraloColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pinnedMessages.length}/6',
                    style: TextStyle(
                      color: MiraloColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (pinnedMessages.length > 1 && onUnpinAll != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onUnpinAll?.call();
                    },
                    child: Text(
                      'Unpin all',
                      style: MiraloTypography.labelMedium(color: MiraloColors.danger),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Messages list or empty state
          Expanded(
            child: pinnedMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin_outlined, size: 48, color: textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No pinned messages',
                          style: MiraloTypography.bodyMedium(color: textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Long press any message and tap "Pin Message" to pin up to 6 messages.',
                          style: MiraloTypography.bodySmall(color: textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(MiraloSpacing.md),
                    itemCount: pinnedMessages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: MiraloSpacing.sm),
                    itemBuilder: (ctx, idx) {
                      final msg = pinnedMessages[idx];
                      final senderName = msg.isMe ? 'You' : (msg.senderName ?? 'User');
                      final hasMedia = msg.type != 'text' || (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) || (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty);

                      return Material(
                        color: surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context);
                            onTapMessage(msg);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                if (hasMedia) ...[
                                  _buildMediaThumbnail(msg),
                                  const SizedBox(width: 12),
                                ] else ...[
                                  MiraloAvatar(name: senderName, size: 36),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            senderName,
                                            style: MiraloTypography.labelMedium(color: textPrimary)
                                                .copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatTime(msg.pinnedAt ?? msg.createdAt),
                                            style: MiraloTypography.bodySmall(color: textMuted)
                                                .copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msg.text.isNotEmpty
                                            ? msg.text
                                            : (msg.type == 'image'
                                                ? '📷 Photo'
                                                : (msg.isGif
                                                    ? 'GIF Animation'
                                                    : (msg.type == 'voice'
                                                        ? '🎤 Voice note'
                                                        : '📎 Document'))),
                                        style: MiraloTypography.bodyMedium(color: textPrimary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (onUnpinMessage != null)
                                  IconButton(
                                    icon: const Icon(Icons.push_pin_outlined, size: 20),
                                    color: MiraloColors.accent,
                                    tooltip: 'Unpin',
                                    onPressed: () {
                                      onUnpinMessage!(msg);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
