import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/private_message_model.dart';

/// Private chat message bubble — IDENTICAL visual language to AI chat.
/// NOT WhatsApp-style. No bright color contrast. Same neutral surfaces.
/// Sender messages: slight elevation difference only, not color difference.
class PrivateMessageBubble extends StatelessWidget {
  final PrivateMessageModel message;
  final bool isMe;
  final Function(String emoji)? onReact;
  final VoidCallback? onDelete;

  const PrivateMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReact,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return isMe
        ? _MyMessage(message: message, onDelete: onDelete)
        : _TheirMessage(message: message, onReact: onReact);
  }
}

// ─── My message (sender) ─────────────────────────────────────────────────────

class _MyMessage extends StatelessWidget {
  final PrivateMessageModel message;
  final VoidCallback? onDelete;

  const _MyMessage({required this.message, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Slightly elevated surface — same neutral palette as AI chat
    final bg = isDark ? AppColors.darkMsgUser : AppColors.lightMsgUser;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final timeColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Padding(
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
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
                  ),
                  child: _messageContent(message, textColor, isDark),
                ),
                const SizedBox(height: 3),
                Text(_time(message.timestamp),
                    style: AppTypography.caption(color: timeColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _MessageActions(onDelete: onDelete),
    );
  }
}

// ─── Their message (receiver) ─────────────────────────────────────────────────

class _TheirMessage extends StatelessWidget {
  final PrivateMessageModel message;
  final Function(String)? onReact;

  const _TheirMessage({required this.message, this.onReact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final timeColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;

    return GestureDetector(
      onLongPress: () => _showReactions(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: _messageContent(message, textColor, isDark),
            ),
            if (message.reactions.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ReactionRow(reactions: message.reactions),
            ],
            const SizedBox(height: 3),
            Text(_time(message.timestamp),
                style: AppTypography.caption(color: timeColor)),
          ],
        ),
      ),
    );
  }

  void _showReactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ReactionPicker(onReact: onReact),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _messageContent(
    PrivateMessageModel message, Color textColor, bool isDark) {
  if (message.imageUrl != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Image.network(
        message.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined, size: 48),
      ),
    );
  }
  return Text(message.text, style: AppTypography.body(color: textColor));
}

String _time(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour = h % 12 == 0 ? 12 : h % 12;
  return '$hour:$m $period';
}

// ─── Reaction row ─────────────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  final Map<String, int> reactions;
  const _ReactionRow({required this.reactions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Wrap(
      spacing: 4,
      children: reactions.entries
          .map((entry) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 14)),
                    if (entry.value > 1) ...[
                      const SizedBox(width: 3),
                      Text('${entry.value}',
                          style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ─── Message actions sheet ────────────────────────────────────────────────────

class _MessageActions extends StatelessWidget {
  final VoidCallback? onDelete;
  const _MessageActions({this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md,
          AppSpacing.screenH, AppSpacing.xxl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy'),
              onTap: () => Navigator.pop(context),
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Reaction picker ─────────────────────────────────────────────────────────

class _ReactionPicker extends StatelessWidget {
  final Function(String)? onReact;
  const _ReactionPicker({this.onReact});

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥', '✅', '👀'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: _emojis
              .map((e) => GestureDetector(
                    onTap: () {
                      onReact?.call(e);
                      Navigator.pop(context);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
