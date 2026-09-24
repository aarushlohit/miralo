import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../services/cloudinary_service.dart';
import '../../services/file_security_service.dart';
import 'voice_note_recorder_sheet.dart';

import 'giphy_picker_sheet.dart';

/// Attachment sheet supporting Images (Camera & Photos), Documents (Any non-executable file), Voice Notes, and GIPHY GIFs.
/// Attempts Cloudinary upload first, falling back directly to Base64 string for offline/free operation.
class AttachmentSheet extends StatelessWidget {
  final Function(String mediaUrlOrBase64, String fileName)? onImageSelected;
  final Function(String documentUrlOrBase64, String fileName, String fileSize)? onDocumentSelected;
  final Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded;
  final Function(String gifUrl, String title)? onGifSelected;

  const AttachmentSheet({
    super.key,
    this.onImageSelected,
    this.onDocumentSelected,
    this.onVoiceNoteRecorded,
    this.onGifSelected,
  });

  static Future<void> show(
    BuildContext context, {
    Function(String mediaUrlOrBase64, String fileName)? onImageSelected,
    Function(String documentUrlOrBase64, String fileName, String fileSize)? onDocumentSelected,
    Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded,
    Function(String gifUrl, String title)? onGifSelected,
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
        onGifSelected: onGifSelected,
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
        Uint8List? bytes = pickedFile.bytes;
        if (bytes == null && pickedFile.path != null) {
          try {
            bytes = await File(pickedFile.path!).readAsBytes();
          } catch (e) {
            debugPrint('Error reading file bytes from path: $e');
          }
        }

        // Comprehensive Anti-Spoofing & Binary Header Validation
        final validation = FileSecurityService.validateFile(
          rawFileName: fileName,
          fileBytes: bytes,
        );

        if (!validation.isValid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validation.errorMessage ?? 'File blocked for security.'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        final safeFileName = validation.sanitizedFileName;
        final sizeKb = (pickedFile.size / 1024).toStringAsFixed(1);
        final sizeText = pickedFile.size > 1024 * 1024
            ? '${(pickedFile.size / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '$sizeKb KB';

        if (bytes != null) {
          final cloudUrl = await CloudinaryService.uploadFileBytes(
            fileBytes: bytes,
            fileName: safeFileName,
            resourceType: 'raw',
          );

          if (cloudUrl != null && cloudUrl.isNotEmpty) {
            onDocumentSelected?.call(cloudUrl, safeFileName, sizeText);
          } else {
            final base64String = base64Encode(bytes);
            onDocumentSelected?.call(base64String, safeFileName, sizeText);
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: MiraloSpacing.md,
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

            // Camera, Photos, Document, Voice Note & GIPHY GIF options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
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
                _ImageActionTile(
                  icon: Icons.gif_box_outlined,
                  label: 'GIF',
                  bgColor: iconBg,
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    if (onGifSelected != null) {
                      GiphyPickerSheet.show(
                        context,
                        onGifSelected: onGifSelected!,
                      );
                    }
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
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: MiraloSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: MiraloColors.accent, size: 24),
            ),
            const SizedBox(height: MiraloSpacing.xs),
            Text(
              label,
              style: MiraloTypography.labelMedium(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

