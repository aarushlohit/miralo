import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/friend_request_model.dart';
import '../models/private_contact_model.dart';
import '../models/private_message_model.dart';
import '../services/chat_backup_service.dart';
import 'library_provider.dart';

class PrivateChatProvider extends ChangeNotifier {
  final List<PrivateContactModel> _contacts = [];
  final List<FriendRequestModel> _pendingFriendRequests = [];
  final Map<String, List<PrivateMessageModel>> _messages = {};
  String? _activeChatId;
  String? _currentUserId;
  bool _isAutoBackupEnabled = true;

  // sent_requests: targetUsername -> status ('pending'|'accepted'|'rejected')
  final Map<String, String> _sentRequestStatuses = {};
  // blocked user IDs (Firebase UIDs)
  final Set<String> _blockedUserIds = {};

  StreamSubscription<DatabaseEvent>? _messagesSubscription;
  StreamSubscription<DatabaseEvent>? _contactsSubscription;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;
  StreamSubscription<DatabaseEvent>? _sentRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _blockedSubscription;

  List<PrivateContactModel> get contacts => _contacts;
  List<FriendRequestModel> get pendingFriendRequests => _pendingFriendRequests;
  String? get activeChatId => _activeChatId;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;
  Set<String> get blockedUserIds => _blockedUserIds;

  /// Returns null (not sent), 'pending', 'accepted', or 'rejected'
  String? getSentRequestStatus(String targetUsername) =>
      _sentRequestStatuses[targetUsername.toLowerCase().trim()];

  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  PrivateContactModel? get activeContact {
    if (_activeChatId == null) return null;
    try {
      return _contacts.firstWhere((c) => c.id == _activeChatId);
    } catch (_) {
      return null;
    }
  }

  List<PrivateMessageModel> get activeMessages {
    if (_activeChatId == null) return [];
    return _messages[_activeChatId] ?? [];
  }

  PrivateMessageModel? getLastMessageForContact(String contactId) {
    final list = _messages[contactId];
    if (list != null && list.isNotEmpty) {
      return list.last;
    }
    return null;
  }

  PrivateChatProvider() {
    // No mock seed chats or fake friends. Clean & real state!
  }

  void setAutoBackupEnabled(bool enabled) {
    _isAutoBackupEnabled = enabled;
    notifyListeners();
  }

  /// Triggers Cloud Auto-Backup to Firebase Realtime Database and Cloudinary
  Future<bool> triggerCloudAutoBackup() async {
    if (_currentUserId == null) return false;
    return await ChatBackupService.performCloudAutoBackup(
      userId: _currentUserId!,
      contacts: _contacts,
      messages: _messages,
    );
  }

  /// Exports all chats to a ZIP archive
  Future<Uint8List?> exportChatsToZip() async {
    final zipBytes = await ChatBackupService.exportChatsToZip(
      contacts: _contacts,
      messages: _messages,
    );
    if (_isAutoBackupEnabled && _currentUserId != null) {
      triggerCloudAutoBackup();
    }
    return zipBytes;
  }

  /// Prompts user to select a .zip backup file and restores chats & contacts
  Future<bool> importChatsFromZipFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final zipBytes = result.files.first.bytes!;
        final backupData = await ChatBackupService.importChatsFromZip(zipBytes);

        if (backupData != null) {
          final importedContacts = backupData['contacts'] as List<PrivateContactModel>? ?? [];
          final importedMessages = backupData['messages'] as Map<String, List<PrivateMessageModel>>? ?? {};

          // Merge imported contacts
          for (var c in importedContacts) {
            if (!_contacts.any((existing) => existing.id == c.id)) {
              _contacts.add(c);
            }
          }

          // Merge imported messages
          importedMessages.forEach((chatId, list) {
            final existingList = _messages.putIfAbsent(chatId, () => []);
            for (var m in list) {
              if (!existingList.any((existing) => existing.id == m.id)) {
                existingList.add(m);
              }
            }
            existingList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });

          notifyListeners();
          if (_currentUserId != null) {
            triggerCloudAutoBackup();
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error restoring backup from zip file: $e');
      return false;
    }
  }

  void initUserSession(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _listenToFirebaseUserContacts(userId);
    _listenToFirebaseFriendRequests(userId);
    _listenToFirebaseSentRequests(userId);
    _listenToFirebaseBlockedUsers(userId);
  }

  void _listenToFirebaseUserContacts(String userId) {
    _contactsSubscription?.cancel();
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId/contacts');
      _contactsSubscription = ref.onValue.listen((event) {
        _contacts.clear();
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          for (var entry in rawMap.entries) {
            if (entry.value is Map) {
              final contactJson = Map<String, dynamic>.from(entry.value as Map);
              _contacts.add(PrivateContactModel.fromJson(contactJson));
            }
          }
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firebase RTDB contacts error: $e');
      });
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  void _listenToFirebaseFriendRequests(String userId) {
    _requestsSubscription?.cancel();
    try {
      final ref = FirebaseDatabase.instance.ref('friend_requests/$userId');
      _requestsSubscription = ref.onValue.listen((event) {
        _pendingFriendRequests.clear();
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          for (var entry in rawMap.entries) {
            if (entry.value is Map) {
              final reqJson = Map<String, dynamic>.from(entry.value as Map);
              final req = FriendRequestModel.fromJson(reqJson);
              if (req.status == 'pending') {
                _pendingFriendRequests.add(req);
              }
            }
          }
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firebase RTDB friend requests error: $e');
      });
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  void _listenToFirebaseSentRequests(String userId) {
    _sentRequestsSubscription?.cancel();
    try {
      final ref = FirebaseDatabase.instance.ref('sent_requests/$userId');
      _sentRequestsSubscription = ref.onValue.listen((event) {
        _sentRequestStatuses.clear();
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          for (var entry in rawMap.entries) {
            if (entry.value is Map) {
              final data = Map<String, dynamic>.from(entry.value as Map);
              final targetUsername = data['targetUsername']?.toString() ?? entry.key;
              final status = data['status']?.toString() ?? 'pending';
              _sentRequestStatuses[targetUsername.toLowerCase().trim()] = status;
            }
          }
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firebase RTDB sent requests error: $e');
      });
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  void _listenToFirebaseBlockedUsers(String userId) {
    _blockedSubscription?.cancel();
    try {
      final ref = FirebaseDatabase.instance.ref('blocked_users/$userId');
      _blockedSubscription = ref.onValue.listen((event) {
        _blockedUserIds.clear();
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          _blockedUserIds.addAll(rawMap.keys);
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firebase RTDB blocked users error: $e');
      });
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  Future<void> blockUser({
    required String targetId,
    required String targetUsername,
    required String targetDisplayName,
  }) async {
    _blockedUserIds.add(targetId);
    notifyListeners();
    if (_currentUserId == null) return;
    try {
      await FirebaseDatabase.instance
          .ref('blocked_users/$_currentUserId/$targetId')
          .set({
        'userId': targetId,
        'username': targetUsername,
        'displayName': targetDisplayName,
        'blockedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firebase block user error: $e');
    }
  }

  Future<void> unblockUser(String targetId) async {
    _blockedUserIds.remove(targetId);
    notifyListeners();
    if (_currentUserId == null) return;
    try {
      await FirebaseDatabase.instance
          .ref('blocked_users/$_currentUserId/$targetId')
          .remove();
    } catch (e) {
      debugPrint('Firebase unblock user error: $e');
    }
  }

  String getConversationChannelId(String contactId) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return contactId;
    return _currentUserId!.compareTo(contactId) < 0
        ? 'chat_${_currentUserId}_$contactId'
        : 'chat_${contactId}_$_currentUserId';
  }

  bool isMyMessage(PrivateMessageModel msg) {
    if (msg.senderId == 'me') return true;
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return msg.senderId == _currentUserId;
    }
    return false;
  }

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
    final contactIndex = _contacts.indexWhere((c) => c.id == chatId);
    if (contactIndex != -1) {
      _contacts[contactIndex] = _contacts[contactIndex].copyWith(unreadCount: 0);
    }
    final channelId = getConversationChannelId(chatId);
    _listenToFirebaseChat(chatId, channelId);
    notifyListeners();
  }

  void _listenToFirebaseChat(String contactId, String channelId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    try {
      final ref = FirebaseDatabase.instance.ref('chats/$channelId/messages');
      _messagesSubscription = ref.onValue.listen((event) {
        final list = _messages.putIfAbsent(contactId, () => []);
        list.clear();
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          final msgs = rawMap.values
              .whereType<Map>()
              .map((val) => PrivateMessageModel.fromJson(Map<String, dynamic>.from(val)))
              .toList();
          msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          list.addAll(msgs);
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firebase RTDB chat error: $e');
      });
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  void _syncMessageToFirebase(PrivateMessageModel msg, String channelId) {
    try {
      final ref = FirebaseDatabase.instance.ref('chats/$channelId/messages/${msg.id}');
      ref.set(msg.toJson());
    } catch (e) {
      debugPrint('Firebase RTDB sync error: $e');
    }
  }

  void sendTextMessage(String text, {String? replyToText}) {
    if (text.trim().isEmpty || _activeChatId == null) return;
    final senderId = _currentUserId ?? 'me';
    final channelId = getConversationChannelId(_activeChatId!);

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: channelId,
      senderId: senderId,
      type: 'text',
      text: text.trim(),
      replyToText: replyToText,
      createdAt: DateTime.now(),
      status: 'sent',
    );

    _messages.putIfAbsent(_activeChatId!, () => []).add(newMsg);
    notifyListeners();
    _syncMessageToFirebase(newMsg, channelId);
  }

  void sendMediaMessage({
    required String type,
    String? mediaUrl,
    String? imageBase64,
    String text = '',
    String? fileName,
    String? fileSize,
  }) {
    if (_activeChatId == null) return;
    final senderId = _currentUserId ?? 'me';
    final channelId = getConversationChannelId(_activeChatId!);

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: channelId,
      senderId: senderId,
      type: type,
      text: text,
      mediaUrl: mediaUrl,
      imageBase64: imageBase64,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      status: 'sent',
    );

    _messages.putIfAbsent(_activeChatId!, () => []).add(newMsg);
    notifyListeners();
    _syncMessageToFirebase(newMsg, channelId);
  }

  void toggleReaction(String messageId, String emoji) {
    if (_activeChatId == null) return;
    final list = _messages[_activeChatId!];
    if (list == null) return;

    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final msg = list[index];
    final reactions = Map<String, int>.from(msg.reactions);

    if (reactions.containsKey(emoji)) {
      if (reactions[emoji]! <= 1) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = reactions[emoji]! - 1;
      }
    } else {
      reactions[emoji] = 1;
    }

    final updatedMsg = msg.copyWith(reactions: reactions);
    list[index] = updatedMsg;
    notifyListeners();
    final channelId = getConversationChannelId(_activeChatId!);
    _syncMessageToFirebase(updatedMsg, channelId);
  }

  void deleteMessage(String messageId) {
    if (_activeChatId == null) return;
    final list = _messages[_activeChatId!];
    if (list == null) return;

    list.removeWhere((m) => m.id == messageId);
    final channelId = getConversationChannelId(_activeChatId!);
    try {
      FirebaseDatabase.instance.ref('chats/$channelId/messages/$messageId').remove();
    } catch (_) {}
    notifyListeners();
  }

  void deleteCurrentChat() {
    if (_activeChatId == null) return;
    final channelId = getConversationChannelId(_activeChatId!);
    try {
      FirebaseDatabase.instance.ref('chats/$channelId').remove();
      if (_currentUserId != null) {
        FirebaseDatabase.instance.ref('users/$_currentUserId/contacts/$_activeChatId').remove();
      }
    } catch (_) {}
    _messages.remove(_activeChatId);
    _contacts.removeWhere((c) => c.id == _activeChatId);
    _activeChatId = null;
    notifyListeners();
  }

  void clearActiveChat() {
    if (_activeChatId == null) return;
    _messages[_activeChatId]?.clear();
    final channelId = getConversationChannelId(_activeChatId!);
    try {
      FirebaseDatabase.instance.ref('chats/$channelId/messages').remove();
    } catch (_) {}
    notifyListeners();
  }

  /// Real-time search users by username or email on Firebase
  Future<List<Map<String, String>>> searchUsersByQuery(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final results = <Map<String, String>>[];
    try {
      final snap = await FirebaseDatabase.instance.ref('users').get();
      if (snap.exists && snap.value is Map) {
        final rawMap = Map<String, dynamic>.from(snap.value as Map);
        for (var entry in rawMap.entries) {
          if (entry.value is Map) {
            final u = Map<String, dynamic>.from(entry.value as Map);
            final uname = (u['username'] ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            final name = (u['displayName'] ?? '').toString();
            final id = (u['id'] ?? entry.key).toString();

            if (uname.contains(clean) || email.contains(clean) || name.toLowerCase().contains(clean)) {
              results.add({
                'id': id,
                'name': name.isEmpty ? uname : name,
                'username': uname,
                'email': email,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Firebase search users error: $e');
    }


    return results;
  }

  /// Real Friend Request via Firebase Realtime Database
  Future<void> sendFriendRequest({
    required String senderId,
    required String senderName,
    required String senderUsername,
    required String targetUsernameOrEmail,
  }) async {
    final clean = targetUsernameOrEmail.trim().toLowerCase();
    if (clean.isEmpty) return;

    String targetId = clean;
    String targetDisplayName = clean;
    String targetUsername = clean;

    // Resolve real target user from user_index or email_index
    try {
      if (!clean.contains('@')) {
        final indexSnap = await FirebaseDatabase.instance.ref('user_index/$clean').get();
        if (indexSnap.exists && indexSnap.value is Map) {
          final data = Map<String, dynamic>.from(indexSnap.value as Map);
          targetId = data['id']?.toString() ?? targetId;
          targetDisplayName = data['displayName']?.toString() ?? targetDisplayName;
          targetUsername = data['username']?.toString() ?? targetUsername;
        }
      } else {
        final safeEmail = clean.replaceAll('.', '_').replaceAll('@', '_at_');
        final emailSnap = await FirebaseDatabase.instance.ref('email_index/$safeEmail').get();
        if (emailSnap.exists && emailSnap.value is Map) {
          final data = Map<String, dynamic>.from(emailSnap.value as Map);
          targetId = data['userId']?.toString() ?? data['id']?.toString() ?? targetId;
          targetUsername = data['username']?.toString() ?? targetUsername;
          targetDisplayName = data['displayName']?.toString() ?? targetDisplayName;
        }
      }
    } catch (e) {
      debugPrint('Error resolving target user for friend request: $e');
    }

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';

    final request = FriendRequestModel(
      id: requestId,
      senderId: senderId,
      senderName: senderName,
      senderUsername: senderUsername,
      receiverId: targetId,
      receiverUsername: targetUsername,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Write to Firebase Realtime Database under target user's real ID AND username
    try {
      await FirebaseDatabase.instance
          .ref('friend_requests/$targetId/$requestId')
          .set(request.toJson());
      if (targetUsername != targetId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$targetUsername/$requestId')
            .set(request.toJson());
      }
      // Also write to sender's sent_requests node so status persists on reopen
      if (_currentUserId != null) {
        await FirebaseDatabase.instance
            .ref('sent_requests/$_currentUserId/$requestId')
            .set({
          'requestId': requestId,
          'targetId': targetId,
          'targetUsername': targetUsername,
          'targetDisplayName': targetDisplayName,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firebase friend request error: $e');
    }

    // Update local status immediately (optimistic)
    _sentRequestStatuses[targetUsername.toLowerCase().trim()] = 'pending';

    // Direct add as local & online contact
    final newContact = PrivateContactModel(
      id: targetId,
      displayName: targetDisplayName,
      username: targetUsername,
      isOnline: true,
      lastSeenText: 'Online',
      unreadCount: 0,
    );

    if (!_contacts.any((c) => c.id == targetId)) {
      _contacts.insert(0, newContact);
      if (_currentUserId != null) {
        try {
          await FirebaseDatabase.instance
              .ref('users/$_currentUserId/contacts/$targetId')
              .set(newContact.toJson());
        } catch (_) {}
      }
    }

    notifyListeners();
  }

  Future<void> respondToFriendRequest(FriendRequestModel req, bool accept) async {
    final status = accept ? 'accepted' : 'rejected';
    try {
      await FirebaseDatabase.instance
          .ref('friend_requests/${req.receiverId}/${req.id}')
          .update({'status': status});
      if (req.receiverUsername != req.receiverId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/${req.receiverUsername}/${req.id}')
            .update({'status': status});
      }
      // Update status in the SENDER's sent_requests node so their UI updates
      await FirebaseDatabase.instance
          .ref('sent_requests/${req.senderId}/${req.id}')
          .update({'status': status});
    } catch (_) {}

    _pendingFriendRequests.removeWhere((r) => r.id == req.id);

    if (accept) {
      final newContact = PrivateContactModel(
        id: req.senderId,
        displayName: req.senderName,
        username: req.senderUsername,
        isOnline: true,
        lastSeenText: 'Online',
        unreadCount: 0,
      );
      if (!_contacts.any((c) => c.id == req.senderId)) {
        _contacts.insert(0, newContact);
      }
      if (_currentUserId != null) {
        try {
          // 1. Add sender to receiver's contacts
          await FirebaseDatabase.instance
              .ref('users/$_currentUserId/contacts/${req.senderId}')
              .set(newContact.toJson());

          // 2. Also add receiver to sender's contacts (try to fetch real display name)
          String receiverDisplayName = req.receiverUsername;
          try {
            final receiverSnap = await FirebaseDatabase.instance.ref('users/$_currentUserId').get();
            if (receiverSnap.exists && receiverSnap.value is Map) {
              final data = Map<String, dynamic>.from(receiverSnap.value as Map);
              receiverDisplayName = data['displayName']?.toString() ?? req.receiverUsername;
            }
          } catch (_) {}

          final receiverContact = PrivateContactModel(
            id: _currentUserId!,
            displayName: receiverDisplayName,
            username: req.receiverUsername,
            isOnline: true,
            lastSeenText: 'Online',
            unreadCount: 0,
          );
          await FirebaseDatabase.instance
              .ref('users/${req.senderId}/contacts/$_currentUserId')
              .set(receiverContact.toJson());
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  void saveMessageToLibrary(PrivateMessageModel msg, LibraryProvider library) {
    if (msg.type == 'image' || msg.type == 'gif') {
      library.uploadItem(
        name: 'Private_Media_${DateTime.now().millisecondsSinceEpoch}.jpg',
        type: 'image',
        size: msg.fileSize ?? '1.8 MB',
        mediaUrl: msg.mediaUrl,
        folderId: 'folder_images',
      );
    } else {
      library.uploadItem(
        name: 'Saved_Note_${DateTime.now().millisecondsSinceEpoch}.txt',
        type: 'document',
        size: '12 KB',
        folderId: 'folder_docs',
      );
    }
  }

  void moveMessageToPrivateVault(PrivateMessageModel msg, LibraryProvider library) {
    saveMessageToLibrary(msg, library);
    deleteMessage(msg.id);
  }

  void updateContactDisplayName(String contactId, String newName) {
    final idx = _contacts.indexWhere((c) => c.id == contactId);
    if (idx != -1) {
      _contacts[idx] = _contacts[idx].copyWith(displayName: newName);
      if (_currentUserId != null) {
        try {
          FirebaseDatabase.instance
              .ref('users/$_currentUserId/contacts/$contactId')
              .update({'displayName': newName});
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void emergencyWipeAllChats() {
    _messages.clear();
    _contacts.clear();
    _pendingFriendRequests.clear();
    _activeChatId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _contactsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _sentRequestsSubscription?.cancel();
    _blockedSubscription?.cancel();
    super.dispose();
  }
}

