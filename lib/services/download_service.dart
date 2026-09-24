import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  DownloadService._();

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

  /// Resolve the destination directory: `/Download/Miralo/<Category>`
  static Future<Directory> getMiraloDirectory(String category) async {
    Directory? baseDir;

    if (Platform.isAndroid) {
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

  /// Save raw bytes to `Miralo/<Category>/<fileName>`
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

  /// Complete download flow with SnackBar showing "Saved to `Miralo/<Category>`" and "OPEN FILE" action.
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Miralo/$category/$fileName'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN FILE',
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
