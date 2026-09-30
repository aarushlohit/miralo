import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/longcat_tokens.dart';
import '../../services/cloudinary_service.dart';
import '../../services/file_security_service.dart';
import 'voice_note_recorder_sheet.dart';

import 'giphy_picker_sheet.dart';

/// Attachment sheet supporting Images (Camera & Photos), Documents (Any non-executable file), Voice Notes, and GIPHY GIFs.
/// Attempts Cloudinary upload first, falling back directly to Base64 string for offline/free operation.
class AttachmentSheet extends StatelessWidget {
  final bool isImageOnly;
  final Function(String mediaUrlOrBase64, String fileName)? onImageSelected;
  final Function(String documentUrlOrBase64, String fileName, String fileSize)? onDocumentSelected;
  final Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded;
  final Function(String gifUrl, String title)? onGifSelected;

  const AttachmentSheet({
    super.key,
    this.isImageOnly = false,
    this.onImageSelected,
    this.onDocumentSelected,
    this.onVoiceNoteRecorded,
    this.onGifSelected,
  });

  static Future<void> show(
    BuildContext context, {
    bool isImageOnly = false,
    Function(String mediaUrlOrBase64, String fileName)? onImageSelected,
    Function(String documentUrlOrBase64, String fileName, String fileSize)? onDocumentSelected,
    Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded,
    Function(String gifUrl, String title)? onGifSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? LongcatColors.darkSurfacePrimary
          : LongcatColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LongcatRadius.bottomSheet),
        ),
      ),
      builder: (_) => AttachmentSheet(
        isImageOnly: isImageOnly,
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
        ? LongcatColors.darkTextPrimary
        : LongcatColors.lightTextPrimary;
    final subColor = isDark
        ? LongcatColors.darkTextSecondary
        : LongcatColors.lightTextSecondary;
    final border = isDark
        ? LongcatColors.darkBorder
        : LongcatColors.lightBorder;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            LongcatSpacing.md,
            LongcatSpacing.md,
            LongcatSpacing.md,
            MediaQuery.of(context).viewInsets.bottom + LongcatSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: LongcatSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isImageOnly ? 'Attach Image' : 'Share Content',
              style: LongcatTypography.titleMedium(color: textColor),
            ),
            const SizedBox(height: LongcatSpacing.xs),
            Text(
              isImageOnly
                  ? 'Select a photo from Camera or Gallery (Max 1 image)'
                  : 'Select media, files, or record a voice note',
              style: LongcatTypography.bodySmall(color: subColor),
            ),
            const SizedBox(height: LongcatSpacing.lg),

            if (isImageOnly)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      bgColor: const Color(0xFFE11D48).withValues(alpha: 0.15),
                      iconColor: const Color(0xFFE11D48),
                      textColor: textColor,
                      onTap: () => _pickImage(context, ImageSource.camera),
                    ),
                  ),
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Photos',
                      bgColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                      iconColor: const Color(0xFF4F46E5),
                      textColor: textColor,
                      onTap: () => _pickImage(context, ImageSource.gallery),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'File',
                      bgColor: const Color(0xFFD97706).withValues(alpha: 0.15),
                      iconColor: const Color(0xFFD97706),
                      textColor: textColor,
                      onTap: () => _pickDocument(context),
                    ),
                  ),
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      bgColor: const Color(0xFFE11D48).withValues(alpha: 0.15),
                      iconColor: const Color(0xFFE11D48),
                      textColor: textColor,
                      onTap: () => _pickImage(context, ImageSource.camera),
                    ),
                  ),
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Photos',
                      bgColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                      iconColor: const Color(0xFF4F46E5),
                      textColor: textColor,
                      onTap: () => _pickImage(context, ImageSource.gallery),
                    ),
                  ),
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.mic_rounded,
                      label: 'Voice Note',
                      bgColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      iconColor: const Color(0xFF0D9488),
                      textColor: textColor,
                      onTap: () {
                        Navigator.pop(context);
                        VoiceNoteRecorderSheet.show(
                          context,
                          onVoiceNoteRecorded: onVoiceNoteRecorded,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _ImageActionTile(
                      icon: Icons.gif_box_rounded,
                      label: 'GIF',
                      bgColor: const Color(0xFF059669).withValues(alpha: 0.15),
                      iconColor: const Color(0xFF059669),
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
                  ),
                ],
              ),
            const SizedBox(height: LongcatSpacing.lg),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: LongcatTypography.bodyMedium(color: subColor)),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ImageActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color? iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ImageActionTile({
    required this.icon,
    required this.label,
    required this.bgColor,
    this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: LongcatRadius.r16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: LongcatSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? LongcatColors.accent, size: 24),
            ),
            const SizedBox(height: LongcatSpacing.xs),
            Text(
              label,
              style: LongcatTypography.labelMedium(color: textColor).copyWith(fontSize: 11),
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

