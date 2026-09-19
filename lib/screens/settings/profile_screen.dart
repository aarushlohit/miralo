import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_avatar.dart';
import '../../widgets/common/miralo_list_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
              title: 'Profile',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
            // Centered Avatar
            Center(
              child: Column(
                children: [
                  MiraloAvatar(
                    name: user?.displayName ?? 'User',
                    size: 88,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.displayName ?? 'User',
                    style: AppTypography.heading2(color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: AppTypography.body(color: textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Account Details
            MiraloSectionHeader('ACCOUNT INFORMATION'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.person_outline,
                  title: 'Display Name',
                  subtitle: user?.displayName ?? 'User',
                  showChevron: false,
                ),
                MiraloListTile(
                  icon: Icons.mail_outline,
                  title: 'Email Address',
                  subtitle: user?.email ?? 'Not set',
                  showChevron: false,
                ),
                MiraloListTile(
                  icon: Icons.badge_outlined,
                  title: 'Member Tier',
                  subtitle: 'MIRALO AI Plus (Active)',
                  showChevron: false,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Security Details
            MiraloSectionHeader('SESSION PROTECTION'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.shield_outlined,
                  title: 'Device Protection',
                  subtitle: 'Biometric & Passcode Active',
                  showChevron: false,
                ),
                MiraloListTile(
                  icon: Icons.vpn_key_outlined,
                  title: 'Credential Status',
                  subtitle: 'Dual Independent Vaults Configured',
                  showChevron: false,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),
    );
  }
}
