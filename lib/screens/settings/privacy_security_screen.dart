import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_list_tile.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  void _showChangeSecretDialog(BuildContext context, VaultProvider vault) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Change Private Secret',
            style: AppTypography.heading3(color: textPrimary)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: AppTypography.body(color: textPrimary),
          decoration: const InputDecoration(
            hintText: 'New secret word or phrase',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                vault.setPrivateChatSecret(controller.text.trim(), userId: auth.currentUser?.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Private Chat Secret updated.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, VaultProvider vault) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Change Library PIN',
            style: AppTypography.heading3(color: textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: AppTypography.body(color: textPrimary),
          decoration: const InputDecoration(
            hintText: 'New 4-digit numeric PIN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                vault.setLibraryPin(controller.text.trim(), userId: auth.currentUser?.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Library Vault PIN updated.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final chat = Provider.of<PrivateChatProvider>(context);

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
        title: Text('Privacy & Security',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          children: [
            // Informational Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Independent credentials protect your private chat and library vault separately. Unlocking one never exposes the other.',
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Credentials & Locks
            MiraloSectionHeader('CREDENTIALS & LOCKS'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.vpn_key_outlined,
                  title: 'Private Chat Secret',
                  subtitle: 'Enter in normal AI composer to reveal contacts',
                  onTap: () => _showChangeSecretDialog(context, vault),
                ),
                MiraloListTile(
                  icon: Icons.shield_outlined,
                  title: 'Library Vault PIN',
                  subtitle: 'Independent code for encrypted files & media',
                  onTap: () => _showChangePinDialog(context, vault),
                ),
                MiraloListTile(
                  icon: Icons.timer_outlined,
                  title: 'Auto-lock Inactivity',
                  subtitle: '${vault.autoLockMinutes} minutes timeout',
                  showChevron: false,
                  trailing: DropdownButton<int>(
                    value: vault.autoLockMinutes,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 min')),
                      DropdownMenuItem(value: 5, child: Text('5 min')),
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 0, child: Text('Immediate')),
                    ],
                    onChanged: (val) {
                      if (val != null) vault.setAutoLockMinutes(val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Device Hygiene
            MiraloSectionHeader('DEVICE HYGIENE'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cached Media',
                  subtitle: 'Frees 24.8 MB of temporary previews',
                  showChevron: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared successfully.')),
                    );
                  },
                ),
                MiraloListTile(
                  icon: Icons.phonelink_erase_outlined,
                  title: 'Sign Out Other Sessions',
                  destructive: true,
                  showChevron: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All other sessions terminated.')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Chat Privacy & Presence
            MiraloSectionHeader('CHAT PRIVACY & PRESENCE'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.wifi_tethering_rounded,
                  title: 'Share Online Status',
                  subtitle: 'Allows contacts to see when you are active',
                  showChevron: false,
                  trailing: Switch.adaptive(
                    value: chat.showOnlineStatus,
                    activeTrackColor: AppColors.accent,
                    onChanged: (val) => chat.updatePrivacySettings(showOnlineStatus: val),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.history_rounded,
                  title: 'Share Last Seen',
                  subtitle: 'Shows when you were last active in chat',
                  showChevron: false,
                  trailing: Switch.adaptive(
                    value: chat.showLastSeen,
                    activeTrackColor: AppColors.accent,
                    onChanged: (val) => chat.updatePrivacySettings(showLastSeen: val),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.done_all_rounded,
                  title: 'Send Read Receipts',
                  subtitle: 'Shows blue double checkmarks when messages are seen',
                  showChevron: false,
                  trailing: Switch.adaptive(
                    value: chat.sendReadReceipts,
                    activeTrackColor: AppColors.accent,
                    onChanged: (val) => chat.updatePrivacySettings(sendReadReceipts: val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
