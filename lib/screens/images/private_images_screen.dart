import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/private_message_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/download_service.dart';
import '../../widgets/common/miralo_empty_state.dart';
import '../../widgets/common/miralo_segmented_tabs.dart';

class PrivateImagesScreen extends StatefulWidget {
  const PrivateImagesScreen({super.key});

  @override
  State<PrivateImagesScreen> createState() => _PrivateImagesScreenState();
}

class _PrivateImagesScreenState extends State<PrivateImagesScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Chat Images', 'Favorites GIF'];
  int _chatImagesSubFilter = 0; // 0: All, 1: Sent, 2: Received
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vault = Provider.of<VaultProvider>(context, listen: false);
      if (!vault.isLibraryUnlocked) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.libraryLocked,
          arguments: AppRoutes.images,
        );
      }
    });
  }

  Future<void> _downloadChatImage(BuildContext context, PrivateMessageModel msg) async {
    try {
      Uint8List? fileBytes;
      if (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty) {
        fileBytes = base64Decode(msg.imageBase64!);
      } else if (msg.mediaUrl != null && msg.mediaUrl!.startsWith('http')) {
        final resp = await http.get(Uri.parse(msg.mediaUrl!));
        if (resp.statusCode == 200) {
          fileBytes = resp.bodyBytes;
        }
      }

      if (fileBytes != null && context.mounted) {
        final fname = msg.fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await DownloadService.downloadAndPrompt(
          context,
          fileName: fname,
          bytes: fileBytes,
          type: 'image',
        );
      }
    } catch (e) {
      debugPrint('Error downloading chat image: $e');
    }
  }

  void _showChatImagePreview(
    BuildContext context,
    PrivateMessageModel msg,
    PrivateChatProvider chat,
    LibraryProvider library,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.senderName ?? 'User',
                        style: AppTypography.bodyMedium(color: textPrimary).copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${msg.createdAt.day}/${msg.createdAt.month}/${msg.createdAt.year} • ${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.48,
              ),
              child: ClipRRect(
                child: InteractiveViewer(
                  child: msg.imageBase64 != null && msg.imageBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(msg.imageBase64!),
                          fit: BoxFit.contain,
                        )
                      : (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty
                          ? Image.network(
                              msg.mediaUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                              ),
                            )
                          : const Center(child: Icon(Icons.image_outlined, size: 48))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _downloadChatImage(context, msg);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.folder_special_outlined, size: 16),
                      label: const Text('Save'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        chat.saveMessageToLibrary(msg, library);
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to Library Vault.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    tooltip: 'Delete image',
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      chat.deleteImageMessage(msg);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image deleted.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatImageCard(
    BuildContext context,
    PrivateMessageModel msg,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color border,
    PrivateChatProvider chat,
    LibraryProvider library,
  ) {
    return GestureDetector(
      onTap: () => _showChatImagePreview(context, msg, chat, library),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
          border: Border.all(color: border, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: msg.imageBase64 != null && msg.imageBase64!.isNotEmpty
                  ? Image.memory(
                      base64Decode(msg.imageBase64!),
                      fit: BoxFit.cover,
                    )
                  : (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty
                      ? Image.network(
                          msg.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(Icons.broken_image_outlined, size: 32, color: textMuted),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image_outlined, size: 32, color: textMuted),
                        )),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        msg.senderName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoriteGifPreview(
    BuildContext context,
    PrivateMessageModel gif,
    PrivateChatProvider chat,
    LibraryProvider library,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'GIF',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gif.fileName ?? gif.senderName ?? 'Favorite GIF',
                                style: AppTypography.bodyMedium(color: textPrimary)
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${gif.createdAt.day}/${gif.createdAt.month}/${gif.createdAt.year} • ${gif.createdAt.hour.toString().padLeft(2, '0')}:${gif.createdAt.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.caption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.48,
              ),
              child: ClipRRect(
                child: InteractiveViewer(
                  child: gif.imageBase64 != null && gif.imageBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(gif.imageBase64!),
                          fit: BoxFit.contain,
                        )
                      : (gif.mediaUrl != null && gif.mediaUrl!.isNotEmpty
                          ? Image.network(
                              gif.mediaUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                              ),
                            )
                          : const Center(child: Icon(Icons.gif_box_rounded, size: 48))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _downloadChatImage(context, gif);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.folder_special_outlined, size: 16),
                      label: const Text('Save'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        chat.saveMessageToLibrary(gif, library);
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to Library Vault.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.star_rounded, color: Colors.amber),
                    tooltip: 'Remove from Favorites',
                    onPressed: () {
                      chat.toggleFavoriteMessage(gif);
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from Favorites.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteGifCard(
    BuildContext context,
    PrivateMessageModel gif,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color border,
    PrivateChatProvider chat,
    LibraryProvider library,
  ) {
    return GestureDetector(
      onTap: () => _showFavoriteGifPreview(context, gif, chat, library),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
          border: Border.all(color: border, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: gif.imageBase64 != null && gif.imageBase64!.isNotEmpty
                  ? Image.memory(
                      base64Decode(gif.imageBase64!),
                      fit: BoxFit.cover,
                    )
                  : (gif.mediaUrl != null && gif.mediaUrl!.isNotEmpty
                      ? Image.network(
                          gif.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(Icons.broken_image_outlined, size: 32, color: textMuted),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.gif_box_rounded, size: 32, color: textMuted),
                        )),
            ),
            // Top left GIF tag
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'GIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Top right favorite gold star
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  chat.toggleFavoriteMessage(gif);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from Favorites'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Bottom sender name & time
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        gif.fileName ?? gif.senderName ?? 'Favorite GIF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${gif.createdAt.hour.toString().padLeft(2, '0')}:${gif.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final privateChat = Provider.of<PrivateChatProvider>(context);
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final vault = Provider.of<VaultProvider>(context);
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bannerBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    if (!vault.isLibraryUnlocked) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          vault.lockLibrary();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back_ios_new, size: 16, color: textPrimary),
                  onPressed: () {
                    vault.lockLibrary();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        title: Text('Images',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH, AppSpacing.xs, AppSpacing.screenH, AppSpacing.md),
                children: [
                  if (_showBanner)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: bannerBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_stories_outlined,
                                size: 17, color: AppColors.accent),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Images are saved in Library',
                                  style: AppTypography.bodySmall(color: textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Generated artwork is encrypted and accessible directly from your Library.',
                                  style: AppTypography.caption(color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showBanner = false),
                            child: Icon(Icons.close, size: 16, color: textMuted),
                          ),
                        ],
                      ),
                    ),

                  Text('Generate & explore',
                      style: AppTypography.heading3(color: textPrimary)),
                  const SizedBox(height: AppSpacing.sm),

                  MiraloSegmentedTabs(
                    tabs: _tabs,
                    selectedIndex: _selectedTabIndex,
                    onTabSelected: (i) => setState(() => _selectedTabIndex = i),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  if (_selectedTabIndex == 0) ...[
                    // Sub-filter: All, Sent, Received
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          _buildSubFilterChip(
                            label: 'All (${privateChat.allChatImages.length})',
                            isSelected: _chatImagesSubFilter == 0,
                            onTap: () => setState(() => _chatImagesSubFilter = 0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildSubFilterChip(
                            label: 'Sent (${privateChat.getSentChatImages().length})',
                            isSelected: _chatImagesSubFilter == 1,
                            onTap: () => setState(() => _chatImagesSubFilter = 1),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildSubFilterChip(
                            label: 'Received (${privateChat.getReceivedChatImages().length})',
                            isSelected: _chatImagesSubFilter == 2,
                            onTap: () => setState(() => _chatImagesSubFilter = 2),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    Builder(
                      builder: (context) {
                        final displayedImages = _chatImagesSubFilter == 1
                            ? privateChat.getSentChatImages()
                            : (_chatImagesSubFilter == 2
                                ? privateChat.getReceivedChatImages()
                                : privateChat.allChatImages);

                        if (displayedImages.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: MiraloEmptyState(
                              icon: Icons.photo_library_outlined,
                              title: _chatImagesSubFilter == 1
                                  ? 'No sent images'
                                  : (_chatImagesSubFilter == 2 ? 'No received images' : 'No chat images yet'),
                              subtitle: _chatImagesSubFilter == 1
                                  ? 'Photos and images you sent will appear here.'
                                  : (_chatImagesSubFilter == 2
                                      ? 'Photos and images received from others will appear here.'
                                      : 'Photos and media shared in your private chats will appear here.'),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.sm + 4,
                            mainAxisSpacing: AppSpacing.sm + 4,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: displayedImages.length,
                          itemBuilder: (context, index) {
                            final msg = displayedImages[index];
                            return _buildChatImageCard(
                              context,
                              msg,
                              isDark,
                              textPrimary,
                              textMuted,
                              border,
                              privateChat,
                              library,
                            );
                          },
                        );
                      },
                    ),
                  ] else ...[
                    if (privateChat.favoriteGifs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: MiraloEmptyState(
                          icon: Icons.star_border_rounded,
                          title: 'No favorite GIFs yet',
                          subtitle: 'Long-press any GIF in chat and tap "Save Favorite" to see it here.',
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm + 4,
                          mainAxisSpacing: AppSpacing.sm + 4,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: privateChat.favoriteGifs.length,
                        itemBuilder: (context, index) {
                          final gif = privateChat.favoriteGifs[index];
                          return _buildFavoriteGifCard(
                            context,
                            gif,
                            isDark,
                            textPrimary,
                            textMuted,
                            border,
                            privateChat,
                            library,
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSubFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
