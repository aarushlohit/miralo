import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_list_tile.dart';

class HideModeScreen extends StatelessWidget {
  const HideModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final hide = vault.hideMode;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
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
        title: Text('Hide Mode',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          children: [
            Text(
              'Mask identifying information from over-the-shoulder glance protection.',
              style: AppTypography.caption(color: textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            // Master Toggle Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: hide.isEnabled ? AppColors.accent : border,
                  width: hide.isEnabled ? 1.5 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (hide.isEnabled ? AppColors.accent : textSecondary)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hide.isEnabled ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: hide.isEnabled ? AppColors.accent : textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enable Hide Mode',
                            style: AppTypography.bodyMedium(color: textPrimary)
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          hide.isEnabled
                              ? 'Active — names and previews masked'
                              : 'Off — normal view',
                          style: AppTypography.caption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: hide.isEnabled,
                    onChanged: (val) => vault.updateHideMode(isEnabled: val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Granular Settings
            MiraloSectionHeader('MASKING RULES'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.person_outline,
                  title: 'Hide Username',
                  subtitle: 'Replace your account name with "User"',
                  showChevron: false,
                  trailing: Switch(
                    value: hide.hideUsername,
                    onChanged: (v) => vault.updateHideMode(hideUsername: v),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Hide Profile Picture',
                  subtitle: 'Display generic shield icon instead',
                  showChevron: false,
                  trailing: Switch(
                    value: hide.hideProfilePicture,
                    onChanged: (v) => vault.updateHideMode(hideProfilePicture: v),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.badge_outlined,
                  title: 'Hide Private Contact Names',
                  subtitle: 'Display "Protected Contact" instead of names',
                  showChevron: false,
                  trailing: Switch(
                    value: hide.hidePrivateChatNames,
                    onChanged: (v) => vault.updateHideMode(hidePrivateChatNames: v),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Hide Message Previews',
                  subtitle: 'Show bullet points for last message text',
                  showChevron: false,
                  trailing: Switch(
                    value: hide.hideMessagePreviews,
                    onChanged: (v) => vault.updateHideMode(hideMessagePreviews: v),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.notifications_none_outlined,
                  title: 'Discreet Notifications',
                  subtitle: 'Hide content in lock screen banners',
                  showChevron: false,
                  trailing: Switch(
                    value: hide.hideNotificationContent,
                    onChanged: (v) => vault.updateHideMode(hideNotificationContent: v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Live Preview Card
            MiraloSectionHeader('CASUAL VIEWER SIMULATION'),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border, width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: hide.isEnabled && hide.hideProfilePicture
                          ? const Icon(Icons.shield_outlined, size: 20, color: AppColors.accent)
                          : Text('C', style: AppTypography.heading3(color: textPrimary)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hide.isEnabled && hide.hidePrivateChatNames
                              ? 'Protected Contact'
                              : 'Contact',
                          style: AppTypography.bodyMedium(color: textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hide.isEnabled && hide.hideMessagePreviews
                              ? '••••••••••••••••••••'
                              : 'Caught this sunset on the drive back 🌅',
                          style: AppTypography.caption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Center(
              child: Text(
                'Hide Mode protects against over-the-shoulder viewing.\nIt does not alter database contents.',
                style: AppTypography.caption(color: textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
