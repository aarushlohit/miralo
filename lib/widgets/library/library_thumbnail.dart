import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/library_item_model.dart';

/// Renders either an actual image thumbnail (file, network, or base64)
/// or a styled icon badge for non-image items in the Library Vault.
class LibraryThumbnail extends StatelessWidget {
  final LibraryItemModel item;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const LibraryThumbnail({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(10);
    final url = item.thumbnailUrl;

    if (item.type == 'image' && url != null && url.isNotEmpty) {
      Widget imageWidget;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        imageWidget = Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _fallbackIcon(),
        );
      } else if (File(url).existsSync()) {
        imageWidget = Image.file(
          File(url),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _fallbackIcon(),
        );
      } else if (url.length > 50 && !url.contains('/') && !url.contains('\\')) {
        try {
          imageWidget = Image.memory(
            base64Decode(url),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _fallbackIcon(),
          );
        } catch (_) {
          imageWidget = _fallbackIcon();
        }
      } else {
        imageWidget = _fallbackIcon();
      }

      return ClipRRect(
        borderRadius: br,
        child: SizedBox(
          width: width,
          height: height,
          child: imageWidget,
        ),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    IconData icon;
    Color iconColor;

    if (item.type == 'image') {
      icon = Icons.photo_outlined;
      iconColor = AppColors.accent;
    } else if (item.type == 'video') {
      icon = Icons.videocam_outlined;
      iconColor = AppColors.accentHover;
    } else if (item.type == 'zip') {
      icon = Icons.folder_zip_outlined;
      iconColor = AppColors.warning;
    } else {
      icon = Icons.description_outlined;
      iconColor = Colors.blueGrey;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          icon,
          size: (width != null && width! < 45) ? 22 : 28,
          color: iconColor,
        ),
      ),
    );
  }
}
