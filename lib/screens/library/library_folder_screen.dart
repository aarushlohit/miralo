import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/library_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common/longcat_app_bar.dart';
import '../../widgets/common/longcat_empty_state.dart';
import '../../widgets/library/file_card.dart';

class LibraryFolderScreen extends StatefulWidget {
  const LibraryFolderScreen({super.key});

  @override
  State<LibraryFolderScreen> createState() => _LibraryFolderScreenState();
}

class _LibraryFolderScreenState extends State<LibraryFolderScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFolderAddMenu(BuildContext context, LibraryProvider library) {
    final folder = library.currentFolder;
    final folderName = (folder?.name ?? '').toLowerCase().trim();
    final folderId = (folder?.id ?? '').toLowerCase().trim();
    final isImagesFolder = folderId == 'folder_images' || folderName == 'images';
    final isDocsFolder = folderId == 'folder_docs' || folderName == 'documents' || folderName == 'files';
    final isVideosFolder = folderId == 'folder_videos' || folderName == 'videos';
    final isCustomFolder = !isImagesFolder && !isDocsFolder && !isVideosFolder;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                if (isImagesFolder || isCustomFolder) ...[
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                    title: Text('Choose Photo from Gallery', style: AppTypography.bodyMedium(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(context, library, ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
                    title: Text('Take Photo with Camera', style: AppTypography.bodyMedium(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(context, library, ImageSource.camera);
                    },
                  ),
                ],
                if (isVideosFolder || isCustomFolder)
                  ListTile(
                    leading: const Icon(Icons.videocam_outlined, color: AppColors.accent),
                    title: Text('Choose Video from Gallery', style: AppTypography.bodyMedium(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickVideo(context, library);
                    },
                  ),
                if (isDocsFolder || isCustomFolder)
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined, color: AppColors.accent),
                    title: Text(isDocsFolder ? 'Upload Document (PDF, Word, Text)' : 'Upload Document or File',
                        style: AppTypography.bodyMedium(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickDocument(context, library, isDocsOnly: isDocsFolder);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    LibraryProvider library,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final List<XFile> files = [];
      if (source == ImageSource.gallery) {
        final multi = await picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        files.addAll(multi);
      } else {
        final single = await picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (single != null) files.add(single);
      }
      if (files.isEmpty) return;

      int addedCount = 0;
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final sizeKb = bytes.length / 1024;
        final sizeStr = sizeKb > 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
            : '${sizeKb.toStringAsFixed(1)} KB';

        final appDir = await getApplicationDocumentsDirectory();
        final libDir = Directory('${appDir.path}/library');
        if (!libDir.existsSync()) {
          await libDir.create(recursive: true);
        }
        final destPath = '${libDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final savedFile = await File(destPath).writeAsBytes(bytes);

        String? cloudUrl;
        try {
          cloudUrl = await CloudinaryService.uploadFileBytes(
            fileBytes: bytes,
            fileName: file.name,
            resourceType: 'image',
          );
        } catch (_) {}

        library.uploadItem(
          name: file.name,
          type: 'image',
          size: sizeStr,
          mediaUrl: cloudUrl ?? savedFile.path,
          folderId: library.selectedFolderId,
        );
        addedCount++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $addedCount image${addedCount > 1 ? "s" : ""} to folder.')),
        );
      }
    } catch (e) {
      debugPrint('Error picking image in folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(
    BuildContext context,
    LibraryProvider library,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final sizeKb = bytes.length / 1024;
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '${sizeKb.toStringAsFixed(1)} KB';

      final appDir = await getApplicationDocumentsDirectory();
      final libDir = Directory('${appDir.path}/library');
      if (!libDir.existsSync()) {
        await libDir.create(recursive: true);
      }
      final destPath = '${libDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final savedFile = await File(destPath).writeAsBytes(bytes);

      String? cloudUrl;
      try {
        cloudUrl = await CloudinaryService.uploadFileBytes(
          fileBytes: bytes,
          fileName: file.name,
          resourceType: 'video',
        );
      } catch (_) {}

      library.uploadItem(
        name: file.name,
        type: 'video',
        size: sizeStr,
        mediaUrl: cloudUrl ?? savedFile.path,
        folderId: library.selectedFolderId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${file.name}" to folder.')),
        );
      }
    } catch (e) {
      debugPrint('Error picking video in folder: $e');
    }
  }

  Future<void> _pickDocument(
    BuildContext context,
    LibraryProvider library, {
    bool isDocsOnly = false,
  }) async {
    try {
      final result = isDocsOnly
          ? await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'],
              allowMultiple: true,
              withData: true,
            )
          : await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: true,
              withData: true,
            );
      if (result == null || result.files.isEmpty) return;

      int addedCount = 0;
      for (final picked in result.files) {
        Uint8List? bytes = picked.bytes;
        if (bytes == null && picked.path != null) {
          bytes = await File(picked.path!).readAsBytes();
        }
        if (bytes == null) continue;

        final sizeKb = bytes.length / 1024;
        final sizeStr = sizeKb > 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
            : '${sizeKb.toStringAsFixed(1)} KB';

        final appDir = await getApplicationDocumentsDirectory();
        final libDir = Directory('${appDir.path}/library');
        if (!libDir.existsSync()) {
          await libDir.create(recursive: true);
        }
        final destPath = '${libDir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final savedFile = await File(destPath).writeAsBytes(bytes);

        final ext = picked.name.split('.').last.toLowerCase();
        final type = (ext == 'zip' || ext == 'rar' || ext == '7z')
            ? 'zip'
            : (['mp4', 'mov', 'avi', 'mkv'].contains(ext)
                ? 'video'
                : (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? 'image' : 'document'));

        String? cloudUrl;
        try {
          cloudUrl = await CloudinaryService.uploadFileBytes(
            fileBytes: bytes,
            fileName: picked.name,
            resourceType: type == 'image' ? 'image' : (type == 'video' ? 'video' : 'raw'),
          );
        } catch (_) {}

        library.uploadItem(
          name: picked.name,
          type: type,
          size: sizeStr,
          mediaUrl: cloudUrl ?? savedFile.path,
          folderId: library.selectedFolderId,
        );
        addedCount++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $addedCount file${addedCount > 1 ? "s" : ""} to folder.')),
        );
      }
    } catch (e) {
      debugPrint('Error picking document in folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final library = Provider.of<LibraryProvider>(context);
    final vault = Provider.of<VaultProvider>(context);
    final folder = library.currentFolder;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final allFolderItems =
        library.items.where((i) => i.folderId == library.selectedFolderId).toList();
    final items = vault.isLibraryContentUnhidden
        ? (_searchQuery.isEmpty
            ? allFolderItems
            : allFolderItems.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList())
        : allFolderItems.take(0).toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          vault.resetInactivityTimer();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            try {
              vault.resetInactivityTimer();
            } catch (_) {}
          },
          child: SafeArea(
            child: Column(
              children: [
                LongcatAppBar(
                  leading: LongcatCircularIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: folder?.name ?? 'Folder',
                ),

                // ── Search bar with stealth /unhide support ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.xs,
                    AppSpacing.screenH,
                    AppSpacing.xs,
                  ),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(LongcatDimensions.composerRadius),
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
                              hintText: 'Search in folder...',
                              hintStyle: AppTypography.bodySmall(color: textMuted),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onChanged: (val) async {
                              final trimmed = val.trim();
                              if (trimmed.toLowerCase().startsWith('/unhide')) {
                                final key = trimmed.length > 7 ? trimmed.substring(7).trim() : '';
                                bool isMatch = vault.verifyPasscode(key) || vault.verifyLibraryPin(key);
                                if (!isMatch && vault.currentUserId != null) {
                                  isMatch = await vault.verifyPrivateSecretServerSide(key) ||
                                      await vault.verifyLibraryPinServerSide(key);
                                }
                                if (!isMatch && !vault.hasLibraryPin && !vault.hasPrivateSecret && key.isNotEmpty) {
                                  isMatch = true;
                                }
                                if (isMatch) {
                                  vault.unhideLibraryContent();
                                  vault.unhideChatMessages();
                                  vault.resetInactivityTimer();
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Library unhidden.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                  return;
                                }
                              }
                              try {
                                vault.resetInactivityTimer();
                              } catch (_) {}
                              setState(() => _searchQuery = val.trim().toLowerCase());
                            },
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
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

                Expanded(
                  child: items.isEmpty
                      ? const LongcatEmptyState(
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
                            childAspectRatio: 0.82,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return FileCardWidget(
                              item: item,
                              onDelete: () => library.deleteItem(item.id),
                              onRename: (newName) =>
                                  library.renameItem(item.id, newName),
                              onMove: (fId) => library.moveItem(item.id, fId),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.accent,
          elevation: 2,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          onPressed: () => _showFolderAddMenu(context, library),
        ),
      ),
    );
  }
}
