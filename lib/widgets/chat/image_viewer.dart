import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Fullscreen Image Viewer supporting Base64, network, and asset images.
class ImageViewer extends StatelessWidget {
  final String? imageBase64;
  final String? imageUrl;
  final String title;

  const ImageViewer({
    super.key,
    this.imageBase64,
    this.imageUrl,
    this.title = 'Image',
  });

  static void show(
    BuildContext context, {
    String? imageBase64,
    String? imageUrl,
    String title = 'Image',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          imageBase64: imageBase64,
          imageUrl: imageUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiraloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: MiraloColors.darkTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: MiraloTypography.titleMedium(color: MiraloColors.darkTextPrimary),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64!);
        return ClipRRect(
          borderRadius: MiraloRadius.r16,
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      } catch (_) {}
    }

    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: MiraloRadius.r16,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: MiraloColors.darkSurfaceSecondary,
        borderRadius: MiraloRadius.r16,
        border: Border.all(color: MiraloColors.darkBorder),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: MiraloColors.darkTextMuted, size: 48),
      ),
    );
  }
}
