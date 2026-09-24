import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  DownloadService._();

  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.miralo.ai/media_scanner');

  /// Determine the Miralo subfolder category based on file extension and type.
  static String getCategory(String fileName, [String? type]) {
    final lowerName = fileName.toLowerCase();
    final lowerType = type?.toLowerCase() ?? '';

    if (lowerType == 'voice' ||
        lowerType == 'audio' ||
        lowerName.endsWith('.m4a') ||
        lowerName.endsWith('.mp3') ||
        lowerName.endsWith('.wav') ||
        lowerName.endsWith('.aac') ||
        lowerName.endsWith('.ogg') ||
        lowerName.endsWith('.opus') ||
        lowerName.endsWith('.flac')) {
      return 'Audio';
    }

    if (lowerType == 'video' ||
        lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.webm') ||
        lowerName.endsWith('.3gp')) {
      return 'Videos';
    }

    if (lowerType == 'image' ||
        lowerType == 'photo' ||
        lowerType == 'gif' ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.svg')) {
      return 'Images';
    }

    return 'Documents';
  }

  /// Resolve the destination directory.
  /// Images are saved to `/Pictures/Miralo` so they appear directly in the Android Gallery.
  /// Videos are saved to `/Movies/Miralo`.
  /// Documents and Audio are saved to `/Download/Miralo/<Category>`.
  static Future<Directory> getMiraloDirectory(String category) async {
    Directory? baseDir;

    if (Platform.isAndroid) {
      if (category == 'Images') {
        final pictures = Directory('/storage/emulated/0/Pictures/Miralo');
        if (!pictures.existsSync()) {
          try {
            pictures.createSync(recursive: true);
            return pictures;
          } catch (_) {}
        } else {
          return pictures;
        }
      } else if (category == 'Videos') {
        final movies = Directory('/storage/emulated/0/Movies/Miralo');
        if (!movies.existsSync()) {
          try {
            movies.createSync(recursive: true);
            return movies;
          } catch (_) {}
        } else {
          return movies;
        }
      }

      final publicDownload = Directory('/storage/emulated/0/Download');
      if (publicDownload.existsSync()) {
        baseDir = publicDownload;
      } else {
        baseDir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }

    baseDir ??= await getApplicationDocumentsDirectory();
    final targetDir = Directory('${baseDir.path}/Miralo/$category');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }
    return targetDir;
  }

  /// Triggers Android MediaScanner so media files appear immediately in Gallery
  static Future<void> scanMediaFile(String filePath) async {
    if (!Platform.isAndroid) return;
    try {
      await _mediaScannerChannel.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      debugPrint('MediaScanner error: $e');
    }
  }

  /// Save raw bytes to destination and trigger gallery indexing for media
  static Future<File> saveFile({
    required String fileName,
    required Uint8List bytes,
    String? type,
  }) async {
    final category = getCategory(fileName, type);
    final dir = await getMiraloDirectory(category);

    String cleanName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    File targetFile = File('${dir.path}/$cleanName');

    // If file already exists, append timestamp
    if (targetFile.existsSync()) {
      final dotIndex = cleanName.lastIndexOf('.');
      if (dotIndex != -1) {
        final name = cleanName.substring(0, dotIndex);
        final ext = cleanName.substring(dotIndex);
        cleanName = '${name}_${DateTime.now().millisecondsSinceEpoch}$ext';
      } else {
        cleanName = '${cleanName}_${DateTime.now().millisecondsSinceEpoch}';
      }
      targetFile = File('${dir.path}/$cleanName');
    }

    await targetFile.writeAsBytes(bytes);

    // Trigger media scanner for images & videos
    if (category == 'Images' || category == 'Videos' || category == 'Audio') {
      await scanMediaFile(targetFile.path);
    }

    return targetFile;
  }

  /// Launch file viewer using open_filex
  static Future<OpenResult> openFile(String filePath) async {
    try {
      return await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint('OpenFilex error: $e');
      return OpenResult(type: ResultType.error, message: e.toString());
    }
  }

  /// Complete download flow with SnackBar showing saved destination and "OPEN" action.
  static Future<File?> downloadAndPrompt(
    BuildContext context, {
    required String fileName,
    required Uint8List bytes,
    String? type,
  }) async {
    try {
      final category = getCategory(fileName, type);
      final file = await saveFile(fileName: fileName, bytes: bytes, type: type);

      if (context.mounted) {
        final isMedia = category == 'Images' || category == 'Videos';
        final message = isMedia
            ? 'Saved to Gallery & Pictures/Miralo'
            : 'Saved to Miralo/$category/$fileName';

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => openFile(file.path),
            ),
          ),
        );
      }
      return file;
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
      return null;
    }
  }
}
