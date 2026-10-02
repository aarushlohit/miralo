import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/longcat_tokens.dart';
import '../../services/base64_image_cache.dart';
import 'image_viewer.dart';
import 'voice_note_player.dart';

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
  final String? type;
  final String? fileName;
  final String? fileSize;
  final String? status;
  final String? replyToText;
  final String? replyToImageBase64;
  final String? replyToMediaUrl;
  final VoidCallback? onTapReply;
  final Map<String, int>? reactions;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSaveToLibrary;
  final VoidCallback? onMoveToVault;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final bool isPinned;
  final bool isStarred;
  final bool isHighlighted;
  final bool isEdited;
  final String? dateHeader;

  const MessageRenderer({
    super.key,
    required this.id,
    required this.text,
    required this.isMe,
    this.senderName,
    required this.createdAt,
    this.imageBase64,
    this.imageUrl,
    this.type,
    this.fileName,
    this.fileSize,
    this.status,
    this.replyToText,
    this.replyToImageBase64,
    this.replyToMediaUrl,
    this.onTapReply,
    this.reactions,
    this.onReactionTap,
    this.onLongPress,
    this.onSaveToLibrary,
    this.onMoveToVault,
    this.onDelete,
    this.onDownload,
    this.isPinned = false,
    this.isStarred = false,
    this.isHighlighted = false,
    this.isEdited = false,
    this.dateHeader,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Neutral message surfaces — identical geometry and neutral palette
    final bg = isMe
        ? (isDark ? LongcatColors.darkSurfaceElevated : LongcatColors.lightSurfaceSecondary)
        : (isDark ? LongcatColors.darkSurfacePrimary : LongcatColors.lightSurfacePrimary);

    final border = isMe
        ? (isDark ? LongcatColors.darkBorderHighlight : LongcatColors.lightBorderHighlight)
        : (isDark ? LongcatColors.darkBorder : LongcatColors.lightBorder);

    final textPrimary = isDark
        ? LongcatColors.darkTextPrimary
        : LongcatColors.lightTextPrimary;

    final textMuted = isDark
        ? LongcatColors.darkTextMuted
        : LongcatColors.lightTextMuted;

    final isVoiceNote = type == 'voice' || (fileName != null && fileName!.contains('Voice Note'));
    final isImage = type == 'image' ||
        type == 'gif' ||
        (imageBase64 != null && imageBase64!.isNotEmpty) ||
        (imageUrl != null &&
            imageUrl!.isNotEmpty &&
            (imageUrl!.contains('/image/') ||
                imageUrl!.contains('.gif') ||
                imageUrl!.contains('giphy.com') ||
                fileName?.toLowerCase().endsWith('.jpg') == true ||
                fileName?.toLowerCase().endsWith('.png') == true ||
                fileName?.toLowerCase().endsWith('.jpeg') == true ||
                fileName?.toLowerCase().endsWith('.gif') == true ||
                fileName?.toLowerCase().endsWith('.webp') == true));
    final isDocument = (type == 'document' || fileName != null) && !isVoiceNote && !isImage;

    final bubble = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LongcatSpacing.md,
        vertical: LongcatSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? (isDark ? LongcatColors.accent.withValues(alpha: 0.18) : LongcatColors.accent.withValues(alpha: 0.12))
                    : bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: Border.all(
                  color: isHighlighted
                      ? LongcatColors.accent
                      : (isDark
                          ? (isMe ? const Color(0x12FFFFFF) : const Color(0x0CFFFFFF))
                          : border),
                  width: isHighlighted ? 1.4 : 0.6,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: LongcatColors.accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LongcatSpacing.md,
                      vertical: LongcatSpacing.sm + 2,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Optional sender name for group / contact context
                        if (!isMe && senderName != null && senderName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: LongcatSpacing.xxs),
                            child: Text(
                              senderName!,
                              style: LongcatTypography.labelMedium(
                                color: LongcatColors.accent,
                              ),
                            ),
                          ),

                        // Quoted reply box if retagged/replied
                        if (replyToText != null && replyToText!.isNotEmpty)
                          InkWell(
                            onTap: onTapReply,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: LongcatSpacing.xs),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF222222) : const Color(0xFFE2E6EE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(color: LongcatColors.accent, width: 3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (replyToImageBase64 != null && replyToImageBase64!.isNotEmpty) ...[
                                    Builder(
                                      builder: (_) {
                                        final bytes = Base64ImageCache.getBytes(replyToImageBase64!);
                                        if (bytes == null) return const SizedBox.shrink();
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.memory(
                                            bytes,
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                            cacheWidth: 80,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                  ] else if (replyToMediaUrl != null &&
                                      replyToMediaUrl!.isNotEmpty &&
                                      replyToMediaUrl!.startsWith('http')) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        replyToMediaUrl!,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image, size: 24, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      replyToText!,
                                      style: LongcatTypography.bodySmall(
                                        color: isDark ? LongcatColors.darkTextSecondary : LongcatColors.lightTextSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Render Voice Note if type == 'voice'
                        if (isVoiceNote && (imageUrl != null || imageBase64 != null))
                          Padding(
                            padding: const EdgeInsets.only(bottom: LongcatSpacing.xs),
                            child: VoiceNotePlayer(
                              audioUrlOrBase64: imageUrl ?? imageBase64 ?? '',
                              durationText: fileSize,
                            ),
                          )
                        // Render Image if present
                        else if (isImage)
                          _buildImageAttachment(context)
                        // Render Document if document file
                        else if (isDocument)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showDocumentActions(context),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: LongcatSpacing.xs),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.insert_drive_file_rounded, color: LongcatColors.accent, size: 28),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName ?? 'Attached Document',
                                          style: LongcatTypography.bodyMedium(color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (fileSize != null)
                                          Text(
                                            fileSize!,
                                            style: LongcatTypography.bodySmall(color: textMuted),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.download_rounded, size: 16, color: textMuted),
                                ],
                              ),
                            ),
                          ),

                        // Render text with styled @ mentions and @all highlights
                        if (text.isNotEmpty)
                          if (type == 'redacted')
                            _RedactedMessageWidget(
                              text: text,
                              baseStyle: LongcatTypography.bodyLarge(color: textPrimary).copyWith(height: 1.45),
                              isDark: isDark,
                            )
                          else
                            _buildMessageText(
                              text,
                              LongcatTypography.bodyLarge(color: textPrimary).copyWith(height: 1.45),
                              isDark,
                            ),

                        const SizedBox(height: LongcatSpacing.xxs),

                        // Timestamp, status, and pin indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEdited) ...[
                              Text(
                                'edited ',
                                style: LongcatTypography.bodySmall(color: textMuted).copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            Text(
                              _formatTime(createdAt),
                              style: LongcatTypography.bodySmall(color: textMuted),
                            ),
                            if (isPinned) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: LongcatColors.accent,
                              ),
                            ],
                            if (isStarred) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Color(0xFFF59E0B),
                              ),
                            ],
                            if (isMe && status != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                (status == 'seen' || status == 'read')
                                    ? Icons.done_all_rounded
                                    : (status == 'delivered'
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded),
                                size: 14,
                                color: (status == 'seen' || status == 'read')
                                    ? LongcatColors.accent
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

    if (dateHeader != null && dateHeader!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateHeader!,
                style: LongcatTypography.caption(color: textMuted).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          bubble,
        ],
      );
    }

    return bubble;
  }

  Widget _buildImageAttachment(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LongcatSpacing.xs),
      child: ClipRRect(
        borderRadius: LongcatRadius.r12,
        child: GestureDetector(
          onTap: () {
            ImageViewer.show(
              context,
              imageBase64: imageBase64,
              imageUrl: imageUrl,
              title: fileName ?? 'Image',
              onMoveToVault: onMoveToVault,
              onSaveToLibrary: onSaveToLibrary,
            );
          },
          child: _renderImage(),
        ),
      ),
    );
  }

  Widget _renderImage() {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      final bytes = Base64ImageCache.getBytes(imageBase64!);
      if (bytes != null) {
        return Image.memory(
          bytes,
          key: ValueKey('img_$id'),
          width: 240,
          height: 180,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 480,
          errorBuilder: (_, _, _) => _buildImagePlaceholder(),
        );
      }
    }

    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        key: ValueKey('img_$id'),
        width: 240,
        height: 180,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: 480,
        errorBuilder: (_, _, _) => _buildImagePlaceholder(),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 240,
      height: 160,
      color: LongcatColors.darkSurfaceSecondary,
      child: const Center(
        child: Icon(Icons.image_outlined, color: LongcatColors.darkTextMuted, size: 36),
      ),
    );
  }

  Widget _buildReactionsRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: LongcatSpacing.xs),
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
                    ? LongcatColors.darkSurfaceSecondary
                    : LongcatColors.lightSurfaceTertiary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? LongcatColors.darkBorder : LongcatColors.lightBorder,
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
                      style: LongcatTypography.bodySmall(
                        color: isDark
                            ? LongcatColors.darkTextSecondary
                            : LongcatColors.lightTextSecondary,
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

  void _showDocumentActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? LongcatColors.darkSurfacePrimary : LongcatColors.lightSurfacePrimary;
    final textColor = isDark ? LongcatColors.darkTextPrimary : LongcatColors.lightTextPrimary;
    final subColor = isDark ? LongcatColors.darkTextSecondary : LongcatColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LongcatRadius.bottomSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LongcatSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: LongcatSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? LongcatColors.darkBorder : LongcatColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, color: LongcatColors.accent, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName ?? 'Attached Document',
                          style: LongcatTypography.titleMedium(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${fileSize ?? ''} • ${imageUrl != null && imageUrl!.startsWith('http') ? 'Cloudinary Hosted' : 'Encrypted Storage'}',
                          style: LongcatTypography.bodySmall(color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LongcatSpacing.md),
              const Divider(height: 1),
              if (imageUrl != null && imageUrl!.startsWith('http'))
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: LongcatColors.accent),
                  title: Text('Copy Cloudinary Download Link', style: LongcatTypography.bodyMedium(color: textColor)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: imageUrl!));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cloud link copied to clipboard.')),
                    );
                  },
                ),
              if (onSaveToLibrary != null)
                ListTile(
                  leading: const Icon(Icons.bookmark_add_outlined, color: LongcatColors.accent),
                  title: Text('Save to Library Vault', style: LongcatTypography.bodyMedium(color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSaveToLibrary?.call();
                  },
                ),
              if (onMoveToVault != null)
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: LongcatColors.accent),
                  title: Text('Move to Library Vault (Delete from chat)', style: LongcatTypography.bodyMedium(color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onMoveToVault?.call();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: LongcatColors.accent),
                title: Text('Download Document', style: LongcatTypography.bodyMedium(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (onDownload != null) {
                    onDownload!();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${fileName ?? "document"}...')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageText(String messageText, TextStyle baseStyle, bool isDark) {
    final mentionRegex = RegExp(r'(@[a-zA-Z0-9_]+)');
    final matches = mentionRegex.allMatches(messageText);

    if (matches.isEmpty) {
      return Text(
        messageText,
        style: baseStyle,
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: messageText.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final mention = match.group(0)!;
      final isAll = mention.toLowerCase() == '@all';

      spans.add(TextSpan(
        text: mention,
        style: baseStyle.copyWith(
          color: LongcatColors.accent,
          fontWeight: isAll ? FontWeight.w800 : FontWeight.w700,
          backgroundColor: LongcatColors.accent.withValues(
            alpha: isAll ? (isDark ? 0.28 : 0.16) : (isDark ? 0.15 : 0.08),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < messageText.length) {
      spans.add(TextSpan(
        text: messageText.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }
}

class _RedactedMessageWidget extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final bool isDark;

  const _RedactedMessageWidget({
    required this.text,
    required this.baseStyle,
    required this.isDark,
  });

  @override
  State<_RedactedMessageWidget> createState() => _RedactedMessageWidgetState();
}

class _RedactedMessageWidgetState extends State<_RedactedMessageWidget> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = !_revealed),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _revealed
              ? (widget.isDark ? Colors.black45 : Colors.grey.shade200)
              : (widget.isDark ? Colors.black : Colors.black87),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 14,
              color: _revealed ? Colors.grey : Colors.amber,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _revealed ? widget.text : '████████ [REDACTED - Tap to reveal]',
                style: widget.baseStyle.copyWith(
                  color: _revealed
                      ? (widget.isDark ? Colors.white70 : Colors.black87)
                      : Colors.amber,
                  fontFamily: _revealed ? null : 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
