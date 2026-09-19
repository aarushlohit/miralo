import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/miralo_tokens.dart';

/// Attachment sheet strictly allowing images only (Camera & Photos).
/// Converts selected image directly to Base64 string for realtime transmission.
class AttachmentSheet extends StatelessWidget {
  final Function(String base64Image, String fileName)? onImageSelected;

  const AttachmentSheet({super.key, this.onImageSelected});

  static Future<void> show(
    BuildContext context, {
    Function(String base64Image, String fileName)? onImageSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark
          ? MiraloColors.darkSurfacePrimary
          : MiraloColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MiraloRadius.bottomSheet),
        ),
      ),
      builder: (_) => AttachmentSheet(onImageSelected: onImageSelected),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        onImageSelected?.call(base64String, file.name);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final subColor = isDark
        ? MiraloColors.darkTextSecondary
        : MiraloColors.lightTextSecondary;
    final iconBg = isDark
        ? MiraloColors.darkSurfaceSecondary
        : MiraloColors.lightSurfaceSecondary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MiraloSpacing.lg,
          vertical: MiraloSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Share Image',
              style: MiraloTypography.titleMedium(color: textColor),
            ),
            const SizedBox(height: MiraloSpacing.xs),
            Text(
              'Select an image to send securely',
              style: MiraloTypography.bodySmall(color: subColor),
            ),
            const SizedBox(height: MiraloSpacing.lg),

            // Strictly Images Only: Camera & Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ImageActionTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  bgColor: iconBg,
                  textColor: textColor,
                  onTap: () => _pickImage(context, ImageSource.camera),
                ),
                _ImageActionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Photos',
                  bgColor: iconBg,
                  textColor: textColor,
                  onTap: () => _pickImage(context, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: MiraloSpacing.lg),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: MiraloTypography.bodyMedium(color: subColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ImageActionTile({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MiraloRadius.r16,
      child: Padding(
        padding: const EdgeInsets.all(MiraloSpacing.md),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: MiraloColors.accent, size: 24),
            ),
            const SizedBox(height: MiraloSpacing.xs),
            Text(label, style: MiraloTypography.labelMedium(color: textColor)),
          ],
        ),
      ),
    );
  }
}
