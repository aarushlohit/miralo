import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/library_provider.dart';

class FullImageViewer extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback? onDelete;

  const FullImageViewer({
    super.key,
    this.title = 'Image Preview',
    this.imageUrl,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<LibraryProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '1 / 1',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE65100),
                        Color(0xFFF57C00),
                        Color(0xFFFFB74D),
                        Color(0xFF2E7D32),
                        Color(0xFF0D47A1),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      Positioned(
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar matching Mockup Screen 15
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionBtn(
                    context,
                    icon: Icons.download_outlined,
                    label: 'Download',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image downloaded to app storage.')),
                      );
                    },
                  ),
                  _buildActionBtn(
                    context,
                    icon: Icons.folder_copy_outlined,
                    label: 'Move to Library',
                    onTap: () {
                      library.uploadItem(
                        name: '$title.jpg',
                        type: 'image',
                        size: '2.4 MB',
                        folderId: 'folder_images',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved to Secure Library!')),
                      );
                    },
                  ),
                  _buildActionBtn(
                    context,
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing image link...')),
                      );
                    },
                  ),
                  _buildActionBtn(
                    context,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.danger,
                    onTap: () {
                      Navigator.pop(context);
                      if (onDelete != null) onDelete!();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image removed.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
