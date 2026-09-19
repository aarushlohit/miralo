import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_avatar.dart';
import '../../widgets/common/miralo_list_tile.dart';

/// MIRALO AI Settings Screen
/// Key spec compliance:
/// - "PRIVATE WORKSPACE" section label removed → renamed to "PRIVACY"
/// - No amber/yellow avatar — uses MiraloAvatar
/// - Consistent AppTypography and AppColors tokens throughout
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final vault = Provider.of<VaultProvider>(context);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surface2 =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bespoke MiraloAppBar ─────────────────────────────
            MiraloAppBar(
              leading: MiraloCircularIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
              title: 'Settings',
            ),

            // ── Scrollable Content ─────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  // ── Profile header ───────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.settingsProfile),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              MiraloAvatar(
                                  name: user?.displayName ?? 'User', size: 76),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: surface,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Icon(Icons.edit_outlined,
                                    size: 13, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(user?.displayName ?? 'User',
                              style: AppTypography.heading2(color: textPrimary)),
                          const SizedBox(height: 2),
                          Text(user?.email ?? '',
                              style: AppTypography.body(color: textSecondary)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── MY MIRALO AI ─────────────────────────────
                  MiraloSectionHeader('MY MIRALO AI'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.person_pin_outlined,
                        title: 'Profile',
                        subtitle: 'Name, email & account details',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsProfile),
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.psychology_outlined,
                        title: 'Memory',
                        subtitle: 'What MIRALO AI remembers about you',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── APP PREFERENCES ──────────────────────────
                  MiraloSectionHeader('PREFERENCES'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Appearance',
                        subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                        onTap: () => theme.toggleTheme(),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) => theme.toggleTheme(),
                        ),
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.smart_toy_outlined,
                        title: 'AI Model & Settings',
                        subtitle: 'GPT-4o, Claude, custom system prompts',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsAi),
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notifications',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsNotifications),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── PRIVACY & SECURITY ───────────────────────
                  // NOTE: Spec says NO "PRIVATE WORKSPACE" label.
                  MiraloSectionHeader('PRIVACY & SECURITY'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.shield_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Credentials, locks & session protection',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsPrivacy),
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'Data Controls',
                        subtitle: 'Storage, cached media & export',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsData),
                        showDivider: true,
                      ),
                      // Hide Mode (no "PRIVATE WORKSPACE" label)
                      MiraloListTile(
                        icon: Icons.visibility_off_outlined,
                        title: 'Hide Mode',
                        subtitle: 'Mask names, previews & sensitive info',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.hideMode),
                        trailing: _HideModeChip(
                            isEnabled: vault.hideMode.isEnabled,
                            surface: surface2,
                            textMuted: textMuted),
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.warning_amber_rounded,
                        title: 'Emergency Controls',
                        subtitle: 'Immediate panic lock & data wipe',
                        iconColor: AppColors.danger,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.emergency),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── SUPPORT ──────────────────────────────────
                  MiraloSectionHeader('SUPPORT'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & FAQ',
                        onTap: () {},
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About MIRALO AI',
                        subtitle: 'v1.0.0',
                        onTap: () {},
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.article_outlined,
                        title: 'Terms of Service',
                        onTap: () {},
                        showDivider: true,
                      ),
                      MiraloListTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sign out ──────────────────────────────────
                  MiraloSettingsGroup(
                    children: [
                      InkWell(
                        onTap: () {
                          auth.logout();
                          Navigator.pushNamedAndRemoveUntil(
                              context, AppRoutes.login, (r) => false);
                        },
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.logout,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Text('Sign Out',
                                  style: AppTypography.bodyMedium(
                                          color: AppColors.danger)
                                      .copyWith(
                                          fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: Text(
                      'MIRALO AI  ·  Smart. Private. Yours.',
                      style: AppTypography.caption(color: textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hide mode chip ────────────────────────────────────────────────────────────

class _HideModeChip extends StatelessWidget {
  final bool isEnabled;
  final Color surface;
  final Color textMuted;

  const _HideModeChip(
      {required this.isEnabled,
      required this.surface,
      required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.success.withValues(alpha: 0.15)
            : surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isEnabled ? 'ON' : 'OFF',
        style: TextStyle(
          color: isEnabled ? AppColors.success : textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
