import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../services/giphy_service.dart';

/// Interactive modal sheet to search and browse GIFs via GIPHY API with
/// a strict 100 requests/hour rate limit enforcement and cooldown notification.
class GiphyPickerSheet extends StatefulWidget {
  final Function(String gifUrl, String title) onGifSelected;

  const GiphyPickerSheet({
    super.key,
    required this.onGifSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String gifUrl, String title) onGifSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
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
      builder: (_) => GiphyPickerSheet(onGifSelected: onGifSelected),
    );
  }

  @override
  State<GiphyPickerSheet> createState() => _GiphyPickerSheetState();
}

class _GiphyPickerSheetState extends State<GiphyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<GiphyGif> _gifs = [];
  bool _isLoading = false;
  String? _rateLimitError;
  int _offset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadGifs(initial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _rateLimitError == null) {
        _loadGifs(initial: false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _offset = 0;
        _hasMore = true;
        _loadGifs(initial: true);
      }
    });
  }

  Future<void> _loadGifs({bool initial = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (initial) {
        _rateLimitError = null;
      }
    });

    final query = _searchController.text.trim();
    try {
      List<GiphyGif> results;
      if (query.isEmpty) {
        results = await GiphyService.instance.getTrendingGifs(
          limit: 24,
          offset: _offset,
        );
      } else {
        results = await GiphyService.instance.searchGifs(
          query,
          limit: 24,
          offset: _offset,
        );
      }

      if (mounted) {
        setState(() {
          if (initial) {
            _gifs = results;
          } else {
            _gifs.addAll(results);
          }
          _offset += results.length;
          _hasMore = results.length >= 24;
          _isLoading = false;
        });
      }
    } on GiphyRateLimitException catch (e) {
      if (mounted) {
        setState(() {
          _rateLimitError = e.userFriendlyMessage;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userFriendlyMessage),
            backgroundColor: Colors.amber.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Error loading GIFs: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final subColor = isDark
        ? MiraloColors.darkTextSecondary
        : MiraloColors.lightTextSecondary;
    final bgSurface = isDark
        ? MiraloColors.darkSurfaceSecondary
        : MiraloColors.lightSurfaceSecondary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.75;

    return Container(
      height: sheetHeight,
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MiraloSpacing.md,
              vertical: MiraloSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.gif_box_rounded,
                  color: MiraloColors.accent,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  'GIPHY GIFs',
                  style: MiraloTypography.titleMedium(color: textColor),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: border, width: 0.5),
                  ),
                  child: Text(
                    '100/hr quota',
                    style: MiraloTypography.bodySmall(color: subColor).copyWith(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: subColor,
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MiraloSpacing.md,
              vertical: MiraloSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: MiraloTypography.bodyMedium(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search GIPHY...',
                hintStyle: MiraloTypography.bodyMedium(color: subColor),
                prefixIcon: Icon(Icons.search_rounded, color: subColor, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: subColor,
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: bgSurface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MiraloRadius.sm),
                  borderSide: BorderSide(color: border, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MiraloRadius.sm),
                  borderSide: BorderSide(color: border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MiraloRadius.sm),
                  borderSide: const BorderSide(color: MiraloColors.accent, width: 1.2),
                ),
              ),
            ),
          ),

          // Rate Limit Warning Banner if in cooldown
          if (_rateLimitError != null)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: MiraloSpacing.md,
                vertical: MiraloSpacing.xs,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _rateLimitError!,
                      style: MiraloTypography.bodySmall(
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // GIF Grid View
          Expanded(
            child: _gifs.isEmpty && _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: MiraloColors.accent,
                    ),
                  )
                : (_gifs.isEmpty
                    ? Center(
                        child: Text(
                          _rateLimitError != null
                              ? 'Rate limit cooldown active'
                              : 'No GIFs found',
                          style: MiraloTypography.bodyMedium(color: subColor),
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(MiraloSpacing.md),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _gifs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _gifs.length) {
                            return Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: MiraloColors.accent,
                                    )
                                  : const SizedBox.shrink(),
                            );
                          }

                          final gif = _gifs[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onGifSelected(gif.url, gif.title);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                color: bgSurface,
                                child: Image.network(
                                  gif.previewUrl.isNotEmpty ? gif.previewUrl : gif.url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                            : null,
                                        color: MiraloColors.accent,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: subColor,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}
