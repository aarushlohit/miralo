import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/private_contact_model.dart';
import '../models/private_message_model.dart';
import 'library_provider.dart';

class PrivateChatProvider extends ChangeNotifier {
  final List<PrivateContactModel> _contacts = [];
  final Map<String, List<PrivateMessageModel>> _messages = {};
  String? _activeChatId;
  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  List<PrivateContactModel> get contacts => _contacts;
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
    _seedContactsAndMessages();
  }

  void _seedContactsAndMessages() {
    final sarah = PrivateContactModel(
      id: 'contact_sarah',
      displayName: 'Sarah',
      username: 'sarah_m',
      isOnline: true,
      lastSeenText: 'Online',
      unreadCount: 0,
      isPinned: true,
    );

    final alex = PrivateContactModel(
      id: 'contact_alex',
      displayName: 'Alex',
      username: 'alex_k',
      isOnline: false,
      lastSeenText: '1h ago',
      unreadCount: 1,
      isPinned: false,
    );

    final emma = PrivateContactModel(
      id: 'contact_emma',
      displayName: 'Emma',
      username: 'emma_w',
      isOnline: false,
      lastSeenText: '3h ago',
      unreadCount: 0,
      isPinned: false,
    );

    final chris = PrivateContactModel(
      id: 'contact_chris',
      displayName: 'Chris',
      username: 'chris_t',
      isOnline: true,
      lastSeenText: 'Online',
      unreadCount: 0,
      isPinned: false,
    );

    _contacts.addAll([sarah, alex, emma, chris]);

    // Initial messages with Sarah matching Screen 10 of specification board
    _messages[sarah.id] = [
      PrivateMessageModel(
        id: 'msg_s_1',
        chatId: sarah.id,
        senderId: sarah.id,
        type: 'text',
        text: 'Hey! How was your day?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        status: 'read',
      ),
      PrivateMessageModel(
        id: 'msg_s_2',
        chatId: sarah.id,
        senderId: 'me',
        type: 'text',
        text: 'It was good! Just finished my project. You?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
        status: 'read',
      ),
      PrivateMessageModel(
        id: 'msg_s_3',
        chatId: sarah.id,
        senderId: sarah.id,
        type: 'text',
        text: "Nice! I'm at the library right now ❤️",
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        status: 'read',
      ),
      PrivateMessageModel(
        id: 'msg_s_4',
        chatId: sarah.id,
        senderId: 'me',
        type: 'image',
        text: 'This place is amazing!',
        mediaUrl: 'mock_sunset',
        reactions: {'❤️': 1},
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'read',
      ),
    ];

    // Alex's messages
    _messages[alex.id] = [
      PrivateMessageModel(
        id: 'msg_a_1',
        chatId: alex.id,
        senderId: alex.id,
        type: 'text',
        text: 'Did you review the project specifications?',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'delivered',
      ),
    ];

    // Emma's messages
    _messages[emma.id] = [
      PrivateMessageModel(
        id: 'msg_e_1',
        chatId: emma.id,
        senderId: emma.id,
        type: 'text',
        text: 'The presentation slides are saved in the Library.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'read',
      ),
    ];
  }

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
    // Mark as read
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
      _messagesSubscription = ref.onChildAdded.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
          final msg = PrivateMessageModel.fromJson(raw);
          final list = _messages.putIfAbsent(chatId, () => []);
          if (!list.any((m) => m.id == msg.id)) {
            list.add(msg);
            notifyListeners();
          }
        }
      }, onError: (e) {
        debugPrint('Firebase RTDB error: $e');
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

  void sendTextMessage(String text) {
    if (text.trim().isEmpty || _activeChatId == null) return;

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: _activeChatId!,
      senderId: 'me',
      type: 'text',
      text: text.trim(),
      createdAt: DateTime.now(),
      status: 'sent',
    );

    _messages.putIfAbsent(_activeChatId!, () => []).add(newMsg);
    notifyListeners();
    _syncMessageToFirebase(newMsg);

    // Auto simulated friendly reply after a short delay
    _simulateContactReply(_activeChatId!);
  }

  void sendMediaMessage({
    required String type, // 'image', 'gif', 'file'
    String? mediaUrl,
    String? imageBase64,
    String text = '',
    String? fileName,
    String? fileSize,
  }) {
    if (_activeChatId == null) return;

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: _activeChatId!,
      senderId: 'me',
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

    list[index] = msg.copyWith(reactions: reactions);
    notifyListeners();
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

  void addNewFriend(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final newContact = PrivateContactModel(
      id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      displayName: clean,
      username: clean.toLowerCase().replaceAll(' ', '_'),
      isOnline: true,
      lastSeenText: 'Just added',
      unreadCount: 0,
    );

    _contacts.insert(0, newContact);
    _messages[newContact.id] = [
      PrivateMessageModel(
        id: 'msg_welcome_${newContact.id}',
        chatId: newContact.id,
        senderId: newContact.id,
        type: 'text',
        text: 'Connected securely on MIRALO AI. Say hello!',
        createdAt: DateTime.now(),
        status: 'read',
      ),
    ];
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

  void _simulateContactReply(String chatId) {
    Future.delayed(const Duration(seconds: 2), () {
      if (_messages.containsKey(chatId)) {
        final reply = PrivateMessageModel(
          id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
          chatId: chatId,
          senderId: chatId,
          type: 'text',
          text: 'Got it! Sounds great 😊',
          createdAt: DateTime.now(),
          status: 'delivered',
        );
        _messages[chatId]!.add(reply);
        notifyListeners();
      }
    });
  }

  void updateContactDisplayName(String contactId, String newName) {
    final idx = _contacts.indexWhere((c) => c.id == contactId);
    if (idx != -1) {
      _contacts[idx] = _contacts[idx].copyWith(displayName: newName);
      notifyListeners();
    }
  }

  void emergencyWipeAllChats() {
    _messages.clear();
    _contacts.clear();
    _activeChatId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
