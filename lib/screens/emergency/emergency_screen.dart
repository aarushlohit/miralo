import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_button.dart';
import '../../widgets/common/miralo_list_tile.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  void _executeQuickExit(BuildContext context) {
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final ai = Provider.of<AiChatProvider>(context, listen: false);

    // 1. Lock private workspace & library
    vault.emergencyLockEverything();

    // 2. Clear current chat and create new AI chat
    ai.createNewChat();

    // 3. Navigate back to AI home instantly with prefill question
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
      arguments: {'prefill': 'What is an API?'},
    );
  }

  void _showConfirmWipe(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: AppTypography.heading3(color: AppColors.danger)),
          ],
        ),
        content: Text(message, style: AppTypography.bodySmall()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm Wipe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final chat = Provider.of<PrivateChatProvider>(context, listen: false);
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

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
        title: Text('Emergency Controls',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // Shield Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.shield_outlined,
                    size: 36, color: AppColors.accent),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text('Quick Exit',
                  style: AppTypography.heading2(color: textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Immediately lock all private content and\nswitch to a safe, neutral AI conversation.',
                style: AppTypography.body(color: textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Quick Exit Button
              MiraloButton(
                label: 'Exit to AI Chat',
                variant: MiraloButtonVariant.destructive,
                icon: Icons.exit_to_app_rounded,
                onPressed: () => _executeQuickExit(context),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Tip: You can also type /urgent in any private composer',
                style: AppTypography.caption(color: textMuted),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Destructive Actions
              MiraloSectionHeader('PERMANENT DATA WIPE'),
              MiraloSettingsGroup(
                children: [
                  MiraloListTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Wipe All Private Chats',
                    subtitle: 'Erases all contacts, message logs, and reactions',
                    destructive: true,
                    showChevron: false,
                    onTap: () {
                      _showConfirmWipe(
                        context,
                        title: 'Wipe Private Chats',
                        message: 'This will permanently destroy all private conversations and contacts on this device.',
                        onConfirm: () {
                          chat.emergencyWipeAllChats();
                          vault.lockPrivate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All private chats wiped.')),
                          );
                        },
                      );
                    },
                  ),
                  MiraloListTile(
                    icon: Icons.folder_delete_outlined,
                    title: 'Wipe Secure Library Vault',
                    subtitle: 'Destroys all encrypted documents and media',
                    destructive: true,
                    showChevron: false,
                    onTap: () {
                      _showConfirmWipe(
                        context,
                        title: 'Wipe Library Vault',
                        message: 'This will permanently delete all encrypted files, images, and folders.',
                        onConfirm: () {
                          library.emergencyWipeLibrary();
                          vault.lockLibrary();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Library vault wiped.')),
                          );
                        },
                      );
                    },
                  ),
                  MiraloListTile(
                    icon: Icons.power_settings_new,
                    title: 'Complete Reset & Sign Out',
                    subtitle: 'Full device purge and session termination',
                    destructive: true,
                    showChevron: false,
                    onTap: () {
                      _showConfirmWipe(
                        context,
                        title: 'Full Reset',
                        message: 'This will wipe all chats, vault data, and restore app to initial state.',
                        onConfirm: () {
                          final ai = Provider.of<AiChatProvider>(context, listen: false);
                          chat.emergencyWipeAllChats();
                          library.emergencyWipeLibrary();
                          vault.lockAll();
                          auth.logout(
                            onClearChatSession: chat.clearSession,
                            onClearVaultSession: vault.clearSession,
                            onClearAiChatSession: ai.clearSession,
                            onClearLibrarySession: library.clearSession,
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
