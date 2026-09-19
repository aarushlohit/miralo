import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/library_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_empty_state.dart';
import '../../widgets/library/file_card.dart';

class LibraryFolderScreen extends StatelessWidget {
  const LibraryFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final library = Provider.of<LibraryProvider>(context);
    final folder = library.currentFolder;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final items =
        library.items.where((i) => i.folderId == library.selectedFolderId).toList();

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
              title: folder?.name ?? 'Folder',
            ),
            Expanded(
              child: items.isEmpty
                  ? const MiraloEmptyState(
                      icon: Icons.folder_open_outlined,
                      title: 'This folder is empty',
                      subtitle:
                          'Add documents or media to store them in this folder.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.sm + 4,
                        mainAxisSpacing: AppSpacing.sm + 4,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return FileCardWidget(
                          item: item,
                          onDelete: () => library.deleteItem(item.id),
                          onRename: (newName) =>
                              library.renameItem(item.id, newName),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        onPressed: () {
          library.uploadItem(
            name: 'Note_${DateTime.now().millisecondsSinceEpoch}.txt',
            type: 'document',
            size: '24 KB',
            folderId: library.selectedFolderId,
          );
        },
      ),
    );
  }
}
