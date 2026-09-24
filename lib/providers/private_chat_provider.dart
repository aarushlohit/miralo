import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend_request_model.dart';
import '../models/private_contact_model.dart';
import '../models/private_message_model.dart';
import '../services/chat_backup_service.dart';
import '../services/encryption_service.dart';
import 'library_provider.dart';

class PrivateChatProvider extends ChangeNotifier {
  final List<PrivateContactModel> _contacts = [];
  final List<FriendRequestModel> _pendingFriendRequests = [];
  final Map<String, List<PrivateMessageModel>> _messages = {};
  String? _activeChatId;
  String? _currentUserId;
  bool _isAutoBackupEnabled = true;

  // Privacy settings
  bool _showOnlineStatus = true;
  bool get showOnlineStatus => _showOnlineStatus;
  bool _showLastSeen = true;
  bool get showLastSeen => _showLastSeen;
  bool _sendReadReceipts = true;
  bool get sendReadReceipts => _sendReadReceipts;

  // sent_requests: targetUsername -> status ('pending'|'accepted'|'rejected')
  final Map<String, String> _sentRequestStatuses = {};
  // blocked user IDs (Firebase UIDs)
  final Set<String> _blockedUserIds = {};

  StreamSubscription<DatabaseEvent>? _messagesSubscription;
  StreamSubscription<DatabaseEvent>? _contactsSubscription;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;
  StreamSubscription<DatabaseEvent>? _usernameRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _emailRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _sentRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _blockedSubscription;
  StreamSubscription<DatabaseEvent>? _recentChatsSubscription;
  StreamSubscription<DatabaseEvent>? _infoConnectedSubscription;
  final Map<String, StreamSubscription<DatabaseEvent>> _contactPresenceSubs = {};

  String? _currentUsername;
  String? get currentUsername => _currentUsername;
  String? _currentUserEmail;
  String? get currentUserEmail => _currentUserEmail;
  String? _currentDisplayName;
  String? get currentDisplayName => _currentDisplayName;

  static String sanitizeDbKey(String key) {
    return key
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll(r'$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_')
        .replaceAll('@', '_at_')
        .trim()
        .toLowerCase();
  }

  final Map<String, PrivateContactModel> _tempContacts = {};


  List<PrivateContactModel> get contacts => _contacts;

  /// Combined list of all DM conversations (accepted friends + active non-friend DMs), sorted by latest message
  List<PrivateContactModel> get allConversations {
    final Map<String, PrivateContactModel> map = {};
    for (var c in _contacts) {
      map[c.id] = c;
    }
    for (var temp in _tempContacts.values) {
      if (!map.containsKey(temp.id)) {
        map[temp.id] = temp;
      }
    }
    for (var chatId in _messages.keys) {
      if (!map.containsKey(chatId)) {
        map[chatId] = PrivateContactModel(
          id: chatId,
          displayName: chatId.startsWith('usr_') ? chatId.replaceFirst('usr_', '@') : chatId,
          username: chatId,
          isOnline: false,
          unreadCount: 0,
        );
      }
    }

    final curId = (_currentUserId ?? '').toLowerCase().trim();
    final curUname = (_currentUsername ?? '').toLowerCase().trim();

    final list = map.values.where((c) {
      final cleanId = c.id.toLowerCase().trim();
      final cleanUname = c.username.toLowerCase().trim();
      if (curId.isNotEmpty && cleanId == curId) return false;
      if (curUname.isNotEmpty && (cleanUname == curUname || cleanId == curUname)) return false;
      return true;
    }).map((c) => c.copyWith(unreadCount: getUnreadCount(c.id))).toList();

    list.sort((a, b) {
      final lastA = getLastMessageForContact(a.id)?.createdAt;
      final lastB = getLastMessageForContact(b.id)?.createdAt;
      if (lastA == null && lastB == null) return 0;
      if (lastA == null) return 1;
      if (lastB == null) return -1;
      return lastB.compareTo(lastA);
    });
    return list;
  }

  /// Returns unread message count for a specific contact
  int getUnreadCount(String contactId) {
    final msgs = _messages[contactId] ?? [];
    return msgs.where((m) => !isMyMessage(m) && m.status != 'seen').length;
  }

  /// Total unread private messages across all conversations
  int get totalUnreadCount {
    int total = 0;
    for (final entry in _messages.entries) {
      total += entry.value.where((m) => !isMyMessage(m) && m.status != 'seen').length;
    }
    return total;
  }

  /// Marks all incoming messages from this contact as 'seen'
  void markMessagesAsSeen(String contactId) {
    if (!_sendReadReceipts) return;
    final msgs = _messages[contactId];
    if (msgs == null || msgs.isEmpty) return;
    final channelId = getConversationChannelId(contactId);
    bool changed = false;
    for (int i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      if (!isMyMessage(m) && m.status != 'seen') {
        msgs[i] = m.copyWith(status: 'seen');
        changed = true;
        try {
          FirebaseDatabase.instance
              .ref('chats/$channelId/messages/${m.id}/status')
              .set('seen');
        } catch (_) {}
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  List<FriendRequestModel> get pendingFriendRequests => _pendingFriendRequests;
  String? get activeChatId => _activeChatId;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;
  Set<String> get blockedUserIds => _blockedUserIds;

  /// Returns null (not sent), 'pending', 'accepted', or 'rejected'
  String? getSentRequestStatus(String target) {
    final clean = target.toLowerCase().trim();
    return _sentRequestStatuses[clean];
  }

  /// Checks whether a target ID or username is already in contacts
  bool isContact(String targetId, String targetUsername) {
    final cleanId = targetId.toLowerCase().trim();
    final cleanUsername = targetUsername.toLowerCase().trim();
    return _contacts.any((c) =>
        c.id.toLowerCase().trim() == cleanId ||
        c.username.toLowerCase().trim() == cleanUsername ||
        c.id.toLowerCase().trim() == cleanUsername);
  }

  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  PrivateContactModel? get activeContact {
    if (_activeChatId == null) return null;
    try {
      return _contacts.firstWhere((c) => c.id == _activeChatId);
    } catch (_) {
      return _tempContacts[_activeChatId];
    }
  }

  List<PrivateMessageModel> get activeMessages {
    if (_activeChatId == null) return [];
    return _messages[_activeChatId] ?? [];
  }

  /// Returns all images from all conversations, newest first (excluding GIFs)
  List<PrivateMessageModel> get allChatImages {
    final List<PrivateMessageModel> images = [];
    for (var list in _messages.values) {
      for (var msg in list) {
        if (msg.isGif) {
          // GIFs are NOT stored or shown in chat images automatically
          continue;
        }
        final isImage = msg.type == 'image' ||
            (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty) ||
            (msg.mediaUrl != null &&
                msg.mediaUrl!.isNotEmpty &&
                (msg.mediaUrl!.contains('/image/') ||
                    msg.fileName?.toLowerCase().endsWith('.jpg') == true ||
                    msg.fileName?.toLowerCase().endsWith('.png') == true ||
                    msg.fileName?.toLowerCase().endsWith('.jpeg') == true ||
                    msg.fileName?.toLowerCase().endsWith('.webp') == true));
        if (isImage) {
          if (!images.any((existing) => existing.id == msg.id)) {
            images.add(msg);
          }
        }
      }
    }
    images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return images;
  }

  List<PrivateMessageModel> _savedFavoriteGifs = [];
  static const String _favoriteGifsPrefsKey = 'saved_favorite_gifs_list';

  /// Returns all favorited GIFs from conversations and saved favorites
  List<PrivateMessageModel> get favoriteGifs {
    final List<PrivateMessageModel> gifs = [];
    for (var list in _messages.values) {
      for (var msg in list) {
        if (msg.isGif && msg.isFavorite) {
          if (!gifs.any((existing) => existing.id == msg.id || (existing.mediaUrl != null && existing.mediaUrl == msg.mediaUrl))) {
            gifs.add(msg);
          }
        }
      }
    }
    for (var saved in _savedFavoriteGifs) {
      if (!gifs.any((existing) => existing.id == saved.id || (existing.mediaUrl != null && existing.mediaUrl == saved.mediaUrl))) {
        gifs.add(saved);
      }
    }
    gifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return gifs;
  }

  bool isMessageFavorite(String messageId) {
    for (var list in _messages.values) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) return list[idx].isFavorite;
    }
    return _savedFavoriteGifs.any((m) => m.id == messageId);
  }

  Future<void> toggleFavoriteMessage(PrivateMessageModel msg) async {
    final newFav = !msg.isFavorite;

    // Update in memory messages
    for (var list in _messages.values) {
      final idx = list.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isFavorite: newFav);
      }
    }

    if (newFav) {
      if (!_savedFavoriteGifs.any((m) => m.id == msg.id || (m.mediaUrl != null && m.mediaUrl == msg.mediaUrl))) {
        _savedFavoriteGifs.insert(0, msg.copyWith(isFavorite: true));
      }
    } else {
      _savedFavoriteGifs.removeWhere((m) => m.id == msg.id || (m.mediaUrl != null && m.mediaUrl == msg.mediaUrl));
    }

    await _persistFavoriteGifs();
    notifyListeners();
  }

  Future<void> removeFavoriteGif(String idOrUrl) async {
    for (var list in _messages.values) {
      final idx = list.indexWhere((m) => m.id == idOrUrl || m.mediaUrl == idOrUrl);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isFavorite: false);
      }
    }
    _savedFavoriteGifs.removeWhere((m) => m.id == idOrUrl || m.mediaUrl == idOrUrl);
    await _persistFavoriteGifs();
    notifyListeners();
  }

  List<PrivateMessageModel> searchFavoriteGifs(String query) {
    final all = favoriteGifs;
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((g) {
      final name = (g.fileName ?? '').toLowerCase();
      final text = g.text.toLowerCase();
      final sender = (g.senderName ?? '').toLowerCase();
      return name.contains(q) || text.contains(q) || sender.contains(q);
    }).toList();
  }

  Future<void> _loadFavoriteGifs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_favoriteGifsPrefsKey);
      if (raw != null) {
        _savedFavoriteGifs = raw
            .map((str) => PrivateMessageModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistFavoriteGifs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _savedFavoriteGifs.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_favoriteGifsPrefsKey, raw);
    } catch (_) {}
  }

  /// Maximum number of messages that can be pinned per conversation (like WhatsApp).
  static const int maxPinnedMessages = 6;

  /// Returns all pinned messages for a specific chat or the active chat.
  List<PrivateMessageModel> getPinnedMessages([String? chatId]) {
    final targetId = chatId ?? _activeChatId;
    if (targetId == null) return [];
    final list = _messages[targetId] ?? [];
    final pinned = list.where((m) => m.isPinned).toList();
    // Sort so newest pinned message is first
    pinned.sort((a, b) {
      final timeA = a.pinnedAt ?? a.createdAt;
      final timeB = b.pinnedAt ?? b.createdAt;
      return timeB.compareTo(timeA);
    });
    return pinned;
  }

  /// Returns the number of pinned messages in the chat.
  int getPinnedMessageCount([String? chatId]) {
    final targetId = chatId ?? _activeChatId;
    if (targetId == null) return 0;
    return (_messages[targetId] ?? []).where((m) => m.isPinned).length;
  }

  /// Returns true if the message is currently pinned.
  bool isMessagePinned(String messageId) {
    for (var list in _messages.values) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) return list[idx].isPinned;
    }
    return false;
  }

  /// Toggles the pinned status of a message.
  /// Returns `true` if pin/unpin was executed, or `false` if max limit (6) was exceeded.
  Future<bool> togglePinMessage(PrivateMessageModel msg) async {
    final targetChatId = _activeChatId ?? msg.chatId;
    final list = _messages[targetChatId] ?? _messages.values.firstWhere(
      (l) => l.any((m) => m.id == msg.id),
      orElse: () => [],
    );

    final idx = list.indexWhere((m) => m.id == msg.id);
    final currentlyPinned = idx != -1 ? list[idx].isPinned : msg.isPinned;

    if (!currentlyPinned) {
      // Check current pinned count
      final currentPinnedCount = list.where((m) => m.isPinned).length;
      if (currentPinnedCount >= maxPinnedMessages) {
        return false; // Limit reached!
      }
    }

    final newPinned = !currentlyPinned;
    final updatedMsg = (idx != -1 ? list[idx] : msg).copyWith(
      isPinned: newPinned,
      pinnedAt: newPinned ? DateTime.now() : null,
    );

    if (idx != -1) {
      list[idx] = updatedMsg;
    } else if (targetChatId.isNotEmpty) {
      _messages.putIfAbsent(targetChatId, () => []).add(updatedMsg);
    }

    notifyListeners();

    final channelId = getConversationChannelId(targetChatId.isNotEmpty ? targetChatId : msg.chatId);
    _syncMessageToFirebase(updatedMsg, channelId);
    return true;
  }

  /// Unpins a specific message by its ID.
  Future<void> unpinMessage(String messageId) async {
    for (var entry in _messages.entries) {
      final list = entry.value;
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1 && list[idx].isPinned) {
        final updatedMsg = list[idx].copyWith(isPinned: false, pinnedAt: null);
        list[idx] = updatedMsg;
        notifyListeners();
        final channelId = getConversationChannelId(entry.key);
        _syncMessageToFirebase(updatedMsg, channelId);
        break;
      }
    }
  }

  /// Unpins all pinned messages in a conversation.
  Future<void> clearAllPinnedMessages(String chatId) async {
    final list = _messages[chatId];
    if (list == null || list.isEmpty) return;
    bool changed = false;
    final channelId = getConversationChannelId(chatId);
    for (int i = 0; i < list.length; i++) {
      if (list[i].isPinned) {
        final updated = list[i].copyWith(isPinned: false, pinnedAt: null);
        list[i] = updated;
        changed = true;
        _syncMessageToFirebase(updated, channelId);
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  PrivateMessageModel? getLastMessageForContact(String contactId) {
    final list = _messages[contactId];
    if (list != null && list.isNotEmpty) {
      return list.last;
    }
    return null;
  }

  PrivateChatProvider() {
    _loadPrivacySettings();
    _loadFavoriteGifs();
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

  void initUserSession(String userId, {String? username, String? email, String? displayName}) {
    final cleanUserId = sanitizeDbKey(userId);
    final cleanUsername = username != null && username.isNotEmpty ? sanitizeDbKey(username) : null;
    final cleanEmail = email != null && email.isNotEmpty ? sanitizeDbKey(email) : null;

    if (_currentUserId == cleanUserId && _currentUsername == cleanUsername && _requestsSubscription != null) {
      if (displayName != null) _currentDisplayName = displayName;
      return;
    }
    // Clear ALL stale session data before switching to new user
    _clearAllSubscriptions();
    _contacts.clear();
    _tempContacts.clear();
    _messages.clear();
    _pendingFriendRequests.clear();
    _sentRequestStatuses.clear();
    _blockedUserIds.clear();
    _activeChatId = null;
    _currentUserId = cleanUserId;
    _currentUsername = cleanUsername;
    _currentUserEmail = cleanEmail;
    _currentDisplayName = displayName;

    _loadPrivacySettings();
    _initPresenceSystem(cleanUserId);

    _listenToFirebaseUserContacts(userId);
    _listenToFirebaseRecentChats(userId);
    _listenToFirebaseFriendRequests(userId, username: username, email: email);
    _listenToFirebaseSentRequests(userId);
    _listenToFirebaseBlockedUsers(userId);
    notifyListeners();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showOnlineStatus = prefs.getBool('privacy_online_status') ?? true;
      _showLastSeen = prefs.getBool('privacy_last_seen') ?? true;
      _sendReadReceipts = prefs.getBool('privacy_read_receipts') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updatePrivacySettings({
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? sendReadReceipts,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (showOnlineStatus != null) {
        _showOnlineStatus = showOnlineStatus;
        await prefs.setBool('privacy_online_status', showOnlineStatus);
      }
      if (showLastSeen != null) {
        _showLastSeen = showLastSeen;
        await prefs.setBool('privacy_last_seen', showLastSeen);
      }
      if (sendReadReceipts != null) {
        _sendReadReceipts = sendReadReceipts;
        await prefs.setBool('privacy_read_receipts', sendReadReceipts);
      }
      if (_currentUserId != null) {
        _syncMyPresence();
      }
      notifyListeners();
    } catch (_) {}
  }

  void _initPresenceSystem(String userId) {
    _infoConnectedSubscription?.cancel();
    try {
      _infoConnectedSubscription = FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        if (connected && _currentUserId != null) {
          _syncMyPresence();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  void _syncMyPresence() {
    if (_currentUserId == null) return;
    try {
      final presenceRef = FirebaseDatabase.instance.ref('users/$_currentUserId/presence');
      presenceRef.onDisconnect().set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
      presenceRef.set({
        'isOnline': _showOnlineStatus,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  void _subscribeToContactPresence(String contactId) {
    if (_contactPresenceSubs.containsKey(contactId)) return;
    try {
      final ref = FirebaseDatabase.instance.ref('users/$contactId/presence');
      _contactPresenceSubs[contactId] = ref.onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final isOnline = data['isOnline'] == true;
          final lastSeenRaw = data['lastSeen'];
          int? lastSeenMs;
          if (lastSeenRaw is num) {
            lastSeenMs = lastSeenRaw.toInt();
          }

          String lastSeenStr = 'Active recently';
          if (isOnline) {
            lastSeenStr = 'Online';
          } else if (lastSeenMs != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
            final now = DateTime.now();
            final diff = now.difference(dt);
            if (diff.inMinutes < 2) {
              lastSeenStr = 'Last seen just now';
            } else if (diff.inHours < 1) {
              lastSeenStr = 'Last seen ${diff.inMinutes}m ago';
            } else if (diff.inDays == 0 && now.day == dt.day) {
              final h = dt.hour.toString().padLeft(2, '0');
              final m = dt.minute.toString().padLeft(2, '0');
              lastSeenStr = 'Last seen today at $h:$m';
            } else {
              lastSeenStr = 'Last seen recently';
            }
          }

          final contactIdx = _contacts.indexWhere((c) => c.id == contactId);
          if (contactIdx != -1) {
            _contacts[contactIdx] = _contacts[contactIdx].copyWith(
              isOnline: isOnline,
              lastSeenText: lastSeenStr,
            );
          }
          if (_tempContacts.containsKey(contactId)) {
            _tempContacts[contactId] = _tempContacts[contactId]!.copyWith(
              isOnline: isOnline,
              lastSeenText: lastSeenStr,
            );
          }
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  /// Called on logout — cancels all Firebase subscriptions and clears all state.
  void clearSession() {
    _clearAllSubscriptions();
    _contacts.clear();
    _tempContacts.clear();
    _messages.clear();
    _pendingFriendRequests.clear();
    _sentRequestStatuses.clear();
    _blockedUserIds.clear();
    _activeChatId = null;
    _currentUserId = null;
    _currentUsername = null;
    _currentUserEmail = null;
    _currentDisplayName = null;
    notifyListeners();
  }

  void _clearAllSubscriptions() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _contactsSubscription?.cancel();
    _contactsSubscription = null;
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _usernameRequestsSubscription?.cancel();
    _usernameRequestsSubscription = null;
    _emailRequestsSubscription?.cancel();
    _emailRequestsSubscription = null;
    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription = null;
    _blockedSubscription?.cancel();
    _blockedSubscription = null;
    _recentChatsSubscription?.cancel();
    _recentChatsSubscription = null;
    _infoConnectedSubscription?.cancel();
    _infoConnectedSubscription = null;
    for (final sub in _contactPresenceSubs.values) {
      sub.cancel();
    }
    _contactPresenceSubs.clear();
    for (final sub in _channelSubscriptions.values) {
      sub.cancel();
    }
    _channelSubscriptions.clear();
  }

  void _listenToFirebaseRecentChats(String userId) {
    _recentChatsSubscription?.cancel();
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId/recent_chats');
      _recentChatsSubscription = ref.onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          for (var entry in rawMap.entries) {
            final otherUserId = entry.key;
            final curId = (_currentUserId ?? '').toLowerCase().trim();
            final curUname = (_currentUsername ?? '').toLowerCase().trim();
            if (otherUserId.toLowerCase().trim() == curId || otherUserId.toLowerCase().trim() == curUname) {
              continue;
            }

            if (entry.value is Map) {
              final data = Map<String, dynamic>.from(entry.value as Map);
              final senderName = data['senderName']?.toString() ?? 'User';
              final senderUsername = data['senderUsername']?.toString() ?? 'user';
              if (senderUsername.toLowerCase().trim() == curUname) continue;

              if (!_contacts.any((c) => c.id == otherUserId) && !_tempContacts.containsKey(otherUserId)) {
                _tempContacts[otherUserId] = PrivateContactModel(
                  id: otherUserId,
                  displayName: senderName,
                  username: senderUsername,
                  isOnline: false,
                  lastSeenText: 'Active recently',
                  unreadCount: 0,
                );
              }
            }
            _subscribeToContactChat(otherUserId);
            _subscribeToContactPresence(otherUserId);
          }
        }
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  final Map<String, StreamSubscription<DatabaseEvent>> _channelSubscriptions = {};

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
              final contact = PrivateContactModel.fromJson(contactJson);
              final curId = (_currentUserId ?? '').toLowerCase().trim();
              final curUname = (_currentUsername ?? '').toLowerCase().trim();
              if (contact.id.toLowerCase().trim() == curId || contact.username.toLowerCase().trim() == curUname) {
                continue;
              }
              _contacts.add(contact);
              _subscribeToContactChat(contact.id);
              _subscribeToContactPresence(contact.id);
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

  PrivateMessageModel _parseAndDecryptMessage(Map<String, dynamic> rawJson, String channelId) {
    final msg = PrivateMessageModel.fromJson(rawJson);
    final decryptedText = EncryptionService.decryptText(msg.text, channelId);
    final decryptedReply = msg.replyToText != null && msg.replyToText!.isNotEmpty
        ? EncryptionService.decryptText(msg.replyToText!, channelId)
        : msg.replyToText;
    return msg.copyWith(
      text: decryptedText,
      replyToText: decryptedReply,
    );
  }

  void _subscribeToContactChat(String contactId) {
    final channelId = getConversationChannelId(contactId);
    if (_channelSubscriptions.containsKey(channelId)) return;
    try {
      final ref = FirebaseDatabase.instance.ref('chats/$channelId/messages');
      _channelSubscriptions[channelId] = ref.onValue.listen((event) {
        final list = _messages.putIfAbsent(contactId, () => []);
        list.clear();
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          final msgs = rawMap.values
              .whereType<Map>()
              .map((val) => _parseAndDecryptMessage(Map<String, dynamic>.from(val), channelId))
              .toList();
          msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          list.addAll(msgs);
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firebase channel subscription error: $e');
      });
    } catch (e) {
      debugPrint('Firebase channel listener error: $e');
    }
  }

  void _listenToFirebaseFriendRequests(String userId, {String? username, String? email}) {
    _requestsSubscription?.cancel();
    _usernameRequestsSubscription?.cancel();
    _emailRequestsSubscription?.cancel();

    final safeUserId = sanitizeDbKey(userId);
    try {
      final ref = FirebaseDatabase.instance.ref('friend_requests/$safeUserId');
      _requestsSubscription = ref.onValue.listen((event) {
        _handleFriendRequestsSnapshot(event.snapshot);
      }, onError: (e) {
        debugPrint('Firebase RTDB friend requests error: $e');
      });

      if (username != null && username.isNotEmpty) {
        final safeUname = sanitizeDbKey(username);
        if (safeUname != safeUserId) {
          final uRef = FirebaseDatabase.instance.ref('friend_requests/$safeUname');
          _usernameRequestsSubscription = uRef.onValue.listen((event) {
            _handleFriendRequestsSnapshot(event.snapshot);
          }, onError: (_) {});
        }
      }

      if (email != null && email.isNotEmpty) {
        final safeEmail = sanitizeDbKey(email);
        if (safeEmail != safeUserId) {
          final eRef = FirebaseDatabase.instance.ref('friend_requests/$safeEmail');
          _emailRequestsSubscription = eRef.onValue.listen((event) {
            _handleFriendRequestsSnapshot(event.snapshot);
          }, onError: (_) {});
        }
      }
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  void _handleFriendRequestsSnapshot(DataSnapshot snapshot) {
    if (snapshot.value != null && snapshot.value is Map) {
      final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in rawMap.entries) {
        if (entry.value is Map) {
          final reqJson = Map<String, dynamic>.from(entry.value as Map);
          final req = FriendRequestModel.fromJson(reqJson);
          if (req.status == 'pending') {
            final idx = _pendingFriendRequests.indexWhere((r) => r.id == req.id);
            if (idx == -1) {
              _pendingFriendRequests.add(req);
            } else {
              _pendingFriendRequests[idx] = req;
            }
          } else {
            _pendingFriendRequests.removeWhere((r) => r.id == req.id);
          }
        }
      }
    }
    notifyListeners();
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
              final targetUsername = data['targetUsername']?.toString();
              final targetId = data['targetId']?.toString();
              final status = data['status']?.toString() ?? 'pending';
              if (targetUsername != null && targetUsername.isNotEmpty) {
                _sentRequestStatuses[targetUsername.toLowerCase().trim()] = status;
              }
              if (targetId != null && targetId.isNotEmpty) {
                _sentRequestStatuses[targetId.toLowerCase().trim()] = status;
              }
              // Also index entry key if relevant
              _sentRequestStatuses[entry.key.toLowerCase().trim()] = status;
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

  Future<bool> blockUser({
    required String targetId,
    required String targetUsername,
    required String targetDisplayName,
    String? currentUsername,
  }) async {
    final cur = (currentUsername ?? _currentUsername ?? '').toLowerCase().trim();
    final target = targetUsername.toLowerCase().trim();
    if ((cur == 'ashlinmirsha' && target == 'aarushlohit') ||
        (cur == 'aarushlohit' && target == 'ashlinmirsha')) {
      return false;
    }

    _blockedUserIds.add(targetId);
    notifyListeners();
    if (_currentUserId == null) return true;
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
    return true;
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
    if (contactId.startsWith('group_')) {
      return contactId;
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) return contactId;
    return _currentUserId!.compareTo(contactId) < 0
        ? 'chat_${_currentUserId}_$contactId'
        : 'chat_${contactId}_$_currentUserId';
  }

  bool isMyMessage(PrivateMessageModel msg) {
    if (msg.senderId == 'me') return true;
    final cleanSender = sanitizeDbKey(msg.senderId).toLowerCase().trim();
    final curId = (_currentUserId ?? '').toLowerCase().trim();
    final curUname = (_currentUsername ?? '').toLowerCase().trim();
    final curEmail = (_currentUserEmail ?? '').toLowerCase().trim();
    return (curId.isNotEmpty && cleanSender == curId) ||
           (curUname.isNotEmpty && cleanSender == curUname) ||
           (curEmail.isNotEmpty && cleanSender == curEmail);
  }

  void setActiveChat(String chatId, {String? displayName, String? username}) {
    final cleanChatId = sanitizeDbKey(chatId).toLowerCase().trim();
    final cleanUname = username != null ? sanitizeDbKey(username).toLowerCase().trim() : '';
    final curId = (_currentUserId ?? '').toLowerCase().trim();
    final curUname = (_currentUsername ?? '').toLowerCase().trim();
    if ((curId.isNotEmpty && cleanChatId == curId) ||
        (curUname.isNotEmpty && cleanChatId == curUname) ||
        (curUname.isNotEmpty && cleanUname == curUname)) {
      debugPrint('Prohibited: Cannot initiate chat with oneself.');
      return;
    }

    _activeChatId = chatId;
    final contactIndex = _contacts.indexWhere((c) => c.id == chatId);
    if (contactIndex != -1) {
      _contacts[contactIndex] = _contacts[contactIndex].copyWith(unreadCount: 0);
    } else if (displayName != null || username != null) {
      _tempContacts[chatId] = PrivateContactModel(
        id: chatId,
        displayName: displayName ?? username ?? 'User',
        username: username ?? 'user',
        isOnline: false,
        lastSeenText: 'Active recently',
        unreadCount: 0,
      );
    } else {
      _fetchUserForChatIfMissing(chatId);
    }
    final channelId = getConversationChannelId(chatId);
    _listenToFirebaseChat(chatId, channelId);
    _subscribeToContactPresence(chatId);
    markMessagesAsSeen(chatId);
    notifyListeners();
  }

  Future<void> _fetchUserForChatIfMissing(String chatId) async {
    if (_contacts.any((c) => c.id == chatId) || _tempContacts.containsKey(chatId)) return;
    try {
      final snap = await FirebaseDatabase.instance.ref('users/$chatId').get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        _tempContacts[chatId] = PrivateContactModel(
          id: chatId,
          displayName: data['displayName']?.toString() ?? data['username']?.toString() ?? 'User',
          username: data['username']?.toString() ?? 'user',
          isOnline: false,
          lastSeenText: 'Active recently',
          unreadCount: 0,
        );
        _subscribeToContactPresence(chatId);
        notifyListeners();
      }
    } catch (_) {}
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
              .map((val) => _parseAndDecryptMessage(Map<String, dynamic>.from(val), channelId))
              .toList();
          msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          list.addAll(msgs);
        }
        if (_activeChatId == contactId) {
          markMessagesAsSeen(contactId);
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
      // Encrypt message text and replyToText with End-to-End Encryption (E2EE) before storing in Firebase
      final encryptedText = EncryptionService.encryptText(msg.text, channelId);
      final encryptedReply = msg.replyToText != null && msg.replyToText!.isNotEmpty
          ? EncryptionService.encryptText(msg.replyToText!, channelId)
          : msg.replyToText;

      final encryptedMsg = msg.copyWith(
        text: encryptedText,
        replyToText: encryptedReply,
      );

      final ref = FirebaseDatabase.instance.ref('chats/$channelId/messages/${msg.id}');
      ref.set(encryptedMsg.toJson());

      if (_activeChatId != null && _currentUserId != null) {
        final myName = _currentDisplayName ?? _currentUsername ?? 'User';
        final myUname = _currentUsername ?? 'user';
        final contactName = activeContact?.displayName ?? activeContact?.username ?? 'User';
        final contactUname = activeContact?.username ?? 'user';

        final lastText = msg.type == 'image'
            ? '📷 Photo'
            : (msg.type == 'voice' ? '🎤 Voice note' : (msg.type == 'file' ? '📎 Document' : msg.text));
        final nowIso = DateTime.now().toIso8601String();

        // 1. Data for the recipient: shows ME as their contact
        final dataForRecipient = {
          'lastMessage': lastText,
          'timestamp': nowIso,
          'senderId': _currentUserId,
          'senderName': myName,
          'senderUsername': myUname,
        };
        FirebaseDatabase.instance.ref('users/$_activeChatId/recent_chats/$_currentUserId').set(dataForRecipient);

        // 2. Data for ME: shows the other user (activeContact) as my contact
        final dataForSender = {
          'lastMessage': lastText,
          'timestamp': nowIso,
          'senderId': _activeChatId,
          'senderName': contactName,
          'senderUsername': contactUname,
        };
        FirebaseDatabase.instance.ref('users/$_currentUserId/recent_chats/$_activeChatId').set(dataForSender);
      }
    } catch (e) {
      debugPrint('Firebase RTDB sync error: $e');
    }
  }

  /// Returns true if the active contact is a confirmed friend (request accepted).
  bool get isActiveChatFriend {
    if (_activeChatId == null) return false;
    final cleanActive = _activeChatId!.toLowerCase().trim();
    if (_sentRequestStatuses[cleanActive] == 'accepted') return true;
    final activeC = activeContact;
    if (activeC != null) {
      final cId = activeC.id.toLowerCase().trim();
      final cUname = activeC.username.toLowerCase().trim();
      if (_sentRequestStatuses[cId] == 'accepted' || _sentRequestStatuses[cUname] == 'accepted') {
        return true;
      }
      if (isContact(activeC.id, activeC.username)) return true;
    }
    for (final c in _contacts) {
      if (c.id.toLowerCase().trim() == cleanActive || c.username.toLowerCase().trim() == cleanActive) {
        return true;
      }
    }
    return false;
  }

  /// Returns true if current user has already sent a cold DM (before friendship).
  bool get coldDmLimitReached {
    if (_activeChatId == null || _currentUserId == null) return false;
    if (_activeChatId!.startsWith('group_')) return false;
    if (isActiveChatFriend) return false;
    final msgs = _messages[_activeChatId!] ?? [];
    // Count how many messages the CURRENT user has sent in this chat
    final myMsgCount = msgs.where((m) => isMyMessage(m)).length;
    return myMsgCount >= 1;
  }

  void sendTextMessage(String text, {String? replyToText}) {
    if (text.trim().isEmpty || _activeChatId == null) return;
    final cleanActive = _activeChatId!.toLowerCase().trim();
    final curId = (_currentUserId ?? '').toLowerCase().trim();
    final curUname = (_currentUsername ?? '').toLowerCase().trim();
    if (cleanActive == curId || (curUname.isNotEmpty && cleanActive == curUname)) {
      debugPrint('Cannot send message to yourself.');
      return;
    }

    // Cold DM limit: max 1 message each side until friend request accepted
    if (coldDmLimitReached) {
      debugPrint('Cold DM limit reached — friend request must be accepted first.');
      return;
    }
    final senderId = _currentUserId ?? 'me';
    final senderName = _currentDisplayName ?? _currentUsername ?? 'User';
    final channelId = getConversationChannelId(_activeChatId!);

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: channelId,
      senderId: senderId,
      senderName: senderName,
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
    final cleanActive = _activeChatId!.toLowerCase().trim();
    final curId = (_currentUserId ?? '').toLowerCase().trim();
    final curUname = (_currentUsername ?? '').toLowerCase().trim();
    if (cleanActive == curId || (curUname.isNotEmpty && cleanActive == curUname)) {
      debugPrint('Cannot send message to yourself.');
      return;
    }

    // Cold DM limit: max 1 message each side until friend request accepted
    if (coldDmLimitReached) {
      debugPrint('Cold DM limit reached — friend request must be accepted first.');
      return;
    }
    final senderId = _currentUserId ?? 'me';
    final senderName = _currentDisplayName ?? _currentUsername ?? 'User';
    final channelId = getConversationChannelId(_activeChatId!);

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: channelId,
      senderId: senderId,
      senderName: senderName,
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

  void deleteImageMessage(PrivateMessageModel msg) {
    String? foundChatId;
    for (var entry in _messages.entries) {
      if (entry.value.any((m) => m.id == msg.id)) {
        foundChatId = entry.key;
        entry.value.removeWhere((m) => m.id == msg.id);
        break;
      }
    }
    if (foundChatId != null) {
      final channelId = getConversationChannelId(foundChatId);
      try {
        FirebaseDatabase.instance.ref('chats/$channelId/messages/${msg.id}').remove();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<String?> createGroupChat({
    required String groupName,
    required List<String> memberIds,
  }) async {
    if (_currentUserId == null) return null;
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final allMembers = <String>{...memberIds, _currentUserId!}.toList();

    final groupContact = PrivateContactModel(
      id: groupId,
      displayName: groupName.trim(),
      username: 'group_$groupId',
      isGroup: true,
      memberIds: allMembers,
    );

    _contacts.add(groupContact);
    _subscribeToContactChat(groupId);
    setActiveChat(groupId, displayName: groupName.trim(), username: 'group_$groupId');
    notifyListeners();

    try {
      for (final mId in allMembers) {
        FirebaseDatabase.instance
            .ref('users/$mId/contacts/$groupId')
            .set(groupContact.toJson());
      }
    } catch (e) {
      debugPrint('Error syncing group chat to Firebase: $e');
    }

    return groupId;
  }

  /// Returns known members of a group chat for @mentions.
  List<PrivateContactModel> getGroupMembers(PrivateContactModel groupContact) {
    if (!groupContact.isGroup) return [];
    final members = <PrivateContactModel>[];
    for (final contact in _contacts) {
      if (!contact.isGroup && groupContact.memberIds.contains(contact.id)) {
        members.add(contact);
      }
    }
    // Also include any senders in active messages if not already in contacts
    final msgs = _messages[groupContact.id] ?? [];
    for (final msg in msgs) {
      if (msg.senderName != null && msg.senderName!.isNotEmpty) {
        final exists = members.any((m) =>
            m.displayName.toLowerCase() == msg.senderName!.toLowerCase() ||
            m.username.toLowerCase() == msg.senderName!.toLowerCase());
        if (!exists && msg.senderId != _currentUserId && msg.senderId != 'me') {
          members.add(PrivateContactModel(
            id: msg.senderId.isNotEmpty ? msg.senderId : msg.senderName!,
            displayName: msg.senderName!,
            username: msg.senderName!.toLowerCase().replaceAll(' ', '_'),
          ));
        }
      }
    }
    return members;
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

            // Exclude current user from search results to prevent self-friend requests
            if (id == _currentUserId ||
                (_currentUsername != null && uname == _currentUsername?.toLowerCase()) ||
                (_currentUserEmail != null && email == _currentUserEmail?.toLowerCase())) {
              continue;
            }

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

    final cleanSender = senderUsername.trim().toLowerCase();
    final cleanSenderId = senderId.trim();
    if (clean == cleanSender ||
        clean == cleanSenderId.toLowerCase() ||
        (_currentUserEmail != null && clean == _currentUserEmail!.toLowerCase())) {
      debugPrint('Self friend request blocked.');
      return;
    }

    String targetId = clean;
    String targetDisplayName = clean;
    String targetUsername = clean;

    // Resolve real target user from user_index or email_index
    try {
      if (!clean.contains('@')) {
        final indexSnap = await FirebaseDatabase.instance.ref('user_index/$clean').get();
        if (indexSnap.exists && indexSnap.value is Map) {
          final data = Map<String, dynamic>.from(indexSnap.value as Map);
          targetId = data['id']?.toString() ?? data['userId']?.toString() ?? targetId;
          targetDisplayName = data['displayName']?.toString() ?? targetDisplayName;
          targetUsername = data['username']?.toString() ?? targetUsername;
        } else {
          // Fallback: search users node directly
          final usersSnap = await FirebaseDatabase.instance.ref('users').get();
          if (usersSnap.exists && usersSnap.value is Map) {
            final rawUsers = Map<String, dynamic>.from(usersSnap.value as Map);
            for (var entry in rawUsers.entries) {
              if (entry.value is Map) {
                final uData = Map<String, dynamic>.from(entry.value as Map);
                final uname = (uData['username'] ?? '').toString().toLowerCase().trim();
                if (uname == clean) {
                  targetId = entry.key.toString();
                  targetDisplayName = uData['displayName']?.toString() ?? targetDisplayName;
                  targetUsername = uData['username']?.toString() ?? targetUsername;
                  break;
                }
              }
            }
          }
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

    if (targetId == cleanSenderId || targetUsername.toLowerCase() == cleanSender) {
      debugPrint('Self friend request blocked after user lookup.');
      return;
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
    final safeTargetId = sanitizeDbKey(targetId);
    final safeTargetUsername = sanitizeDbKey(targetUsername);

    try {
      await FirebaseDatabase.instance
          .ref('friend_requests/$safeTargetId/$requestId')
          .set(request.toJson());
      if (safeTargetUsername != safeTargetId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$safeTargetUsername/$requestId')
            .set(request.toJson());
      }
      if (clean.contains('@')) {
        final safeCleanEmail = sanitizeDbKey(clean);
        if (safeCleanEmail != safeTargetId && safeCleanEmail != safeTargetUsername) {
          await FirebaseDatabase.instance
              .ref('friend_requests/$safeCleanEmail/$requestId')
              .set(request.toJson());
        }
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
    _sentRequestStatuses[targetId.toLowerCase().trim()] = 'pending';
    _sentRequestStatuses[clean] = 'pending';
    _sentRequestStatuses[requestId.toLowerCase().trim()] = 'pending';

    notifyListeners();
  }

  Future<void> respondToFriendRequest(FriendRequestModel req, bool accept) async {
    final status = accept ? 'accepted' : 'rejected';
    final safeReceiverId = sanitizeDbKey(req.receiverId);
    final safeReceiverUsername = sanitizeDbKey(req.receiverUsername);
    final safeSenderId = sanitizeDbKey(req.senderId);

    try {
      // Remove friend request node from receiver so it disappears permanently
      await FirebaseDatabase.instance
          .ref('friend_requests/$safeReceiverId/${req.id}')
          .remove();
      if (safeReceiverUsername != safeReceiverId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$safeReceiverUsername/${req.id}')
            .remove();
      }
      // Update status in the SENDER's sent_requests node so their UI updates in real-time
      await FirebaseDatabase.instance
          .ref('sent_requests/$safeSenderId/${req.id}')
          .update({'status': status});
    } catch (e) {
      debugPrint('Firebase respond to request error: $e');
    }

    _pendingFriendRequests.removeWhere((r) => r.id == req.id);
    _sentRequestStatuses[req.senderId.toLowerCase().trim()] = status;
    _sentRequestStatuses[req.senderUsername.toLowerCase().trim()] = status;
    _tempContacts.remove(req.senderId);
    _tempContacts.remove(req.senderUsername);

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
      _subscribeToContactPresence(req.senderId);
      _subscribeToContactChat(req.senderId);

      if (_currentUserId != null) {
        try {
          // 1. Add sender to receiver's contacts
          await FirebaseDatabase.instance
              .ref('users/$_currentUserId/contacts/${req.senderId}')
              .set(newContact.toJson());

          // 2. Also add receiver to sender's contacts (fetch receiver's display name)
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
        } catch (e) {
          debugPrint('Firebase contact write error on accept: $e');
        }
      }
    }
    notifyListeners();
  }

  /// Delete an entire conversation directly from the sidebar or settings
  Future<void> deleteConversation(String contactId) async {
    _messages.remove(contactId);
    _contacts.removeWhere((c) => c.id == contactId || c.username == contactId);
    _tempContacts.remove(contactId);
    if (_activeChatId == contactId) {
      _activeChatId = null;
    }
    notifyListeners();

    if (_currentUserId != null) {
      try {
        await FirebaseDatabase.instance
            .ref('users/$_currentUserId/recent_chats/$contactId')
            .remove();
        await FirebaseDatabase.instance
            .ref('users/$_currentUserId/contacts/$contactId')
            .remove();
      } catch (e) {
        debugPrint('Firebase delete conversation error: $e');
      }
    }
  }

  /// Clears messages for a conversation without deleting the contact
  void clearConversationMessages(String contactId) {
    _messages[contactId]?.clear();
    notifyListeners();
  }

  /// Full clean wipe of database accounts, chats, and relationships for testing
  Future<void> wipeAllTestData() async {
    try {
      await FirebaseDatabase.instance.ref('chats').remove();
      await FirebaseDatabase.instance.ref('users').remove();
      await FirebaseDatabase.instance.ref('friend_requests').remove();
      await FirebaseDatabase.instance.ref('sent_requests').remove();
      await FirebaseDatabase.instance.ref('blocked_users').remove();
    } catch (e) {
      debugPrint('Firebase wipe data error: $e');
    }
    clearSession();
  }

  void saveMessageToLibrary(PrivateMessageModel msg, LibraryProvider library) {
    if (msg.type == 'image' || msg.type == 'gif') {
      library.uploadItem(
        name: msg.fileName ?? 'Private_Media_${DateTime.now().millisecondsSinceEpoch}.jpg',
        type: 'image',
        size: msg.fileSize ?? '1.8 MB',
        mediaUrl: msg.mediaUrl ?? msg.imageBase64,
        folderId: 'folder_images',
      );
    } else {
      library.uploadItem(
        name: msg.fileName ?? 'Saved_Note_${DateTime.now().millisecondsSinceEpoch}.txt',
        type: msg.type == 'voice' ? 'audio' : 'document',
        size: msg.fileSize ?? '12 KB',
        mediaUrl: msg.mediaUrl ?? msg.imageBase64,
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
    for (var sub in _channelSubscriptions.values) {
      sub.cancel();
    }
    _channelSubscriptions.clear();
    _messages.clear();
    _contacts.clear();
    _pendingFriendRequests.clear();
    _activeChatId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (var sub in _channelSubscriptions.values) {
      sub.cancel();
    }
    _channelSubscriptions.clear();
    _messagesSubscription?.cancel();
    _contactsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _usernameRequestsSubscription?.cancel();
    _emailRequestsSubscription?.cancel();
    _sentRequestsSubscription?.cancel();
    _blockedSubscription?.cancel();
    _recentChatsSubscription?.cancel();
    _infoConnectedSubscription?.cancel();
    for (final sub in _contactPresenceSubs.values) {
      sub.cancel();
    }
    _contactPresenceSubs.clear();
    super.dispose();
  }
}

