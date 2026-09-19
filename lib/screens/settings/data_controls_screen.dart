import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/miralo_list_tile.dart';

class DataControlsScreen extends StatelessWidget {
  const DataControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
        title: Text('Data Controls',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          children: [
            // Storage Breakdown Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEVICE STORAGE',
                    style: AppTypography.labelSmall(color: textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Space Used',
                          style: AppTypography.bodyMedium(color: textPrimary)
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('41.3 MB',
                          style: AppTypography.bodyMedium(color: textPrimary)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Container(height: 6, color: AppColors.accent)),
                        Expanded(flex: 3, child: Container(height: 6, color: AppColors.success)),
                        Expanded(flex: 2, child: Container(height: 6, color: AppColors.warning)),
                        Expanded(flex: 1, child: Container(height: 6, color: border)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildLegendRow('Library Vault Files', '24.8 MB', AppColors.accent, textSecondary),
                  const SizedBox(height: 6),
                  _buildLegendRow('Private Media Attachments', '12.4 MB', AppColors.success, textSecondary),
                  const SizedBox(height: 6),
                  _buildLegendRow('Local AI Chat History', '4.1 MB', AppColors.warning, textSecondary),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            MiraloSectionHeader('ACTIONS & EXPORTS'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.download_outlined,
                  title: 'Export All Data',
                  subtitle: 'Download complete chat and library archive',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Archive prepared and ready for download.')),
                    );
                  },
                ),
                MiraloListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cached Previews',
                  subtitle: 'Frees 18.2 MB of temporary thumbnails',
                  showChevron: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preview cache cleared.')),
                    );
                  },
                ),
                MiraloListTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account & Vaults',
                  destructive: true,
                  showChevron: false,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Account?', style: TextStyle(color: AppColors.danger)),
                        content: const Text(
                            'This will permanently delete all conversations, files, vaults, and history. This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
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

  Widget _buildLegendRow(String label, String size, Color color, Color textSecondary) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.caption(color: textSecondary))),
        Text(size, style: AppTypography.caption(color: textSecondary).copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
