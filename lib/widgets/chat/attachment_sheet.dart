import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../services/cloudinary_service.dart';
import 'voice_note_recorder_sheet.dart';

/// Attachment sheet supporting Images (Camera & Photos), Documents (Any non-executable file), and Voice Notes.
/// Attempts Cloudinary upload first, falling back directly to Base64 string for offline/free operation.
class AttachmentSheet extends StatelessWidget {
  final Function(String mediaUrlOrBase64, String fileName)? onImageSelected;
  final Function(String documentUrlOrBase64, String fileName, String fileSize)? onDocumentSelected;
  final Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded;

  const AttachmentSheet({
    super.key,
    this.onImageSelected,
    this.onDocumentSelected,
    this.onVoiceNoteRecorded,
  });

  static Future<void> show(
    BuildContext context, {
    Function(String mediaUrlOrBase64, String fileName)? onImageSelected,
    Function(String documentUrlOrBase64, String fileName, String fileSize)? onDocumentSelected,
    Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded,
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
      builder: (_) => AttachmentSheet(
        onImageSelected: onImageSelected,
        onDocumentSelected: onDocumentSelected,
        onVoiceNoteRecorded: onVoiceNoteRecorded,
      ),
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
        
        // Attempt Cloudinary upload first
        final cloudUrl = await CloudinaryService.uploadFileBytes(
          fileBytes: bytes,
          fileName: file.name,
          resourceType: 'image',
        );

        if (cloudUrl != null && cloudUrl.isNotEmpty) {
          onImageSelected?.call(cloudUrl, file.name);
        } else {
          // Fallback to Base64
          final base64String = base64Encode(bytes);
          onImageSelected?.call(base64String, file.name);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final fileName = pickedFile.name;
        final bytes = pickedFile.bytes;

        // Block Executables / Potentially Harmful Files
        const blockedExts = {
          'exe', 'bat', 'cmd', 'sh', 'vbs', 'scr', 'msi', 'apk', 'com', 'pif', 
          'application', 'gadget', 'cpl', 'wsf', 'jar', 'ps1', 'reg', 'hta', 'inf', 'sys'
        };

        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        if (blockedExts.contains(ext)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Harmful/Executable file format (.$ext) is blocked for security.'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final sizeKb = (pickedFile.size / 1024).toStringAsFixed(1);
        final sizeText = pickedFile.size > 1024 * 1024
            ? '${(pickedFile.size / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '$sizeKb KB';

        if (bytes != null) {
          final cloudUrl = await CloudinaryService.uploadFileBytes(
            fileBytes: bytes,
            fileName: fileName,
            resourceType: 'raw',
          );

          if (cloudUrl != null && cloudUrl.isNotEmpty) {
            onDocumentSelected?.call(cloudUrl, fileName, sizeText);
          } else {
            final base64String = base64Encode(bytes);
            onDocumentSelected?.call(base64String, fileName, sizeText);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
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
              'Share Content',
              style: MiraloTypography.titleMedium(color: textColor),
            ),
            const SizedBox(height: MiraloSpacing.xs),
            Text(
              'Select media, files, or record a voice note',
              style: MiraloTypography.bodySmall(color: subColor),
            ),
            const SizedBox(height: MiraloSpacing.lg),

            // Camera, Photos, Document & Voice Note options
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
                _ImageActionTile(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'File',
                  bgColor: iconBg,
                  textColor: textColor,
                  onTap: () => _pickDocument(context),
                ),
                _ImageActionTile(
                  icon: Icons.mic_none_rounded,
                  label: 'Voice Note',
                  bgColor: iconBg,
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    VoiceNoteRecorderSheet.show(
                      context,
                      onVoiceNoteRecorded: onVoiceNoteRecorded,
                    );
                  },
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

