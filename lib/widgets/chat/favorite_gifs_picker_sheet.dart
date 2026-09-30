import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/longcat_tokens.dart';
import '../../models/private_message_model.dart';
import '../../providers/private_chat_provider.dart';

/// Modal bottom sheet allowing users to search and quickly send their
/// saved/favorited GIFs in chat conversations.
class FavoriteGifsPickerSheet extends StatefulWidget {
  final String initialQuery;
  final Function(String gifUrl, String title) onGifSelected;

  const FavoriteGifsPickerSheet({
    super.key,
    this.initialQuery = '',
    required this.onGifSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String initialQuery = '',
    required Function(String gifUrl, String title) onGifSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? LongcatColors.darkSurfacePrimary
          : LongcatColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LongcatRadius.bottomSheet),
        ),
      ),
      builder: (_) => FavoriteGifsPickerSheet(
        initialQuery: initialQuery,
        onGifSelected: onGifSelected,
      ),
    );
  }

  @override
  State<FavoriteGifsPickerSheet> createState() => _FavoriteGifsPickerSheetState();
}

class _FavoriteGifsPickerSheetState extends State<FavoriteGifsPickerSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = Provider.of<PrivateChatProvider>(context);
    final text = _searchController.text.trim();
    final List<PrivateMessageModel> gifs = chat.searchFavoriteGifs(text);
    final totalFavoritesCount = chat.favoriteGifs.length;

    final textColor = isDark
        ? LongcatColors.darkTextPrimary
        : LongcatColors.lightTextPrimary;
    final textMuted = isDark
        ? LongcatColors.darkTextSecondary
        : LongcatColors.lightTextSecondary;
    final searchBg = isDark
        ? LongcatColors.darkSurfaceSecondary
        : LongcatColors.lightSurfaceSecondary;
    final border = isDark ? LongcatColors.darkBorder : LongcatColors.lightBorder;

    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: LongcatSpacing.sm, bottom: LongcatSpacing.xs),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LongcatSpacing.md,
                vertical: LongcatSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: LongcatSpacing.xs),
                  Text(
                    'Favorite GIFs',
                    style: LongcatTypography.titleMedium(color: textColor),
                  ),
                  if (totalFavoritesCount > 0) ...[
                    const SizedBox(width: LongcatSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: LongcatColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(LongcatRadius.pill),
                      ),
                      child: Text(
                        '$totalFavoritesCount',
                        style: LongcatTypography.bodySmall(color: LongcatColors.accent)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LongcatSpacing.md,
                vertical: LongcatSpacing.xs,
              ),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: BorderRadius.circular(LongcatRadius.pill),
                  border: Border.all(color: border, width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: LongcatSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: textMuted, size: 18),
                    const SizedBox(width: LongcatSpacing.xs),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: LongcatTypography.bodyMedium(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search favorite GIFs...',
                          hintStyle: LongcatTypography.bodyMedium(color: textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Icon(Icons.clear_rounded, color: textMuted, size: 16),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: LongcatSpacing.xs),

            // Content Grid / Empty state
            Expanded(
              child: gifs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: LongcatSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              totalFavoritesCount == 0
                                  ? Icons.star_border_rounded
                                  : Icons.search_off_rounded,
                              size: 48,
                              color: textMuted,
                            ),
                            const SizedBox(height: LongcatSpacing.sm),
                            Text(
                              totalFavoritesCount == 0
                                  ? 'No favorite GIFs yet'
                                  : 'No matching GIFs found',
                              style: LongcatTypography.titleMedium(color: textColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: LongcatSpacing.xs),
                            Text(
                              totalFavoritesCount == 0
                                  ? 'Long-press any GIF in chat and tap "Save Favorite" to collect them here.'
                                  : 'Try a different search word.',
                              style: LongcatTypography.bodySmall(color: textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(LongcatSpacing.md),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: LongcatSpacing.sm,
                        mainAxisSpacing: LongcatSpacing.sm,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: gifs.length,
                      itemBuilder: (context, index) {
                        final gif = gifs[index];
                        final gifUrl = gif.mediaUrl ?? '';
                        final isBase64 = gif.imageBase64 != null && gif.imageBase64!.isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            if (gifUrl.isNotEmpty || isBase64) {
                              Navigator.pop(context);
                              widget.onGifSelected(
                                gifUrl.isNotEmpty ? gifUrl : gif.imageBase64!,
                                gif.fileName ?? 'Favorite GIF',
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: searchBg,
                              borderRadius: BorderRadius.circular(LongcatRadius.md),
                              border: Border.all(color: border, width: 0.6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                isBase64
                                    ? Image.memory(
                                        base64Decode(gif.imageBase64!),
                                        fit: BoxFit.cover,
                                      )
                                    : (gifUrl.isNotEmpty
                                        ? Image.network(
                                            gifUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Center(
                                              child: Icon(Icons.broken_image_outlined,
                                                  size: 32, color: textMuted),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(Icons.gif_box_rounded,
                                                size: 32, color: textMuted),
                                          )),

                                // GIF pill badge
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

                                // Unfavorite button
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

                                // Bottom filename / label
                                if (gif.fileName != null && gif.fileName!.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                                      child: Text(
                                        gif.fileName!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
