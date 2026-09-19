import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/library_provider.dart';
import '../../widgets/common/miralo_segmented_tabs.dart';

class PrivateImagesScreen extends StatefulWidget {
  const PrivateImagesScreen({super.key});

  @override
  State<PrivateImagesScreen> createState() => _PrivateImagesScreenState();
}

class _PrivateImagesScreenState extends State<PrivateImagesScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Trending', 'Templates'];
  bool _showBanner = true;
  final TextEditingController _promptController = TextEditingController();

  final List<Map<String, dynamic>> _imageTemplates = const [
    {
      'title': 'Stickers',
      'subtitle': 'Die-cut vinyl cartoon stickers with bold outlines',
      'color1': 0xFF1E293B,
      'color2': 0xFF334155,
      'emoji': '🐱',
      'category': 'Trending',
    },
    {
      'title': 'Cinematic Film',
      'subtitle': 'Aesthetic 35mm grain with natural lighting',
      'color1': 0xFF18181B,
      'color2': 0xFF27272A,
      'emoji': '🎞️',
      'category': 'Trending',
    },
    {
      'title': 'Caricature',
      'subtitle': 'Whimsical exaggerated cartoon portraits',
      'color1': 0xFF14532D,
      'color2': 0xFF166534,
      'emoji': '🎨',
      'category': 'Trending',
    },
    {
      'title': 'Anime Art',
      'subtitle': 'Clean digital line work with dynamic lighting',
      'color1': 0xFF0F172A,
      'color2': 0xFF1E293B,
      'emoji': '✨',
      'category': 'Trending',
    },
    {
      'title': 'Isometric City',
      'subtitle': 'Detailed isometric miniature 3D scene',
      'color1': 0xFF1E1B4B,
      'color2': 0xFF312E81,
      'emoji': '🏙️',
      'category': 'Templates',
    },
    {
      'title': 'Minimal 3D',
      'subtitle': 'Clean matte clay render with soft shadows',
      'color1': 0xFF27272A,
      'color2': 0xFF3F3F46,
      'emoji': '🔮',
      'category': 'Templates',
    },
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _showImageDetails(BuildContext context, Map<String, dynamic> item) {
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(item['color1'] as int), Color(item['color2'] as int)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Center(
                  child: Text(
                    item['emoji'] as String,
                    style: const TextStyle(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item['title'] as String,
                style: AppTypography.heading2(color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'] as String,
                style: AppTypography.body(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                      ),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Save to Library'),
                      onPressed: () {
                        library.uploadItem(
                          name: '${item['title'].toString().replaceAll(' ', '_')}.png',
                          type: 'image',
                          size: '2.8 MB',
                          folderId: 'folder_images',
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to your private Library.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                      label: const Text('Download', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image downloaded to device.')),
                        );
                      },
                    ),
                  ),
                ],
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
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bannerBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    final selectedCategory = _tabs[_selectedTabIndex];
    final items = _imageTemplates.where((item) {
      if (selectedCategory == 'Trending') return true;
      return item['category'] == selectedCategory;
    }).toList();

    return Scaffold(
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
                onPressed: () => Navigator.pop(context),
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

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm + 4,
                      mainAxisSpacing: AppSpacing.sm + 4,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => _showImageDetails(context, item),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            gradient: LinearGradient(
                              colors: [Color(item['color1'] as int), Color(item['color2'] as int)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: border, width: 0.6),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  item['emoji'] as String,
                                  style: const TextStyle(fontSize: 44),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(AppSpacing.radiusMd)),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.8)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Text(
                                    item['title'] as String,
                                    style: AppTypography.bodySmall(color: Colors.white)
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom prompt composer
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, AppSpacing.xs, AppSpacing.screenH, AppSpacing.md),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.composerRadius),
                  border: Border.all(color: border, width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.image_outlined, color: textMuted, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        style: AppTypography.bodySmall(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Describe an image…',
                          hintStyle: AppTypography.bodySmall(color: textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final text = _promptController.text.trim();
                        if (text.isNotEmpty) {
                          _promptController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Generating image: "$text"…'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 17),
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
}
