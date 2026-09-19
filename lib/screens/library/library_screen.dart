import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/library_item_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_empty_state.dart';
import '../../widgets/common/miralo_segmented_tabs.dart';
import '../../widgets/library/file_preview_dialog.dart';
import '../../widgets/library/zip_export_dialog.dart';

/// MIRALO AI Library Vault Screen.
/// Clean Apple-grade file management interface with pill tabs,
/// two-column grid, search, and action sheets.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  static const List<String> _tabs = ['All', 'Images', 'Files', 'Videos'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateFolderDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('New Folder',
            style: AppTypography.heading3(color: textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: AppTypography.body(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.button(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                library.createFolder(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context, LibraryProvider library) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                      color: border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined, color: AppColors.accent),
                title: Text('Create Folder', style: AppTypography.bodyMedium(color: textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateFolderDialog(context, library);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.accent),
                title: Text('Import Image', style: AppTypography.bodyMedium(color: textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  library.uploadItem(
                    name: 'Imported_Asset_${DateTime.now().millisecondsSinceEpoch}.png',
                    type: 'image',
                    size: '2.4 MB',
                    folderId: 'folder_images',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined, color: AppColors.accent),
                title: Text('Add Document', style: AppTypography.bodyMedium(color: textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  library.uploadItem(
                    name: 'Encrypted_Doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    type: 'document',
                    size: '1.1 MB',
                    folderId: 'folder_docs',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, VaultProvider vault, LibraryProvider library) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                      color: border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: AppColors.accent),
                title: Text('Export as Encrypted ZIP', style: AppTypography.bodyMedium(color: textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const ZipExportDialog());
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.danger),
                title: Text('Lock Library Vault',
                    style: AppTypography.bodyMedium(color: AppColors.danger)
                        .copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  vault.lockLibrary();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final library = Provider.of<LibraryProvider>(context);
    final vault = Provider.of<VaultProvider>(context);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final cardBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final folders = library.folders;
    final items = library.filteredItems;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            MiraloAppBar(
              leading: MiraloCircularIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
              title: 'Library',
              actions: [
                MiraloCircularIconButton(
                  icon: Icons.more_horiz_rounded,
                  iconSize: 18,
                  onPressed: () => _showMoreMenu(context, vault, library),
                ),
              ],
            ),

            // ── TOP: Search library field with clean padding & no overlap ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xs,
                AppSpacing.screenH,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(MiraloDimensions.composerRadius),
                        border: Border.all(color: cardBorder, width: 0.6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: textMuted, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: AppTypography.bodySmall(color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search library...',
                                hintStyle: AppTypography.bodySmall(color: textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onChanged: (val) => library.setSearchQuery(val),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                library.setSearchQuery('');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close, size: 16, color: textMuted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      tooltip: 'Add item',
                      onPressed: () => _showAddMenu(context, library),
                    ),
                  ),
                ],
              ),
            ),

            // ── Segmented tabs ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.sm,
              ),
              child: MiraloSegmentedTabs(
                tabs: _tabs,
                selectedIndex: _tabs.indexOf(library.currentTab).clamp(0, _tabs.length - 1),
                onTabSelected: (i) => library.setCurrentTab(_tabs[i]),
              ),
            ),

            // ── Content Grid ───────────────────────────────────────────
            Expanded(
              child: (folders.isEmpty && items.isEmpty)
                  ? MiraloEmptyState(
                      icon: Icons.folder_open_outlined,
                      title: 'Library is empty',
                      subtitle: 'Add items or create folders to store content privately.',
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                        vertical: AppSpacing.sm,
                      ),
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.sm + 4,
                            mainAxisSpacing: AppSpacing.sm + 4,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: (library.currentTab == 'All' ? folders.length : 0) + items.length,
                          itemBuilder: (context, index) {
                            if (library.currentTab == 'All' && index < folders.length) {
                              final folder = folders[index];
                              return _buildFolderCard(
                                title: folder.name,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                onTap: () {
                                  library.openFolder(folder.id);
                                  Navigator.pushNamed(context, AppRoutes.libraryFolder);
                                },
                              );
                            }

                            final itemIndex = library.currentTab == 'All' ? index - folders.length : index;
                            final item = items[itemIndex];
                            return _buildItemCard(
                              item: item,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => FilePreviewDialog(
                                    item: item,
                                    onDelete: () => library.deleteItem(item.id),
                                    onRename: (newName) => library.renameItem(item.id, newName),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard({
    required String title,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: cardBorder, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.bodyMedium(color: textPrimary).copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Icon(Icons.folder_outlined, size: 28, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard({
    required LibraryItemModel item,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    IconData icon;
    Color iconColor;

    if (item.type == 'image') {
      icon = Icons.photo_outlined;
      iconColor = AppColors.accent;
    } else if (item.type == 'video') {
      icon = Icons.videocam_outlined;
      iconColor = AppColors.accentHover;
    } else if (item.type == 'zip') {
      icon = Icons.folder_zip_outlined;
      iconColor = AppColors.warning;
    } else {
      icon = Icons.description_outlined;
      iconColor = textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: cardBorder, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.name,
              style: AppTypography.bodySmall(color: textPrimary).copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 22, color: iconColor),
                Text(item.size, style: AppTypography.caption(color: textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
