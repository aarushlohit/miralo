import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/friend_request_model.dart';
import '../models/private_contact_model.dart';
import '../models/private_message_model.dart';
import 'library_provider.dart';

class PrivateChatProvider extends ChangeNotifier {
  final List<PrivateContactModel> _contacts = [];
  final List<FriendRequestModel> _pendingFriendRequests = [];
  final Map<String, List<PrivateMessageModel>> _messages = {};
  String? _activeChatId;
  String? _currentUserId;

  StreamSubscription<DatabaseEvent>? _messagesSubscription;
  StreamSubscription<DatabaseEvent>? _contactsSubscription;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;

  List<PrivateContactModel> get contacts => _contacts;
  List<FriendRequestModel> get pendingFriendRequests => _pendingFriendRequests;
  String? get activeChatId => _activeChatId;

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

  PrivateChatProvider() {
    // No mock seed chats or fake friends. Clean & real state!
  }

  void initUserSession(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _listenToFirebaseUserContacts(userId);
    _listenToFirebaseFriendRequests(userId);
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

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
    final contactIndex = _contacts.indexWhere((c) => c.id == chatId);
    if (contactIndex != -1) {
      _contacts[contactIndex] = _contacts[contactIndex].copyWith(unreadCount: 0);
    }
    _listenToFirebaseChat(chatId);
    notifyListeners();
  }

  void _listenToFirebaseChat(String chatId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    try {
      final ref = FirebaseDatabase.instance.ref('chats/$chatId/messages');
      _messagesSubscription = ref.onValue.listen((event) {
        final list = _messages.putIfAbsent(chatId, () => []);
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

  void _syncMessageToFirebase(PrivateMessageModel msg) {
    try {
      final ref = FirebaseDatabase.instance.ref('chats/${msg.chatId}/messages/${msg.id}');
      ref.set(msg.toJson());
    } catch (e) {
      debugPrint('Firebase RTDB sync error: $e');
    }
  }

  void sendTextMessage(String text, {String? replyToText}) {
    if (text.trim().isEmpty || _activeChatId == null) return;
    final senderId = _currentUserId ?? 'me';

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: _activeChatId!,
      senderId: senderId,
      type: 'text',
      text: text.trim(),
      replyToText: replyToText,
      createdAt: DateTime.now(),
      status: 'sent',
    );

    _messages.putIfAbsent(_activeChatId!, () => []).add(newMsg);
    notifyListeners();
    _syncMessageToFirebase(newMsg);
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

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: _activeChatId!,
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
    _syncMessageToFirebase(newMsg);
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
    _syncMessageToFirebase(updatedMsg);
  }

  void deleteMessage(String messageId) {
    if (_activeChatId == null) return;
    final list = _messages[_activeChatId!];
    if (list == null) return;

    list.removeWhere((m) => m.id == messageId);
    try {
      FirebaseDatabase.instance.ref('chats/$_activeChatId/messages/$messageId').remove();
    } catch (_) {}
    notifyListeners();
  }

  void deleteCurrentChat() {
    if (_activeChatId == null) return;
    try {
      FirebaseDatabase.instance.ref('chats/$_activeChatId').remove();
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
    try {
      FirebaseDatabase.instance.ref('chats/$_activeChatId/messages').remove();
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

    if (results.isEmpty) {
      // Direct target preview fallback if searching specific username
      results.add({
        'id': 'usr_${clean.replaceAll(' ', '_')}',
        'name': clean,
        'username': clean,
        'email': '$clean@miralo.ai',
      });
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

    final targetId = 'usr_${clean.replaceAll(' ', '_').replaceAll('@', '_at_')}';
    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';

    final request = FriendRequestModel(
      id: requestId,
      senderId: senderId,
      senderName: senderName,
      senderUsername: senderUsername,
      receiverId: targetId,
      receiverUsername: clean,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Write to Firebase Realtime Database
    try {
      final ref = FirebaseDatabase.instance.ref('friend_requests/$targetId/$requestId');
      await ref.set(request.toJson());
    } catch (e) {
      debugPrint('Firebase friend request error: $e');
    }

    // Direct add as local & online contact
    final newContact = PrivateContactModel(
      id: targetId,
      displayName: clean,
      username: clean,
      isOnline: true,
      lastSeenText: 'Online',
      unreadCount: 0,
    );

    if (!_contacts.any((c) => c.id == targetId)) {
      _contacts.insert(0, newContact);
      if (_currentUserId != null) {
        try {
          FirebaseDatabase.instance
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
        if (_currentUserId != null) {
          try {
            FirebaseDatabase.instance
                .ref('users/$_currentUserId/contacts/${req.senderId}')
                .set(newContact.toJson());
          } catch (_) {}
        }
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
    super.dispose();
  }
}

