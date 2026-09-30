import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/longcat_tokens.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/longcat_app_bar.dart';
import '../../widgets/common/longcat_avatar.dart';
import '../../widgets/common/longcat_list_tile.dart';

/// LONGCAT AI Settings Screen
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

    final bg = LongcatColors.bg(isDark);
    final textPrimary = LongcatColors.textPrimary(isDark);
    final textSecondary = LongcatColors.textSecondary(isDark);

    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            LongcatAppBar(
              leading: LongcatCircularIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
              title: 'Settings',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: LongcatSpacing.md),
                children: [
                  // ── Profile Header ───────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.settingsProfile),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: LongcatSpacing.lg),
                      child: Column(
                        children: [
                          LongcatAvatar(
                            name: user?.displayName ?? 'User',
                            size: 72,
                          ),
                          const SizedBox(height: LongcatSpacing.sm),
                          Text(
                            user?.displayName ?? 'User',
                            style: LongcatTypography.titleLarge(
                                color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: LongcatTypography.bodySmall(
                                color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: LongcatSpacing.xl),

                  // ── ACCOUNT ──────────────────────────────────
                  const LongcatSectionHeader('ACCOUNT'),
                  LongcatSettingsGroup(
                    children: [
                      LongcatListTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        subtitle: 'Name, email and user details',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsProfile),
                      ),
                      LongcatListTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Account',
                        subtitle: 'Security & login information',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsProfile),
                      ),
                    ],
                  ),

                  const SizedBox(height: LongcatSpacing.lg),

                  // ── AI ───────────────────────────────────────
                  const LongcatSectionHeader('AI'),
                  LongcatSettingsGroup(
                    children: [
                      LongcatListTile(
                        icon: Icons.smart_toy_outlined,
                        title: 'Model',
                        subtitle: 'Cloud AI endpoints and configuration',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settingsAi),
                      ),
                      LongcatListTile(
                        icon: Icons.tune_rounded,
                        title: 'AI Preferences',
                        subtitle: 'API keys & custom system prompts',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settingsAi),
                      ),
                    ],
                  ),

                  const SizedBox(height: LongcatSpacing.lg),

                  // ── PRIVACY & SECURITY ───────────────────────
                  const LongcatSectionHeader('PRIVACY & SECURITY'),
                  if (vault.isPrivateUnlocked || vault.isLibraryUnlocked)
                    LongcatSettingsGroup(
                      children: [
                        LongcatListTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Private Access',
                          subtitle: 'Stealth composer passcode & contacts',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.settingsPrivacy),
                        ),
                        LongcatListTile(
                          icon: Icons.shield_outlined,
                          title: 'Library Vault',
                          subtitle: 'Independent PIN protection for media',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.libraryLocked),
                        ),
                        LongcatListTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy',
                          subtitle: 'Zero data tracking & local security',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.settingsPrivacy),
                        ),
                        LongcatListTile(
                          icon: Icons.timer_outlined,
                          title: 'Auto-lock',
                          subtitle: 'Immediate session timeout on exit',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.settingsPrivacy),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: LongcatSpacing.lg),
                      child: Container(
                        padding: const EdgeInsets.all(LongcatSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? LongcatColors.darkSurfaceSecondary : LongcatColors.lightSurfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? LongcatColors.darkBorder : LongcatColors.lightBorder, width: 0.6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: LongcatColors.accent, size: 20),
                            const SizedBox(width: LongcatSpacing.sm),
                            Expanded(
                              child: Text(
                                'Sensitive security and vault settings are hidden until secret passcode is entered in AI chat.',
                                style: LongcatTypography.bodySmall(color: textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: LongcatSpacing.lg),

                  // ── APPEARANCE ───────────────────────────────
                  const LongcatSectionHeader('APPEARANCE'),
                  LongcatSettingsGroup(
                    children: [
                      LongcatListTile(
                        icon: isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Appearance',
                        subtitle: isDark ? 'Charcoal Black' : 'Pure Light',
                        onTap: () => theme.toggleTheme(),
                        trailing: Switch(
                          value: isDark,
                          activeThumbColor: LongcatColors.accent,
                          onChanged: (_) => theme.toggleTheme(),
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: LongcatSpacing.lg),

                  // ── NOTIFICATIONS ────────────────────────────
                  const LongcatSectionHeader('NOTIFICATIONS'),
                  LongcatSettingsGroup(
                    children: [
                      LongcatListTile(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notifications',
                        subtitle: 'Direct message and AI alerts',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsNotifications),
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: LongcatSpacing.lg),

                  // ── STORAGE ──────────────────────────────────
                  if (vault.isPrivateUnlocked || vault.isLibraryUnlocked) ...[
                    const LongcatSectionHeader('STORAGE'),
                    LongcatSettingsGroup(
                      children: [
                        LongcatListTile(
                          icon: Icons.data_usage_outlined,
                          title: 'Data & Storage',
                          subtitle: 'Local cache, export and database sync',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.settingsData),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: LongcatSpacing.lg),
                  ],

                  // ── SUPPORT ──────────────────────────────────
                  const LongcatSectionHeader('SUPPORT'),
                  LongcatSettingsGroup(
                    children: [
                      LongcatListTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help',
                        subtitle: 'Guides & FAQ',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support guides: help@longcat.ai'),
                            ),
                          );
                        },
                      ),
                      LongcatListTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'LONGCAT AI v1.0.0',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'LONGCAT AI',
                            applicationVersion: '1.0.0',
                            applicationLegalese:
                                '© 2026 LONGCAT AI. All rights reserved.',
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: LongcatSpacing.xl),

                  // ── Sign out ──────────────────────────────────
                  LongcatSettingsGroup(
                    children: [
                      InkWell(
                        onTap: () {
                          final chat = Provider.of<PrivateChatProvider>(context, listen: false);
                          final aiChat = Provider.of<AiChatProvider>(context, listen: false);
                          final library = Provider.of<LibraryProvider>(context, listen: false);
                          vault.lockAll();
                          auth.logout(
                            onClearChatSession: chat.clearSession,
                            onClearVaultSession: vault.clearSession,
                            onClearAiChatSession: aiChat.clearSession,
                            onClearLibrarySession: library.clearSession,
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.onboarding,
                            (route) => false,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: LongcatSpacing.md,
                            vertical: 14,
                          ),
                          child: Center(
                            child: Text(
                              'Sign out',
                              style: TextStyle(
                                color: LongcatColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: LongcatSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
