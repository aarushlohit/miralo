import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/private_contact_model.dart';
import '../models/private_message_model.dart';
import 'cloudinary_service.dart';

/// Service for Chat Cloud Auto-Backup, Zip Export, and Zip Import.
class ChatBackupService {
  /// Encodes all contacts and messages into a formatted JSON string.
  static String createBackupJson({
    required List<PrivateContactModel> contacts,
    required Map<String, List<PrivateMessageModel>> messages,
  }) {
    final payload = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'messages': messages.map(
        (key, list) => MapEntry(key, list.map((m) => m.toJson()).toList()),
      ),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Exports chats into a .zip file and triggers file save / picker.
  static Future<Uint8List?> exportChatsToZip({
    required List<PrivateContactModel> contacts,
    required Map<String, List<PrivateMessageModel>> messages,
  }) async {
    try {
      final jsonString = createBackupJson(contacts: contacts, messages: messages);
      final jsonBytes = utf8.encode(jsonString);

      final archive = Archive()
        ..addFile(
          ArchiveFile('miralo_chat_backup.json', jsonBytes.length, jsonBytes),
        );

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return null;

      final resultBytes = Uint8List.fromList(zipBytes);

      // Attempt Cloudinary Auto-Backup as raw file
      final fileName = 'miralo_chat_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      CloudinaryService.uploadFileBytes(
        fileBytes: resultBytes,
        fileName: fileName,
        resourceType: 'raw',
      );

      return resultBytes;
    } catch (e) {
      debugPrint('Error exporting chats to zip: $e');
      return null;
    }
  }

  /// Imports chats from a picked .zip file or raw zip bytes.
  static Future<Map<String, dynamic>?> importChatsFromZip(Uint8List zipBytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      ArchiveFile? jsonFile;

      for (final file in archive) {
        if (file.name.endsWith('.json')) {
          jsonFile = file;
          break;
        }
      }

      if (jsonFile == null) {
        debugPrint('No JSON backup file found inside ZIP archive.');
        return null;
      }

      final jsonContent = utf8.decode(jsonFile.content as List<int>);
      final rawMap = jsonDecode(jsonContent) as Map<String, dynamic>;

      final rawContacts = (rawMap['contacts'] as List? ?? []);
      final contacts = rawContacts
          .whereType<Map>()
          .map((c) => PrivateContactModel.fromJson(Map<String, dynamic>.from(c)))
          .toList();

      final rawMessages = (rawMap['messages'] as Map? ?? {});
      final messages = <String, List<PrivateMessageModel>>{};

      rawMessages.forEach((chatId, msgs) {
        if (msgs is List) {
          messages[chatId.toString()] = msgs
              .whereType<Map>()
              .map((m) => PrivateMessageModel.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      });

      return {
        'contacts': contacts,
        'messages': messages,
      };
    } catch (e) {
      debugPrint('Error importing chats from zip: $e');
      return null;
    }
  }

  /// Performs cloud auto-backup to Firebase Realtime Database.
  static Future<bool> performCloudAutoBackup({
    required String userId,
    required List<PrivateContactModel> contacts,
    required Map<String, List<PrivateMessageModel>> messages,
  }) async {
    try {
      final jsonString = createBackupJson(contacts: contacts, messages: messages);
      final ref = FirebaseDatabase.instance.ref('users/$userId/backups/latest');
      await ref.set({
        'updatedAt': DateTime.now().toIso8601String(),
        'backupData': jsonString,
      });
      debugPrint('Cloud auto-backup completed for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Firebase cloud auto-backup error: $e');
      return false;
    }
  }
}
