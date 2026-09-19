import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/miralo_list_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _privateChatAlerts = true;
  bool _soundEnabled = false;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
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
        title: Text('Notifications',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          children: [
            MiraloSectionHeader('ALERTS & MESSAGES'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.notifications_outlined,
                  title: 'Allow Notifications',
                  subtitle: 'Receive message and assistant alerts',
                  showChevron: false,
                  trailing: Switch(
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.shield_outlined,
                  title: 'Discreet Private Alerts',
                  subtitle: 'Generic alert without sender or content',
                  showChevron: false,
                  trailing: Switch(
                    value: _privateChatAlerts,
                    onChanged: (v) => setState(() => _privateChatAlerts = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            MiraloSectionHeader('SOUND & HAPTICS'),
            MiraloSettingsGroup(
              children: [
                MiraloListTile(
                  icon: Icons.volume_up_outlined,
                  title: 'In-app Sounds',
                  subtitle: 'Subtle sound effects for messages',
                  showChevron: false,
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                  ),
                ),
                MiraloListTile(
                  icon: Icons.vibration,
                  title: 'Haptic Feedback',
                  subtitle: 'Tactile responses on interactions',
                  showChevron: false,
                  trailing: Switch(
                    value: _vibration,
                    onChanged: (v) => setState(() => _vibration = v),
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
