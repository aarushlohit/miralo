import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/miralo_tokens.dart';
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
        horizontal: MiraloSpacing.md,
        vertical: MiraloSpacing.xs,
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
                    ? (isDark ? MiraloColors.accent.withValues(alpha: 0.18) : MiraloColors.accent.withValues(alpha: 0.12))
                    : bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: Border.all(
                  color: isHighlighted
                      ? MiraloColors.accent
                      : (isDark
                          ? (isMe ? const Color(0x12FFFFFF) : const Color(0x0CFFFFFF))
                          : border),
                  width: isHighlighted ? 1.4 : 0.6,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: MiraloColors.accent.withValues(alpha: 0.25),
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

                        // Quoted reply box if retagged/replied
                        if (replyToText != null && replyToText!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: MiraloSpacing.xs),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222222) : const Color(0xFFE2E6EE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(left: BorderSide(color: MiraloColors.accent, width: 3)),
                            ),
                            child: Text(
                              replyToText!,
                              style: MiraloTypography.bodySmall(
                                color: isDark ? MiraloColors.darkTextSecondary : MiraloColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        // Render Voice Note if type == 'voice'
                        if (isVoiceNote && (imageUrl != null || imageBase64 != null))
                          Padding(
                            padding: const EdgeInsets.only(bottom: MiraloSpacing.xs),
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
                              margin: const EdgeInsets.only(bottom: MiraloSpacing.xs),
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
                                  const Icon(Icons.insert_drive_file_rounded, color: MiraloColors.accent, size: 28),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName ?? 'Attached Document',
                                          style: MiraloTypography.bodyMedium(color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (fileSize != null)
                                          Text(
                                            fileSize!,
                                            style: MiraloTypography.bodySmall(color: textMuted),
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
                          _buildMessageText(
                            text,
                            MiraloTypography.bodyLarge(color: textPrimary).copyWith(height: 1.45),
                            isDark,
                          ),

                        const SizedBox(height: MiraloSpacing.xxs),

                        // Timestamp, status, and pin indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEdited) ...[
                              Text(
                                'edited ',
                                style: MiraloTypography.bodySmall(color: textMuted).copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            Text(
                              _formatTime(createdAt),
                              style: MiraloTypography.bodySmall(color: textMuted),
                            ),
                            if (isPinned) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: MiraloColors.accent,
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
                style: MiraloTypography.caption(color: textMuted).copyWith(
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
      padding: const EdgeInsets.only(bottom: MiraloSpacing.xs),
      child: ClipRRect(
        borderRadius: MiraloRadius.r12,
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

  void _showDocumentActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary;
    final textColor = isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary;
    final subColor = isDark ? MiraloColors.darkTextSecondary : MiraloColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MiraloRadius.bottomSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MiraloSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, color: MiraloColors.accent, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName ?? 'Attached Document',
                          style: MiraloTypography.titleMedium(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${fileSize ?? ''} • ${imageUrl != null && imageUrl!.startsWith('http') ? 'Cloudinary Hosted' : 'Encrypted Storage'}',
                          style: MiraloTypography.bodySmall(color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MiraloSpacing.md),
              const Divider(height: 1),
              if (imageUrl != null && imageUrl!.startsWith('http'))
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: MiraloColors.accent),
                  title: Text('Copy Cloudinary Download Link', style: MiraloTypography.bodyMedium(color: textColor)),
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
                  leading: const Icon(Icons.bookmark_add_outlined, color: MiraloColors.accent),
                  title: Text('Save to Library Vault', style: MiraloTypography.bodyMedium(color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSaveToLibrary?.call();
                  },
                ),
              if (onMoveToVault != null)
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: MiraloColors.accent),
                  title: Text('Move to Library Vault (Delete from chat)', style: MiraloTypography.bodyMedium(color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onMoveToVault?.call();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: MiraloColors.accent),
                title: Text('Download Document', style: MiraloTypography.bodyMedium(color: textColor)),
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
      return SelectableText(
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
          color: MiraloColors.accent,
          fontWeight: isAll ? FontWeight.w800 : FontWeight.w700,
          backgroundColor: MiraloColors.accent.withValues(
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

    return SelectableText.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }
}
