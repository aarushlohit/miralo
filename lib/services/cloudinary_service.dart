import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for uploading media & documents to Cloudinary (Free Tier).
class CloudinaryService {
  // Configurable Cloudinary Cloud Name and Upload Preset
  static String cloudName = 'miralo_app'; 
  static String uploadPreset = 'miralo_preset';

  /// Configure Cloudinary credentials dynamically
  static void configure({required String newCloudName, required String newUploadPreset}) {
    cloudName = newCloudName;
    uploadPreset = newUploadPreset;
  }

  /// Uploads raw file bytes to Cloudinary and returns public secure HTTPS URL.
  /// Handles images, documents (PDF, DOCX, TXT), audio, and video files.
  static Future<String?> uploadFileBytes({
    required Uint8List fileBytes,
    required String fileName,
    String resourceType = 'auto', // 'image', 'raw', 'video', or 'auto'
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Cloudinary upload success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary upload error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
  }

  /// Uploads file path to Cloudinary.
  static Future<String?> uploadFilePath(
    String filePath, {
    String resourceType = 'auto',
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      return await uploadFileBytes(
        fileBytes: bytes,
        fileName: fileName,
        resourceType: resourceType,
      );
    } catch (e) {
      debugPrint('Error uploading file path: $e');
      return null;
    }
  }
}
