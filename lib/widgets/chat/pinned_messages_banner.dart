import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../models/private_message_model.dart';

/// WhatsApp-style sticky banner at the top of a DM or Group Chat
/// displaying up to 6 pinned messages with multi-pin indicators,
/// cycling on tap, jump-to-message, and quick unpin actions.
class PinnedMessagesBanner extends StatefulWidget {
  final List<PrivateMessageModel> pinnedMessages;
  final String? currentUserId;
  final ValueChanged<PrivateMessageModel> onTapMessage;
  final ValueChanged<PrivateMessageModel>? onUnpinMessage;
  final VoidCallback? onViewAll;

  const PinnedMessagesBanner({
    super.key,
    required this.pinnedMessages,
    this.currentUserId,
    required this.onTapMessage,
    this.onUnpinMessage,
    this.onViewAll,
  });

  @override
  State<PinnedMessagesBanner> createState() => _PinnedMessagesBannerState();
}

class _PinnedMessagesBannerState extends State<PinnedMessagesBanner> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant PinnedMessagesBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.pinnedMessages.length) {
      _currentIndex = widget.pinnedMessages.isEmpty ? 0 : widget.pinnedMessages.length - 1;
    }
  }

  void _handleTap() {
    if (widget.pinnedMessages.isEmpty) return;
    final msg = widget.pinnedMessages[_currentIndex];
    widget.onTapMessage(msg);

    // Cycle to next pinned message on tap (WhatsApp behavior)
    if (widget.pinnedMessages.length > 1) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.pinnedMessages.length;
      });
    }
  }

  String _formatSnippet(PrivateMessageModel msg) {
    if (msg.type == 'image') {
      return msg.text.isNotEmpty ? '📷 ${msg.text}' : '📷 Photo';
    }
    if (msg.isGif) {
      return msg.text.isNotEmpty ? 'GIF • ${msg.text}' : 'GIF Animation';
    }
    if (msg.type == 'voice' || (msg.fileName != null && msg.fileName!.contains('Voice Note'))) {
      return '🎤 Voice note';
    }
    if (msg.type == 'file' || msg.fileName != null) {
      return '📎 ${msg.fileName ?? 'Document'}';
    }
    return msg.text.isNotEmpty ? msg.text : 'Attachment';
  }

  String _getSenderLabel(PrivateMessageModel msg) {
    if (msg.isMe || (widget.currentUserId != null && msg.senderId == widget.currentUserId)) {
      return 'You';
    }
    return msg.senderName ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedMessages.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.pinnedMessages.length;
    final safeIndex = _currentIndex < count ? _currentIndex : 0;
    final activeMsg = widget.pinnedMessages[safeIndex];

    final bg = isDark
        ? MiraloColors.darkSurfacePrimary.withValues(alpha: 0.95)
        : MiraloColors.lightSurfacePrimary.withValues(alpha: 0.95);
    final borderColor = isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder;
    final textPrimary = isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary;
    final textMuted = isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WhatsApp-style Multi-pinned Dash Indicators (if >1 message pinned)
          if (count > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Row(
                children: List.generate(count, (idx) {
                  final isActive = idx == safeIndex;
                  return Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? MiraloColors.accent
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  );
                }),
              ),
            ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              onLongPress: widget.onViewAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Vertical Accent Bar Indicator
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: MiraloColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Pin Icon in rounded background
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MiraloColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.push_pin_rounded,
                        size: 14,
                        color: MiraloColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Pinned Header & Text Snippet
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pinned message',
                                style: MiraloTypography.labelMedium(
                                  color: MiraloColors.accent,
                                ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                              if (count > 1) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '• ${safeIndex + 1}/$count',
                                  style: MiraloTypography.bodySmall(
                                    color: textMuted,
                                  ).copyWith(fontSize: 11),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(
                                '(${_getSenderLabel(activeMsg)})',
                                style: MiraloTypography.bodySmall(
                                  color: textMuted,
                                ).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _formatSnippet(activeMsg),
                            style: MiraloTypography.bodySmall(
                              color: textPrimary,
                            ).copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // View all sheet button
                    if (widget.onViewAll != null)
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                        color: textMuted,
                        tooltip: 'View all pinned ($count/6)',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: widget.onViewAll,
                      ),

                    // Quick Unpin button
                    if (widget.onUnpinMessage != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: textMuted,
                        tooltip: 'Unpin message',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => widget.onUnpinMessage!(activeMsg),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
