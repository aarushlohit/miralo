import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_avatar.dart';
import '../../widgets/common/miralo_list_tile.dart';

/// MIRALO AI Settings Screen
/// Strictly reduced, minimal, and useful categories matching Section 18:
/// - Account (Profile, Account)
/// - AI (Model, AI preferences)
/// - Privacy & Security (Private Access, Library Vault, Privacy, Auto-lock)
/// - Appearance (Appearance toggle)
/// - Notifications (Notifications)
/// - Storage (Data & Storage)
/// - Support (Help, About)
/// - Sign out
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final vault = Provider.of<VaultProvider>(context);

    final bg = MiraloColors.bg(isDark);
    final textPrimary = MiraloColors.textPrimary(isDark);
    final textSecondary = MiraloColors.textSecondary(isDark);

    final user = auth.currentUser;

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
              title: 'Settings',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: MiraloSpacing.md),
                children: [
                  // ── Profile Header ───────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.settingsProfile),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: MiraloSpacing.lg),
                      child: Column(
                        children: [
                          MiraloAvatar(
                            name: user?.displayName ?? 'User',
                            size: 72,
                          ),
                          const SizedBox(height: MiraloSpacing.sm),
                          Text(
                            user?.displayName ?? 'User',
                            style: MiraloTypography.titleLarge(
                                color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: MiraloTypography.bodySmall(
                                color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: MiraloSpacing.xl),

                  // ── ACCOUNT ──────────────────────────────────
                  const MiraloSectionHeader('ACCOUNT'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        subtitle: 'Name, email and user details',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsProfile),
                      ),
                      MiraloListTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Account',
                        subtitle: 'Security & login information',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsProfile),
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.lg),

                  // ── AI ───────────────────────────────────────
                  const MiraloSectionHeader('AI'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.smart_toy_outlined,
                        title: 'Model',
                        subtitle: 'Cloud AI endpoints and configuration',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settingsAi),
                      ),
                      MiraloListTile(
                        icon: Icons.tune_rounded,
                        title: 'AI Preferences',
                        subtitle: 'API keys & custom system prompts',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settingsAi),
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.lg),

                  // ── PRIVACY & SECURITY ───────────────────────
                  const MiraloSectionHeader('PRIVACY & SECURITY'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Private Access',
                        subtitle: 'Stealth composer passcode & contacts',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsPrivacy),
                      ),
                      MiraloListTile(
                        icon: Icons.shield_outlined,
                        title: 'Library Vault',
                        subtitle: 'Independent PIN protection for media',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.libraryLocked),
                      ),
                      MiraloListTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy',
                        subtitle: 'Zero data tracking & local security',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsPrivacy),
                      ),
                      MiraloListTile(
                        icon: Icons.timer_outlined,
                        title: 'Auto-lock',
                        subtitle: 'Immediate session timeout on exit',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsPrivacy),
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.lg),

                  // ── APPEARANCE ───────────────────────────────
                  const MiraloSectionHeader('APPEARANCE'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Appearance',
                        subtitle: isDark ? 'Charcoal Black' : 'Pure Light',
                        onTap: () => theme.toggleTheme(),
                        trailing: Switch(
                          value: isDark,
                          activeThumbColor: MiraloColors.accent,
                          onChanged: (_) => theme.toggleTheme(),
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.lg),

                  // ── NOTIFICATIONS ────────────────────────────
                  const MiraloSectionHeader('NOTIFICATIONS'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notifications',
                        subtitle: 'Direct message and AI alerts',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsNotifications),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.lg),

                  // ── STORAGE ──────────────────────────────────
                  const MiraloSectionHeader('STORAGE'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.data_usage_outlined,
                        title: 'Data & Storage',
                        subtitle: 'Local cache, export and database sync',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsData),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.lg),

                  // ── SUPPORT ──────────────────────────────────
                  const MiraloSectionHeader('SUPPORT'),
                  MiraloSettingsGroup(
                    children: [
                      MiraloListTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help',
                        subtitle: 'Guides & FAQ',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support guides: help@miralo.ai'),
                            ),
                          );
                        },
                      ),
                      MiraloListTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'MIRALO AI v1.0.0',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'MIRALO AI',
                            applicationVersion: '1.0.0',
                            applicationLegalese:
                                '© 2026 MIRALO AI. All rights reserved.',
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.xl),

                  // ── Sign out ──────────────────────────────────
                  MiraloSettingsGroup(
                    children: [
                      InkWell(
                        onTap: () {
                          vault.lockAll();
                          auth.logout();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.onboarding,
                            (route) => false,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MiraloSpacing.md,
                            vertical: 14,
                          ),
                          child: Center(
                            child: Text(
                              'Sign out',
                              style: TextStyle(
                                color: MiraloColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: MiraloSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
