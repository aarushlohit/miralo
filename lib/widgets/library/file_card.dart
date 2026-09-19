import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/library_item_model.dart';
import 'file_preview_dialog.dart';

class FileCardWidget extends StatelessWidget {
  final LibraryItemModel item;
  final VoidCallback onDelete;
  final Function(String newName) onRename;

  const FileCardWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    IconData iconData = Icons.insert_drive_file_outlined;
    Color iconColor = Colors.blueGrey;

    if (item.type == 'image') {
      iconData = Icons.photo_outlined;
      iconColor = Colors.pinkAccent;
    } else if (item.type == 'video') {
      iconData = Icons.videocam_outlined;
      iconColor = Colors.deepPurpleAccent;
    } else if (item.type == 'document') {
      iconData = Icons.description_outlined;
      iconColor = AppColors.accentBlue;
    } else if (item.type == 'zip') {
      iconData = Icons.folder_zip_outlined;
      iconColor = Colors.amber;
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => FilePreviewDialog(
            item: item,
            onDelete: onDelete,
            onRename: onRename,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                if (item.isEncrypted)
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.darkTextMuted),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.size,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
