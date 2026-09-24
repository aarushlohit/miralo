import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/library_item_model.dart';
import '../../providers/library_provider.dart';
import 'file_preview_dialog.dart';
import 'library_thumbnail.dart';

class FileCardWidget extends StatelessWidget {
  final LibraryItemModel item;
  final VoidCallback onDelete;
  final Function(String newName) onRename;
  final Function(String folderId)? onMove;

  const FileCardWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onRename,
    this.onMove,
  });

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: item.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                onRename(newName);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context) {
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final folders = library.folders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Move to Folder',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: folders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No folders available'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final f = folders[idx];
                    final isCurrent = item.folderId == f.id;
                    return ListTile(
                      leading: Icon(
                        isCurrent ? Icons.folder : Icons.folder_outlined,
                        color: isCurrent ? AppColors.accent : Colors.grey,
                      ),
                      title: Text(
                        f.name,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Text('Current', style: TextStyle(color: AppColors.accent, fontSize: 12))
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (onMove != null) {
                          onMove!(f.id);
                        } else {
                          library.moveItem(item.id, f.id);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Moved "${item.name}" to ${f.name}.')),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

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

    final isImage = item.type == 'image';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => FilePreviewDialog(
            item: item,
            onDelete: onDelete,
            onRename: onRename,
            onMove: (fId) {
              if (onMove != null) {
                onMove!(fId);
              } else {
                Provider.of<LibraryProvider>(context, listen: false).moveItem(item.id, fId);
              }
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Large preview thumbnail covering the upper card ───────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isImage)
                    LibraryThumbnail(
                      item: item,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    )
                  else
                    Container(
                      color: isDark ? const Color(0xFF1E242B) : const Color(0xFFF1F5F9),
                      child: Center(
                        child: LibraryThumbnail(
                          item: item,
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  // Cloud sync indicator overlay (top-left) — NO encrypted lock icon per user request
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isSavedToCloud
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_off_rounded,
                            size: 13,
                            color: item.isSavedToCloud
                                ? AppColors.accent
                                : Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.isSavedToCloud ? 'Cloud' : 'Local',
                            style: TextStyle(
                              color: item.isSavedToCloud
                                  ? AppColors.accent
                                  : Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3-dots action menu (top-right)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDark
                              ? AppColors.darkSurfacePrimary
                              : AppColors.lightSurfacePrimary,
                          onSelected: (val) {
                            if (val == 'rename') {
                              _showRenameDialog(context);
                            } else if (val == 'move') {
                              _showMoveDialog(context);
                            } else if (val == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  const Icon(Icons.drive_file_rename_outline,
                                      size: 18, color: AppColors.accent),
                                  const SizedBox(width: 10),
                                  Text('Rename',
                                      style: TextStyle(
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'move',
                              child: Row(
                                children: [
                                  const Icon(Icons.drive_file_move_outlined,
                                      size: 18, color: AppColors.accent),
                                  const SizedBox(width: 10),
                                  Text('Move to Folder',
                                      style: TextStyle(
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.danger),
                                  SizedBox(width: 10),
                                  Text('Delete',
                                      style: TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── File title & metadata at bottom of card ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.size,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          color: textSecondary.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
