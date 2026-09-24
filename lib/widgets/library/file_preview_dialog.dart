import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/library_item_model.dart';
import '../../providers/library_provider.dart';
import 'library_thumbnail.dart';

class FilePreviewDialog extends StatelessWidget {
  final LibraryItemModel item;
  final VoidCallback onDelete;
  final Function(String newName) onRename;
  final Function(String folderId)? onMove;

  const FilePreviewDialog({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onRename,
    this.onMove,
  });

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New file name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onRename(val);
                Navigator.pop(ctx);
                Navigator.pop(context); // Close preview
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
                        Navigator.pop(context); // Close preview dialog
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
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final secondarySurface =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Preview Box
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: secondarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.type == 'image' && item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          LibraryThumbnail(
                            item: item,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.zero,
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.size,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  const Row(
                                    children: [
                                      Icon(Icons.shield_outlined, size: 12, color: AppColors.success),
                                      SizedBox(width: 4),
                                      Text(
                                        'Encrypted Vault Asset',
                                        style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.type == 'video'
                                  ? Icons.play_circle_outline
                                  : item.type == 'zip'
                                      ? Icons.folder_zip_outlined
                                      : Icons.description_outlined,
                              size: 54,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${item.type.toUpperCase()} • ${item.size}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.isSavedToCloud
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_off_rounded,
                                  size: 14,
                                  color: item.isSavedToCloud
                                      ? AppColors.accent
                                      : AppColors.darkTextMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.isSavedToCloud
                                      ? 'Saved to Cloud'
                                      : 'Local Only',
                                  style: TextStyle(
                                    color: item.isSavedToCloud
                                        ? AppColors.accent
                                        : AppColors.darkTextMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAction(
                  context,
                  icon: Icons.download_outlined,
                  label: 'Download',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File exported.')),
                    );
                  },
                ),
                _buildAction(
                  context,
                  icon: Icons.drive_file_rename_outline,
                  label: 'Rename',
                  onTap: () => _showRenameDialog(context),
                ),
                _buildAction(
                  context,
                  icon: Icons.drive_file_move_outlined,
                  label: 'Move',
                  onTap: () => _showMoveDialog(context),
                ),
                _buildAction(
                  context,
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing secure link...')),
                    );
                  },
                ),
                _buildAction(
                  context,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.danger,
                  onTap: () {
                    onDelete();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File deleted.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
