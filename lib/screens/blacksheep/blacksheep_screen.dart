import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/chat/image_viewer.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_empty_state.dart';

/// Blacksheep Screen — Displayed after unlocking with the secret PIN/passcode.
/// Visualizes intruder access attempts with a red dot indicator on new unread logs.
class BlacksheepScreen extends StatefulWidget {
  const BlacksheepScreen({super.key});

  @override
  State<BlacksheepScreen> createState() => _BlacksheepScreenState();
}

class _BlacksheepScreenState extends State<BlacksheepScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final intruderLogs = vault.intruderLogs;

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
              title: 'Blacksheep Security',
              actions: [
                if (intruderLogs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      vault.clearIntruderLogs();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Intruder logs cleared.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
                    label: Text('Clear Logs', style: AppTypography.caption(color: AppColors.danger)),
                  ),
              ],
            ),
            Expanded(
              child: intruderLogs.isEmpty
                  ? const MiraloEmptyState(
                      icon: Icons.shield_outlined,
                      title: 'No Intruder Activity',
                      subtitle: 'Your workspace is secure. No unauthorized access or failed login attempts recorded.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: intruderLogs.length,
                      itemBuilder: (context, index) {
                        final log = intruderLogs[index];
                        final isNew = index == intruderLogs.length - 1; // latest attempt has red dot indicator

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isNew ? AppColors.danger.withValues(alpha: 0.8) : border,
                              width: isNew ? 1.5 : 0.8,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Red dot indicator for new incorrect login
                                        if (isNew) ...[
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: AppColors.danger,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.danger,
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                        ],
                                        Text(
                                          'Unauthorised Access Attempt',
                                          style: AppTypography.heading3(color: textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target: ${log.attemptType.toUpperCase()} | Failed Attempts: ${log.failedAttempts}',
                                      style: AppTypography.caption(color: textSecondary),
                                    ),
                                    Text(
                                      'Captured At: ${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                      style: AppTypography.caption(color: textSecondary),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    // Intruder captured photo preview frame
                                    _buildIntruderPhotoFrame(context, log.photoBase64, isDark, textSecondary),
                                  ],
                                ),
                              ),
                              if (isNew)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'NEW',
                                      style: AppTypography.caption(color: Colors.white).copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntruderPhotoFrame(BuildContext context, String? photoBase64, bool isDark, Color textSecondary) {
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(photoBase64);
        return GestureDetector(
          onTap: () => ImageViewer.show(
            context,
            imageBase64: photoBase64,
            title: 'Intruder Photo',
          ),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildNoPhotoFallback(isDark, textSecondary),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to Expand',
                            style: AppTypography.caption(color: Colors.white).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (_) {}
    }

    return _buildNoPhotoFallback(isDark, textSecondary);
  }

  Widget _buildNoPhotoFallback(bool isDark, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography_outlined, size: 20, color: textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'No Camera Frame Available',
            style: AppTypography.caption(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
