import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/miralo_tokens.dart';

/// Message actions bottom sheet.
class MessageActionsSheet extends StatelessWidget {
  final String text;
  final VoidCallback? onReact;
  final VoidCallback? onSaveToLibrary;
  final VoidCallback? onDelete;

  const MessageActionsSheet({
    super.key,
    required this.text,
    this.onReact,
    this.onSaveToLibrary,
    this.onDelete,
  });

  static void show(
    BuildContext context, {
    required String text,
    VoidCallback? onReact,
    VoidCallback? onSaveToLibrary,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
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
        onSaveToLibrary: onSaveToLibrary,
        onDelete: onDelete,
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MiraloSpacing.lg,
          vertical: MiraloSpacing.md,
        ),
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
            if (onDelete != null)
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Message',
                textColor: MiraloColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            const SizedBox(height: MiraloSpacing.sm),
          ],
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
