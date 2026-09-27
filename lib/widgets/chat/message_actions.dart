import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/miralo_tokens.dart';

/// Message actions bottom sheet.
class MessageActionsSheet extends StatelessWidget {
  final String text;
  final VoidCallback? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onDownload;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final VoidCallback? onStar;
  final bool isStarred;
  final VoidCallback? onPin;
  final bool isPinned;
  final VoidCallback? onSaveToLibrary;
  final VoidCallback? onMoveToVault;
  final VoidCallback? onEdit;

  const MessageActionsSheet({
    super.key,
    required this.text,
    this.onReact,
    this.onReply,
    this.onDownload,
    this.onFavorite,
    this.isFavorite = false,
    this.onStar,
    this.isStarred = false,
    this.onPin,
    this.isPinned = false,
    this.onSaveToLibrary,
    this.onMoveToVault,
    this.onEdit,
  });

  static void show(
    BuildContext context, {
    required String text,
    VoidCallback? onReact,
    VoidCallback? onReply,
    VoidCallback? onDownload,
    VoidCallback? onFavorite,
    bool isFavorite = false,
    VoidCallback? onStar,
    bool isStarred = false,
    VoidCallback? onPin,
    bool isPinned = false,
    VoidCallback? onSaveToLibrary,
    VoidCallback? onMoveToVault,
    VoidCallback? onEdit,
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
      builder: (_) => MessageActionsSheet(
        text: text,
        onReact: onReact,
        onReply: onReply,
        onDownload: onDownload,
        onFavorite: onFavorite,
        isFavorite: isFavorite,
        onStar: onStar,
        isStarred: isStarred,
        onPin: onPin,
        isPinned: isPinned,
        onSaveToLibrary: onSaveToLibrary,
        onMoveToVault: onMoveToVault,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: MiraloSpacing.lg,
          vertical: MiraloSpacing.md,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (onReact != null)
              _ActionRow(
                icon: Icons.add_reaction_outlined,
                title: 'Add Reaction',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  onReact?.call();
                },
              ),
            if (onEdit != null)
              _ActionRow(
                icon: Icons.edit_outlined,
                title: 'Edit Message (within 5m)',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            if (onReply != null)
              _ActionRow(
                icon: Icons.reply_rounded,
                title: 'Reply / Retag Message',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
            _ActionRow(
              icon: Icons.copy_rounded,
              title: 'Copy Text',
              textColor: textColor,
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (onDownload != null)
              _ActionRow(
                icon: Icons.file_download_outlined,
                title: 'Download to Device',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  onDownload?.call();
                },
              ),
            if (onFavorite != null)
              _ActionRow(
                icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                title: isFavorite ? 'Remove from Favorites' : 'Save Favorite',
                textColor: isFavorite ? MiraloColors.accent : textColor,
                onTap: () {
                  Navigator.pop(context);
                  onFavorite?.call();
                },
              ),
            if (onPin != null)
              _ActionRow(
                icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                title: isPinned ? 'Unpin Message' : 'Pin Message',
                textColor: isPinned ? MiraloColors.accent : textColor,
                onTap: () {
                  Navigator.pop(context);
                  onPin?.call();
                },
              ),
            if (onStar != null)
              _ActionRow(
                icon: isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                title: isStarred ? 'Unstar Message' : 'Star Message',
                textColor: isStarred ? const Color(0xFFF59E0B) : textColor,
                onTap: () {
                  Navigator.pop(context);
                  onStar?.call();
                },
              ),
            if (onSaveToLibrary != null)
              _ActionRow(
                icon: Icons.bookmark_border_rounded,
                title: 'Save to Library',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  onSaveToLibrary?.call();
                },
              ),
            if (onMoveToVault != null)
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                title: 'Move to Private Vault',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  onMoveToVault?.call();
                },
              ),
            const SizedBox(height: MiraloSpacing.sm),
          ],
        ),
      ),
    ),
  );
}
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor, size: MiraloIconSizes.md),
      title: Text(title, style: MiraloTypography.bodyMedium(color: textColor)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
