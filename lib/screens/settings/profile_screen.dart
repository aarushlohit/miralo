import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _showAvatarPicker(BuildContext context, AuthProvider auth) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
                title: Text('Take Photo', style: AppTypography.body(color: textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 85);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    await auth.uploadCustomAvatar(bytes, picked.name);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text('Choose from Gallery', style: AppTypography.body(color: textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    await auth.uploadCustomAvatar(bytes, picked.name);
                  }
                },
              ),
              if (auth.currentUser?.avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: Text('Remove Avatar', style: AppTypography.body(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    auth.updateProfile(avatarUrl: '');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, AuthProvider auth, String? currentNote) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: currentNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('Share a Note', style: AppTypography.heading3(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your note appears above your avatar for friends to see.',
              style: AppTypography.caption(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: ctrl,
              maxLength: 60,
              autofocus: true,
              style: AppTypography.body(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: AppTypography.body(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          if (currentNote != null && currentNote.isNotEmpty)
            TextButton(
              onPressed: () {
                auth.updateProfile(note: '');
                Navigator.pop(ctx);
              },
              child: Text('Clear', style: AppTypography.bodyMedium(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodyMedium(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              auth.updateProfile(note: ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditBioDialog(BuildContext context, AuthProvider auth, String? currentBio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: currentBio ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Bio', style: AppTypography.heading3(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A brief description displayed on your profile.',
              style: AppTypography.caption(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: ctrl,
              maxLength: 150,
              maxLines: 3,
              autofocus: true,
              style: AppTypography.body(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'Write a short bio...',
                hintStyle: AppTypography.body(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          if (currentBio != null && currentBio.isNotEmpty)
            TextButton(
              onPressed: () {
                auth.updateProfile(bio: '');
                Navigator.pop(ctx);
              },
              child: Text('Clear', style: AppTypography.bodyMedium(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodyMedium(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              auth.updateProfile(bio: ctrl.text.trim());
              Navigator.pop(ctx);
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
                  // Centered Avatar with Note Bubble
                  Center(
                    child: Column(
                      children: [
                        // Instagram-style note bubble
                        GestureDetector(
                          onTap: () => _showEditNoteDialog(context, auth, user?.note),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (user?.note != null && user!.note!.isNotEmpty)
                                    ? AppColors.accent.withValues(alpha: 0.5)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 13,
                                  color: (user?.note != null && user!.note!.isNotEmpty) ? AppColors.accent : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (user?.note != null && user!.note!.isNotEmpty)
                                      ? user.note!
                                      : 'Share a note...',
                                  style: AppTypography.caption(
                                    color: (user?.note != null && user!.note!.isNotEmpty) ? textPrimary : textSecondary,
                                  ).copyWith(
                                    fontStyle: (user?.note != null && user!.note!.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                                    fontWeight: (user?.note != null && user!.note!.isNotEmpty) ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Avatar with Camera Badge
                        GestureDetector(
                          onTap: () => _showAvatarPicker(context, auth),
                          child: Stack(
                            children: [
                              MiraloAvatar(
                                name: user?.displayName ?? 'User',
                                imageUrl: user?.avatarUrl,
                                size: 92,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bg, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          user?.displayName ?? 'User',
                          style: AppTypography.heading2(color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? ''}',
                          style: AppTypography.bodySmall(color: AppColors.accent).copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH * 1.5),
                            child: Text(
                              user.bio!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall(color: textSecondary),
                            ),
                          ),
                        ],
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
                        icon: Icons.alternate_email,
                        title: 'Username',
                        subtitle: '@${user?.username ?? ''}',
                        showChevron: false,
                      ),
                      MiraloListTile(
                        icon: Icons.mail_outline,
                        title: 'Email Address',
                        subtitle: user?.email ?? 'Not set',
                        showChevron: false,
                      ),
                      MiraloListTile(
                        icon: Icons.notes_rounded,
                        title: 'Bio',
                        subtitle: (user?.bio != null && user!.bio!.isNotEmpty) ? user.bio! : 'Tap to add a bio...',
                        showChevron: true,
                        onTap: () => _showEditBioDialog(context, auth, user?.bio),
                      ),
                      MiraloListTile(
                        icon: Icons.edit_note_rounded,
                        title: 'Note',
                        subtitle: (user?.note != null && user!.note!.isNotEmpty) ? user.note! : 'Tap to share a note...',
                        showChevron: true,
                        onTap: () => _showEditNoteDialog(context, auth, user?.note),
                      ),
                      MiraloListTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Account Status',
                        subtitle: 'Active',
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
