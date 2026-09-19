import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GifPickerSheet extends StatefulWidget {
  final Function(String gifUrl, String label) onGifSelected;

  const GifPickerSheet({super.key, required this.onGifSelected});

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  String _selectedCategory = 'Trending';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Trending',
    'Love',
    'Fun',
    'Reactions',
  ];

  final List<Map<String, String>> _mockGifs = [
    {'label': 'Cat Vibing', 'type': 'cat', 'color': '0xFF3E2723'},
    {'label': 'Good Night', 'type': 'night', 'color': '0xFF1A237E'},
    {'label': 'Anime Wink', 'type': 'anime', 'color': '0xFF880E4F'},
    {'label': 'Excited Dance', 'type': 'dance', 'color': '0xFF004D40'},
    {'label': 'Applause', 'type': 'clap', 'color': '0xFF311B92'},
    {'label': 'Love Hearts', 'type': 'heart', 'color': '0xFFB71C1C'},
    {'label': 'Puppy Wink', 'type': 'dog', 'color': '0xFFE65100'},
    {'label': 'Mind Blown', 'type': 'mind', 'color': '0xFF263238'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GIFs',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search GIFs...',
                  prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Categories
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.white,
                    backgroundColor:
                        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : borderColor,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // GIF Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: _mockGifs.length,
                itemBuilder: (context, index) {
                  final gif = _mockGifs[index];
                  final colorVal = int.parse(gif['color']!);

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onGifSelected('mock_gif_${gif['type']}', gif['label']!);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.gif_box_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                gif['label']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
