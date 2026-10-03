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
import '../services/stealth_notification_service.dart';
import 'library_provider.dart';

class PrivateChatProvider extends ChangeNotifier with WidgetsBindingObserver {
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

  // Presence lifecycle state & in-memory presence caches
  bool _isAppForeground = true;
  final Map<String, bool> _onlineStatusCache = {};
  final Map<String, String> _lastSeenCache = {};

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppForeground = true;
      _syncMyPresence();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached ||
               state == AppLifecycleState.hidden) {
      _isAppForeground = false;
      _setMyPresenceOffline();
    }
  }

  bool isUserOnline(String? idOrUsername) {
    if (idOrUsername == null || idOrUsername.isEmpty) return false;
    final canonicalId = resolveCanonicalId(idOrUsername);
    return _onlineStatusCache[canonicalId] ??
        _onlineStatusCache[canonicalId.toLowerCase()] ??
        _onlineStatusCache[_normalizeIdentifier(idOrUsername)] ??
        false;
  }

  String getUserLastSeen(String? idOrUsername) {
    if (idOrUsername == null || idOrUsername.isEmpty) return 'Active recently';
    final canonicalId = resolveCanonicalId(idOrUsername);
    return _lastSeenCache[canonicalId] ??
        _lastSeenCache[canonicalId.toLowerCase()] ??
        _lastSeenCache[_normalizeIdentifier(idOrUsername)] ??
        'Active recently';
  }

  // sent_requests: targetUsername -> status ('pending'|'accepted'|'rejected')
  final Map<String, String> _sentRequestStatuses = {};
  // blocked user IDs (Firebase UIDs)
  final Set<String> _blockedUserIds = {};

  StreamSubscription<DatabaseEvent>? _messagesSubscription;
  StreamSubscription<DatabaseEvent>? _contactsSubscription;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;
  StreamSubscription<DatabaseEvent>? _requestsLowerSubscription;
  StreamSubscription<DatabaseEvent>? _usernameRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _usernameLowerRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _emailRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _sentRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _blockedSubscription;
  StreamSubscription<DatabaseEvent>? _recentChatsSubscription;
  StreamSubscription<DatabaseEvent>? _recentChatsUsernameSubscription;
  StreamSubscription<DatabaseEvent>? _recentChatsLowerSubscription;
  StreamSubscription<DatabaseEvent>? _contactsLowerSubscription;
  StreamSubscription<DatabaseEvent>? _infoConnectedSubscription;
  final Map<String, StreamSubscription<DatabaseEvent>> _contactPresenceSubs = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _contactProfileSubs = {};
  final Map<String, Map<String, dynamic>> _cachedUserProfiles = {};
  final Map<String, bool> _typingUsers = {};
  final Map<String, String> _typingUserNames = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _typingSubscriptions = {};
  final Set<String> _notifiedMessageIds = {};
  // ignore: unused_field
  BuildContext? _appContext;
  void setNavigationContext(BuildContext context) {
    _appContext = context;
  }

  bool isContactTyping(String? chatId) => chatId != null && _typingUsers[chatId] == true;
  String? getTypingUserName(String? chatId) => chatId != null ? _typingUserNames[chatId] : null;

  String? _currentUsername;
  String? get currentUsername => _currentUsername;
  String? _currentUserEmail;
  String? get currentUserEmail => _currentUserEmail;
  String? _currentDisplayName;
  String? get currentDisplayName => _currentDisplayName;
  String? _currentUserNote;
  String? get currentUserNote => _currentUserNote;

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

  static const String _deletedConversationsPrefsKey = 'deleted_conversations_set';
  final Set<String> _deletedConversationIds = {};

  Future<void> _loadDeletedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deletedConversationsPrefsKey);
      if (list != null) {
        _deletedConversationIds.addAll(list.map((s) => s.toLowerCase().trim()));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistDeletedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_deletedConversationsPrefsKey, _deletedConversationIds.toList());
    } catch (_) {}
  }

  void _unDeleteConversation(String id) {
    final clean = id.toLowerCase().trim();
    final norm = _normalizeIdentifier(clean);
    bool changed = _deletedConversationIds.remove(clean);
    if (norm.isNotEmpty) {
      if (_deletedConversationIds.remove(norm)) changed = true;
    }
    if (changed) {
      _persistDeletedConversations();
    }
  }

  List<PrivateContactModel> get contacts => _contacts;

  /// Strips 'usr_' or '@' prefixes and normalizes for comparison
  static String _normalizeIdentifier(String input) {
    String s = input.trim();
    if (s.startsWith('usr_')) s = s.substring(4);
    if (s.startsWith('@')) s = s.substring(1);
    return s.toLowerCase().trim();
  }

  /// Resolves any ID, username, 'usr_...', or '@...' to its canonical UID
  String resolveCanonicalId(String idOrUsername) {
    if (idOrUsername.startsWith('group_')) return idOrUsername;
    final norm = _normalizeIdentifier(idOrUsername);
    if (norm.isEmpty) return idOrUsername;

    // If it is an internal channel ID like chat_uidA_uidB, resolve to peer UID
    if (norm.startsWith('chat_')) {
      final parts = norm.substring(5).split('_');
      if (parts.length >= 2 && _currentUserId != null) {
        final cur = _normalizeIdentifier(_currentUserId!);
        if (_normalizeIdentifier(parts[0]) == cur) return parts[1];
        if (_normalizeIdentifier(parts[1]) == cur) return parts[0];
      }
      return idOrUsername;
    }

    // 1. Check confirmed contacts
    for (final c in _contacts) {
      if (c.id.toLowerCase() == norm ||
          _normalizeIdentifier(c.username) == norm ||
          _normalizeIdentifier(c.id) == norm) {
        return c.id;
      }
    }

    // 2. Check pending friend requests
    for (final req in _pendingFriendRequests) {
      if (req.senderId.toLowerCase() == norm ||
          _normalizeIdentifier(req.senderUsername) == norm) {
        return req.senderId;
      }
      if (req.receiverId.toLowerCase() == norm ||
          _normalizeIdentifier(req.receiverUsername) == norm) {
        return req.receiverId;
      }
    }

    // 3. Check temporary contacts
    for (final temp in _tempContacts.values) {
      if (temp.id.toLowerCase() == norm ||
          _normalizeIdentifier(temp.username) == norm ||
          _normalizeIdentifier(temp.id) == norm) {
        return temp.id;
      }
    }

    // 4. Check cached user profiles
    for (final entry in _cachedUserProfiles.entries) {
      final uname = _normalizeIdentifier((entry.value['username'] ?? '').toString());
      if (uname == norm || entry.key.toLowerCase() == norm) {
        return entry.key;
      }
    }

    return idOrUsername;
  }

  /// Merges messages from oldKey into canonicalKey (e.g. username -> uid)
  void _mergeMessageKeys(String oldKey, String canonicalKey) {
    if (oldKey == canonicalKey || oldKey.isEmpty || canonicalKey.isEmpty) return;
    if (_messages.containsKey(oldKey)) {
      final oldList = _messages.remove(oldKey) ?? [];
      final canonicalList = _messages[canonicalKey] ?? [];
      final existingIds = canonicalList.map((m) => m.id).toSet();
      for (final msg in oldList) {
        if (!existingIds.contains(msg.id)) {
          canonicalList.add(msg.copyWith(chatId: canonicalKey));
        }
      }
      canonicalList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messages[canonicalKey] = canonicalList;
    }
  }

  PrivateContactModel _applyProfileCache(PrivateContactModel contact) {
    final cached = _cachedUserProfiles[contact.id] ??
        _cachedUserProfiles[_normalizeIdentifier(contact.username)] ??
        _cachedUserProfiles[contact.username];
    if (cached == null) return contact;
    return contact.copyWith(
      avatarUrl: cached['avatarUrl'] as String?,
      clearAvatarUrl: cached['clearAvatarUrl'] == true,
      bio: cached['bio'] as String?,
      clearBio: cached['clearBio'] == true,
      note: cached['note'] as String?,
      clearNote: cached['clearNote'] == true,
      displayName: cached['displayName'] as String? ?? contact.displayName,
      username: cached['username'] as String? ?? contact.username,
    );
  }

  /// Combined list of all DM conversations (accepted friends + active non-friend DMs + pending invitations).
  /// Every person appears exactly ONCE. Cold DM / invitation chat seamlessly continues as the final chat upon acceptance.
  List<PrivateContactModel> get allConversations {
    final Map<String, PrivateContactModel> canonicalMap = {};

    // 1. First add all confirmed contacts
    for (var c in _contacts) {
      final cleanId = c.id.toLowerCase().trim();
      final normUname = _normalizeIdentifier(c.username);
      if (_deletedConversationIds.contains(cleanId) ||
          (normUname.isNotEmpty && _deletedConversationIds.contains(normUname))) {
        continue;
      }
      canonicalMap[c.id] = c;
      if (c.username.isNotEmpty) {
        _mergeMessageKeys(c.username, c.id);
        _mergeMessageKeys('usr_${c.username}', c.id);
        _mergeMessageKeys('@${c.username}', c.id);
      }
    }

    // 2. Add pending friend requests (if not already in contacts)
    for (var req in _pendingFriendRequests) {
      final senderId = req.senderId;
      final senderUsername = req.senderUsername;
      final normSender = _normalizeIdentifier(senderUsername);

      // Skip fake / internal channel IDs
      if (senderId.startsWith('chat_') || normSender.startsWith('chat_')) {
        continue;
      }

      String existingKey = '';
      for (final entry in canonicalMap.entries) {
        if (entry.key == senderId || _normalizeIdentifier(entry.value.username) == normSender) {
          existingKey = entry.key;
          break;
        }
      }

      if (existingKey.isEmpty) {
        canonicalMap[senderId] = PrivateContactModel(
          id: senderId,
          displayName: req.senderName,
          username: senderUsername,
          isOnline: isUserOnline(senderId),
          lastSeenText: getUserLastSeen(senderId),
          unreadCount: 0,
          isPendingInvitation: true,
        );
      } else {
        // Mark the existing conversation with isPendingInvitation
        canonicalMap[existingKey] = canonicalMap[existingKey]!.copyWith(isPendingInvitation: true);
      }

      _mergeMessageKeys(senderUsername, senderId);
      _mergeMessageKeys('usr_$senderUsername', senderId);
      _mergeMessageKeys('@$senderUsername', senderId);
      if (existingKey.isNotEmpty && existingKey != senderId) {
        _mergeMessageKeys(existingKey, senderId);
      }
    }

    // 3. Add temp contacts (cold DMs, recent chats) only if not already present
    for (var temp in _tempContacts.values) {
      final normUname = _normalizeIdentifier(temp.username);
      final normId = _normalizeIdentifier(temp.id);

      // NEVER treat internal channel IDs as contacts!
      if (temp.id.startsWith('chat_') || normId.startsWith('chat_')) {
        continue;
      }

      if (_deletedConversationIds.contains(normId) ||
          (normUname.isNotEmpty && _deletedConversationIds.contains(normUname))) {
        continue;
      }

      bool alreadyPresent = false;
      for (final entry in canonicalMap.entries) {
        if (entry.key == temp.id ||
            _normalizeIdentifier(entry.value.username) == normUname ||
            _normalizeIdentifier(entry.value.id) == normId) {
          alreadyPresent = true;
          _mergeMessageKeys(temp.id, entry.key);
          break;
        }
      }

      if (!alreadyPresent) {
        canonicalMap[temp.id] = temp;
      }
    }

    // 4. Merge messages for any orphan message keys
    for (final msgKey in _messages.keys.toList()) {
      // NEVER create contacts for internal transport channel IDs
      if (msgKey.startsWith('chat_')) {
        continue;
      }

      final normMsgKey = _normalizeIdentifier(msgKey);
      if (_deletedConversationIds.contains(normMsgKey)) {
        continue;
      }

      bool merged = false;
      for (final entry in canonicalMap.entries) {
        if (entry.key == msgKey ||
            _normalizeIdentifier(entry.value.username) == normMsgKey ||
            _normalizeIdentifier(entry.value.id) == normMsgKey) {
          if (entry.key != msgKey) {
            _mergeMessageKeys(msgKey, entry.key);
          }
          merged = true;
          break;
        }
      }
      if (!merged && !canonicalMap.containsKey(msgKey)) {
        final cached = _cachedUserProfiles[msgKey] ?? _cachedUserProfiles[normMsgKey];
        if (cached != null && (cached['displayName'] != null || cached['username'] != null)) {
          canonicalMap[msgKey] = PrivateContactModel(
            id: msgKey,
            displayName: cached['displayName']?.toString() ?? cached['username']?.toString() ?? 'Contact',
            username: cached['username']?.toString() ?? normMsgKey,
            isOnline: false,
            unreadCount: 0,
          );
        } else if (!msgKey.startsWith('usr_') && msgKey.length >= 20 && !msgKey.contains(' ') && !msgKey.contains('@')) {
          // Raw UID hash without profile: fetch profile in background, do not show raw hash as contact
          _fetchUserForChatIfMissing(msgKey);
        } else {
          canonicalMap[msgKey] = PrivateContactModel(
            id: msgKey,
            displayName: msgKey.startsWith('usr_') ? msgKey.replaceFirst('usr_', '@') : msgKey,
            username: msgKey.startsWith('usr_') ? msgKey.replaceFirst('usr_', '') : msgKey,
            isOnline: false,
            unreadCount: 0,
          );
        }
      }
    }

    final curId = (_currentUserId ?? '').toLowerCase().trim();
    final curUname = (_currentUsername ?? '').toLowerCase().trim();

    final list = <PrivateContactModel>[];
    final seenUsernames = <String>{};
    final seenIds = <String>{};

    for (var rawC in canonicalMap.values) {
      final c = _applyProfileCache(rawC);
      final cleanId = c.id.toLowerCase().trim();
      final cleanUname = _normalizeIdentifier(c.username);
      if (curId.isNotEmpty && cleanId == curId) continue;
      if (curUname.isNotEmpty && (cleanUname == curUname || cleanId == curUname)) continue;

      if (c.isGroup) {
        if (seenIds.add(cleanId)) {
          list.add(c.copyWith(unreadCount: getUnreadCount(c.id)));
        }
      } else {
        final idKey = cleanId;
        final unameKey = cleanUname.isNotEmpty ? cleanUname : cleanId;
        if (seenIds.contains(idKey) || seenUsernames.contains(unameKey)) {
          continue;
        }
        seenIds.add(idKey);
        if (cleanUname.isNotEmpty) seenUsernames.add(unameKey);
        list.add(c.copyWith(unreadCount: getUnreadCount(c.id)));
      }
    }

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
        if (!_pendingStatusUpdates.contains(m.id)) {
          _pendingStatusUpdates.add(m.id);
          try {
            FirebaseDatabase.instance
                .ref('chats/$channelId/messages/${m.id}/status')
                .set('seen')
                .then((_) {
              _pendingStatusUpdates.remove(m.id);
            }).catchError((_) {
              _pendingStatusUpdates.remove(m.id);
            });
          } catch (_) {
            _pendingStatusUpdates.remove(m.id);
          }
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  List<FriendRequestModel> get pendingFriendRequests {
    final seenSenders = <String>{};
    final list = <FriendRequestModel>[];
    for (final req in _pendingFriendRequests) {
      if (req.status != 'pending') continue;
      if (req.senderId.startsWith('chat_') ||
          req.senderUsername.startsWith('chat_') ||
          req.id.startsWith('chat_')) {
        continue;
      }

      final senderKey = req.senderId.isNotEmpty
          ? req.senderId
          : _normalizeIdentifier(req.senderUsername);
      if (senderKey.isEmpty) continue;
      if (isContact(req.senderId, req.senderUsername)) continue;
      if (seenSenders.add(senderKey)) {
        list.add(req);
      }
    }
    return list;
  }

  @visibleForTesting
  List<FriendRequestModel> get pendingFriendRequestsInternal => _pendingFriendRequests;

  @visibleForTesting
  void injectMessageForTest(String chatId, PrivateMessageModel msg) {
    _messages.putIfAbsent(chatId, () => []).add(msg);
    notifyListeners();
  }

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
    if (cleanId.isEmpty && cleanUsername.isEmpty) return false;

    final normId = _normalizeIdentifier(targetId);
    final normUname = _normalizeIdentifier(targetUsername);

    return _contacts.any((c) {
      final cId = c.id.toLowerCase().trim();
      final cUname = c.username.toLowerCase().trim();
      final normCId = _normalizeIdentifier(c.id);
      final normCUname = _normalizeIdentifier(c.username);

      final matchesId = cleanId.isNotEmpty && cId.isNotEmpty && (cId == cleanId || cUname == cleanId);
      final matchesUname = cleanUsername.isNotEmpty && cUname.isNotEmpty && (cUname == cleanUsername || cId == cleanUsername);
      final matchesNormId = normId.isNotEmpty && normCId.isNotEmpty && (normCId == normId || normCUname == normId);
      final matchesNormUname = normUname.isNotEmpty && normCUname.isNotEmpty && (normCId == normUname || normCUname == normUname);

      return matchesId || matchesUname || matchesNormId || matchesNormUname;
    });
  }

  bool isBlocked(String userId, [String? username]) {
    final cleanId = userId.toLowerCase().trim();
    final cleanUname = username != null ? username.toLowerCase().trim() : '';
    return _blockedUserIds.contains(cleanId) ||
           (cleanUname.isNotEmpty && _blockedUserIds.contains(cleanUname));
  }

  PrivateContactModel? get activeContact {
    if (_activeChatId == null) return null;
    return getContact(_activeChatId!);
  }

  PrivateContactModel? getContact(String id) {
    final norm = _normalizeIdentifier(id);
    // 1. Confirmed contacts
    for (final c in _contacts) {
      if (c.id == id ||
          c.id.toLowerCase() == norm ||
          _normalizeIdentifier(c.username) == norm ||
          _normalizeIdentifier(c.id) == norm) {
        return _applyProfileCache(c);
      }
    }
    // 2. Pending friend requests (invitations)
    for (final req in _pendingFriendRequests) {
      if (req.senderId == id ||
          _normalizeIdentifier(req.senderUsername) == norm ||
          req.senderId.toLowerCase() == norm) {
        return _applyProfileCache(PrivateContactModel(
          id: req.senderId,
          displayName: req.senderName,
          username: req.senderUsername,
          isOnline: isUserOnline(req.senderId),
          lastSeenText: getUserLastSeen(req.senderId),
          isPendingInvitation: true,
        ));
      }
      if (req.receiverId == id ||
          _normalizeIdentifier(req.receiverUsername) == norm ||
          req.receiverId.toLowerCase() == norm) {
        return _applyProfileCache(PrivateContactModel(
          id: req.receiverId,
          displayName: req.receiverUsername,
          username: req.receiverUsername,
          isOnline: isUserOnline(req.receiverId),
          lastSeenText: getUserLastSeen(req.receiverId),
        ));
      }
    }
    // 3. Temp contacts
    for (final temp in _tempContacts.values) {
      if (temp.id == id ||
          temp.id.toLowerCase() == norm ||
          _normalizeIdentifier(temp.username) == norm) {
        return _applyProfileCache(temp);
      }
    }
    // 4. Default fallback contact object
    if (id.isNotEmpty) {
      final clean = id.startsWith('usr_') ? id.replaceFirst('usr_', '') : id;
      return _applyProfileCache(PrivateContactModel(
        id: id,
        displayName: clean.startsWith('@') ? clean : '@$clean',
        username: clean.replaceFirst('@', ''),
        isOnline: isUserOnline(id),
        lastSeenText: getUserLastSeen(id),
      ));
    }
    return null;
  }

  Map<String, List<PrivateMessageModel>> get messagesMap => Map.unmodifiable(_messages);

  List<PrivateMessageModel> get activeMessages {
    if (_activeChatId == null) return [];
    final byActive = _messages[_activeChatId];
    if (byActive != null && byActive.isNotEmpty) return byActive;
    final canonical = resolveCanonicalId(_activeChatId!);
    final byCanonical = _messages[canonical];
    if (byCanonical != null && byCanonical.isNotEmpty) return byCanonical;
    final channelId = getConversationChannelId(_activeChatId!);
    final byChannel = _messages[channelId];
    if (byChannel != null && byChannel.isNotEmpty) return byChannel;
    return byActive ?? byCanonical ?? byChannel ?? [];
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

  /// Returns chat images sent by the current user
  List<PrivateMessageModel> getSentChatImages([String? chatId]) {
    final list = chatId != null ? allChatImages.where((m) => m.chatId == chatId) : allChatImages;
    return list.where((m) => isMyMessage(m)).toList();
  }

  /// Returns chat images received from others
  List<PrivateMessageModel> getReceivedChatImages([String? chatId]) {
    final list = chatId != null ? allChatImages.where((m) => m.chatId == chatId) : allChatImages;
    return list.where((m) => !isMyMessage(m)).toList();
  }

  /// Count of received chat images only (sent images do NOT trigger notification badges)
  int get receivedChatImagesCount => getReceivedChatImages().length;

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

  /// Returns all starred messages for a specific chat, or from all chats if chatId is null.
  List<PrivateMessageModel> getStarredMessages([String? chatId]) {
    final targetId = chatId ?? _activeChatId;
    if (targetId == null) {
      final all = <PrivateMessageModel>[];
      for (var l in _messages.values) {
        all.addAll(l.where((m) => m.isStarred));
      }
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }
    final list = _messages[targetId] ?? [];
    final starred = list.where((m) => m.isStarred).toList();
    starred.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return starred;
  }

  bool isMessageStarred(String messageId) {
    for (var list in _messages.values) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) return list[idx].isStarred;
    }
    return false;
  }

  /// Toggles the starred status of a message.
  Future<bool> toggleStarMessage(PrivateMessageModel msg) async {
    final targetChatId = _activeChatId ?? msg.chatId;
    final list = _messages[targetChatId] ?? _messages.values.firstWhere(
      (l) => l.any((m) => m.id == msg.id),
      orElse: () => [],
    );

    final idx = list.indexWhere((m) => m.id == msg.id);
    final currentlyStarred = idx != -1 ? list[idx].isStarred : msg.isStarred;
    final newStarred = !currentlyStarred;

    final updatedMsg = (idx != -1 ? list[idx] : msg).copyWith(isStarred: newStarred);
    if (idx != -1) {
      list[idx] = updatedMsg;
    } else if (targetChatId.isNotEmpty) {
      _messages.putIfAbsent(targetChatId, () => []).add(updatedMsg);
    }

    notifyListeners();

    final channelId = getConversationChannelId(targetChatId.isNotEmpty ? targetChatId : msg.chatId);
    _syncMessageToFirebase(updatedMsg, channelId);
    return newStarred;
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
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _loadPrivacySettings();
    _loadFavoriteGifs();
    _loadDeletedConversations();
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

  /// Prompts user to select a .json or .zip backup file and restores chats & contacts
  Future<bool> importChatsFromZipFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final fileBytes = result.files.first.bytes!;
        final backupData = ChatBackupService.importChatsFromBytes(fileBytes);

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
    _loadUserNote(cleanUserId);
    _initPresenceSystem(cleanUserId);

    _listenToFirebaseUserContacts(userId);
    _listenToFirebaseRecentChats(userId);
    _listenToFirebaseFriendRequests(userId, username: username, email: email);
    _listenToFirebaseSentRequests(userId);
    _listenToFirebaseBlockedUsers(userId);
    notifyListeners();
  }

  Future<void> _loadUserNote(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserNote = prefs.getString('floating_note_$userId');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateCurrentUserNote(String? note) async {
    _currentUserNote = (note != null && note.trim().isNotEmpty) ? note.trim() : null;
    notifyListeners();
    if (_currentUserId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_currentUserNote != null) {
          await prefs.setString('floating_note_$_currentUserId', _currentUserNote!);
        } else {
          await prefs.remove('floating_note_$_currentUserId');
        }
        await FirebaseDatabase.instance
            .ref('users/$_currentUserId/note')
            .set(_currentUserNote);
      } catch (_) {}
    }
  }

  Future<void> updateContactNote(String contactId, String? note) async {
    final cleanNote = (note != null && note.trim().isNotEmpty) ? note.trim() : null;
    final idx = _contacts.indexWhere((c) => c.id == contactId);
    if (idx != -1) {
      _contacts[idx] = _contacts[idx].copyWith(note: cleanNote);
      notifyListeners();
    }
    if (_currentUserId != null) {
      try {
        await FirebaseDatabase.instance
            .ref('users/$_currentUserId/contacts/$contactId/note')
            .set(cleanNote);
      } catch (_) {}
    }
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
      final curUid = _currentUserId!;
      final lowerCurUid = curUid.toLowerCase().trim();
      final isOnline = _isAppForeground && _showOnlineStatus;
      final presenceData = {
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      };

      final presenceRef = FirebaseDatabase.instance.ref('users/$curUid/presence');
      presenceRef.onDisconnect().set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
      presenceRef.set(presenceData);

      if (lowerCurUid != curUid) {
        final lowerRef = FirebaseDatabase.instance.ref('users/$lowerCurUid/presence');
        lowerRef.onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
        lowerRef.set(presenceData);
      }

      if (_currentUsername != null && _currentUsername!.isNotEmpty) {
        final uname = _normalizeIdentifier(_currentUsername!);
        if (uname.isNotEmpty && uname != curUid && uname != lowerCurUid) {
          final unameRef = FirebaseDatabase.instance.ref('users/$uname/presence');
          unameRef.onDisconnect().set({
            'isOnline': false,
            'lastSeen': ServerValue.timestamp,
          });
          unameRef.set(presenceData);
        }
      }
    } catch (_) {}
  }

  void _setMyPresenceOffline() {
    if (_currentUserId == null) return;
    try {
      final curUid = _currentUserId!;
      final lowerCurUid = curUid.toLowerCase().trim();
      final offlineData = {
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      };

      FirebaseDatabase.instance.ref('users/$curUid/presence').set(offlineData);
      if (lowerCurUid != curUid) {
        FirebaseDatabase.instance.ref('users/$lowerCurUid/presence').set(offlineData);
      }
      if (_currentUsername != null && _currentUsername!.isNotEmpty) {
        final uname = _normalizeIdentifier(_currentUsername!);
        if (uname.isNotEmpty && uname != curUid && uname != lowerCurUid) {
          FirebaseDatabase.instance.ref('users/$uname/presence').set(offlineData);
        }
      }
    } catch (_) {}
  }

  void _subscribeToContactPresence(String contactId) {
    if (contactId.isEmpty || contactId.startsWith('chat_')) return;
    final canonicalId = resolveCanonicalId(contactId);

    if (!_contactProfileSubs.containsKey(canonicalId)) {
      try {
        final profileRef = FirebaseDatabase.instance.ref('users/$canonicalId');
        _contactProfileSubs[canonicalId] = profileRef.onValue.listen((event) {
          if (event.snapshot.value != null && event.snapshot.value is Map) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            final avatarUrl = data['avatarUrl']?.toString();
            final bio = data['bio']?.toString();
            final note = data['note']?.toString();
            final displayName = data['displayName']?.toString();
            final username = data['username']?.toString();

            final cacheEntry = <String, dynamic>{
              if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
              if (data.containsKey('avatarUrl') && (avatarUrl == null || avatarUrl.isEmpty)) 'clearAvatarUrl': true,
              if (bio != null && bio.isNotEmpty) 'bio': bio,
              if (data.containsKey('bio') && (bio == null || bio.isEmpty)) 'clearBio': true,
              if (note != null && note.isNotEmpty) 'note': note,
              if (data.containsKey('note') && (note == null || note.isEmpty)) 'clearNote': true,
              if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
              if (username != null && username.isNotEmpty) 'username': username,
            };

            _cachedUserProfiles[canonicalId] = cacheEntry;
            if (username != null && username.isNotEmpty) {
              _cachedUserProfiles[_normalizeIdentifier(username)] = cacheEntry;
              _cachedUserProfiles[username] = cacheEntry;
            }

            for (int i = 0; i < _contacts.length; i++) {
              if (_contacts[i].id == canonicalId ||
                  (username != null && _normalizeIdentifier(_contacts[i].username) == _normalizeIdentifier(username))) {
                _contacts[i] = _applyProfileCache(_contacts[i]);
              }
            }
            if (_tempContacts.containsKey(canonicalId)) {
              _tempContacts[canonicalId] = _applyProfileCache(_tempContacts[canonicalId]!);
            }
            if (username != null && _tempContacts.containsKey(username)) {
              _tempContacts[username] = _applyProfileCache(_tempContacts[username]!);
            }
            notifyListeners();
          }
        }, onError: (_) {});
      } catch (_) {}
    }

    if (_contactPresenceSubs.containsKey(canonicalId)) return;
    try {
      final ref = FirebaseDatabase.instance.ref('users/$canonicalId/presence');
      _contactPresenceSubs[canonicalId] = ref.onValue.listen((event) {
        bool isOnline = false;
        String lastSeenStr = 'Active recently';

        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          isOnline = data['isOnline'] == true;
          final lastSeenRaw = data['lastSeen'];
          int? lastSeenMs;
          if (lastSeenRaw is num) {
            lastSeenMs = lastSeenRaw.toInt();
          }

          if (isOnline) {
            lastSeenStr = 'Online';
          } else if (lastSeenMs != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
            final now = DateTime.now();
            final diff = now.difference(dt);
            if (diff.inSeconds < 60) {
              lastSeenStr = 'Last seen just now';
            } else if (diff.inMinutes < 60) {
              lastSeenStr = 'Last seen ${diff.inMinutes}m ago';
            } else if (diff.inHours < 24 && now.day == dt.day) {
              final h = dt.hour.toString().padLeft(2, '0');
              final m = dt.minute.toString().padLeft(2, '0');
              lastSeenStr = 'Last seen today at $h:$m';
            } else if (diff.inDays <= 1 || (diff.inHours < 48 && now.day - dt.day == 1)) {
              final h = dt.hour.toString().padLeft(2, '0');
              final m = dt.minute.toString().padLeft(2, '0');
              lastSeenStr = 'Last seen yesterday at $h:$m';
            } else {
              lastSeenStr = 'Last seen recently';
            }
          }
        }

        // Cache presence
        _onlineStatusCache[canonicalId] = isOnline;
        _onlineStatusCache[canonicalId.toLowerCase()] = isOnline;
        _lastSeenCache[canonicalId] = lastSeenStr;
        _lastSeenCache[canonicalId.toLowerCase()] = lastSeenStr;

        final normCanonical = _normalizeIdentifier(canonicalId);
        if (normCanonical.isNotEmpty) {
          _onlineStatusCache[normCanonical] = isOnline;
          _lastSeenCache[normCanonical] = lastSeenStr;
        }

        for (int i = 0; i < _contacts.length; i++) {
          final c = _contacts[i];
          if (c.id == canonicalId ||
              c.id.toLowerCase() == canonicalId.toLowerCase() ||
              _normalizeIdentifier(c.username) == normCanonical) {
            _contacts[i] = c.copyWith(
              isOnline: isOnline,
              lastSeenText: lastSeenStr,
            );
          }
        }

        for (final key in _tempContacts.keys.toList()) {
          final tc = _tempContacts[key];
          if (tc != null &&
              (tc.id == canonicalId ||
               tc.id.toLowerCase() == canonicalId.toLowerCase() ||
               _normalizeIdentifier(tc.username) == normCanonical)) {
            _tempContacts[key] = tc.copyWith(
              isOnline: isOnline,
              lastSeenText: lastSeenStr,
            );
          }
        }

        if (isOnline) {
          final msgs = _messages[canonicalId];
          if (msgs != null && msgs.isNotEmpty) {
            final channelId = getConversationChannelId(canonicalId);
            for (int i = 0; i < msgs.length; i++) {
              final m = msgs[i];
              if (isMyMessage(m) && m.status == 'sent') {
                msgs[i] = m.copyWith(status: 'delivered');
                try {
                  FirebaseDatabase.instance
                      .ref('chats/$channelId/messages/${m.id}/status')
                      .set('delivered');
                } catch (_) {}
              }
            }
          }
        }
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  /// Public subscription to a user's real-time presence (e.g. for search results)
  void subscribeToUserPresence(String idOrUsername) {
    if (idOrUsername.isEmpty) return;
    final canonicalId = resolveCanonicalId(idOrUsername);
    _subscribeToContactPresence(canonicalId);
  }

  /// Called on logout — cancels all Firebase subscriptions and clears all state.
  void clearSession() {
    _setMyPresenceOffline();
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
    _onlineStatusCache.clear();
    _lastSeenCache.clear();
    notifyListeners();
  }

  void _clearAllSubscriptions() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _contactsSubscription?.cancel();
    _contactsSubscription = null;
    _contactsLowerSubscription?.cancel();
    _contactsLowerSubscription = null;
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _requestsLowerSubscription?.cancel();
    _requestsLowerSubscription = null;
    _usernameRequestsSubscription?.cancel();
    _usernameRequestsSubscription = null;
    _usernameLowerRequestsSubscription?.cancel();
    _usernameLowerRequestsSubscription = null;
    _emailRequestsSubscription?.cancel();
    _emailRequestsSubscription = null;
    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription = null;
    _blockedSubscription?.cancel();
    _blockedSubscription = null;
    _recentChatsSubscription?.cancel();
    _recentChatsSubscription = null;
    _recentChatsUsernameSubscription?.cancel();
    _recentChatsUsernameSubscription = null;
    _recentChatsLowerSubscription?.cancel();
    _recentChatsLowerSubscription = null;
    _infoConnectedSubscription?.cancel();
    _infoConnectedSubscription = null;
    for (final sub in _contactPresenceSubs.values) {
      sub.cancel();
    }
    _contactPresenceSubs.clear();
    for (final sub in _contactProfileSubs.values) {
      sub.cancel();
    }
    _contactProfileSubs.clear();
    for (final sub in _channelSubscriptions.values) {
      sub.cancel();
    }
    _channelSubscriptions.clear();
    _cachedUserProfiles.clear();
  }

  void _listenToFirebaseRecentChats(String userId) {
    _recentChatsSubscription?.cancel();
    _recentChatsSubscription = null;
    _recentChatsUsernameSubscription?.cancel();
    _recentChatsUsernameSubscription = null;

    void processRecentChatsSnapshot(DataSnapshot snapshot) {
      if (snapshot.value != null && snapshot.value is Map) {
        final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in rawMap.entries) {
          final otherUserId = entry.key;
          final cleanOther = otherUserId.toLowerCase().trim();

          // 1. If key is an internal channel ID (e.g. chat_...), clean it up from Firebase and skip!
          if (cleanOther.startsWith('chat_')) {
            try {
              FirebaseDatabase.instance.ref('users/$userId/recent_chats/$otherUserId').remove();
            } catch (_) {}
            continue;
          }

          // 2. If user deleted this conversation, skip and clean up from recent_chats
          if (_deletedConversationIds.contains(cleanOther)) {
            try {
              FirebaseDatabase.instance.ref('users/$userId/recent_chats/$otherUserId').remove();
            } catch (_) {}
            continue;
          }

          final curId = (_currentUserId ?? '').toLowerCase().trim();
          final curUname = (_currentUsername ?? '').toLowerCase().trim();
          if (cleanOther == curId || cleanOther == curUname) {
            continue;
          }

          if (entry.value is Map) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            final senderName = data['senderName']?.toString() ?? 'User';
            final senderUsername = data['senderUsername']?.toString() ?? 'user';
            final normSenderUname = _normalizeIdentifier(senderUsername);

            if (normSenderUname == curUname) continue;
            if (_deletedConversationIds.contains(normSenderUname)) {
              try {
                FirebaseDatabase.instance.ref('users/$userId/recent_chats/$otherUserId').remove();
              } catch (_) {}
              continue;
            }

            if (!_contacts.any((c) => c.id == otherUserId) &&
                !_tempContacts.containsKey(otherUserId)) {
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
        notifyListeners();
      }
    }

    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId/recent_chats');
      _recentChatsSubscription = ref.onValue.listen((event) {
        processRecentChatsSnapshot(event.snapshot);
      }, onError: (_) {});

      final lowerId = userId.toLowerCase().trim();
      if (lowerId != userId) {
        final lowerRef = FirebaseDatabase.instance.ref('users/$lowerId/recent_chats');
        _recentChatsLowerSubscription = lowerRef.onValue.listen((event) {
          processRecentChatsSnapshot(event.snapshot);
        }, onError: (_) {});
      }

      final uname = _currentUsername;
      if (uname != null && uname.isNotEmpty && uname != userId && uname != lowerId) {
        final uRef = FirebaseDatabase.instance.ref('users/$uname/recent_chats');
        _recentChatsUsernameSubscription = uRef.onValue.listen((event) {
          processRecentChatsSnapshot(event.snapshot);
        }, onError: (_) {});
      }
    } catch (_) {}
  }

  final Map<String, StreamSubscription<DatabaseEvent>> _channelSubscriptions = {};
  final Set<String> _pendingStatusUpdates = {};
  final Map<String, bool> _myTypingStatus = {};

  void _processContactsSnapshot(dynamic value) {
    if (value != null && value is Map) {
      final rawMap = Map<String, dynamic>.from(value);
      for (var entry in rawMap.entries) {
        if (entry.value is Map) {
          final contactJson = Map<String, dynamic>.from(entry.value as Map);
          var contact = PrivateContactModel.fromJson(contactJson);
          final cleanContactId = contact.id.toLowerCase().trim();
          final normContactUname = _normalizeIdentifier(contact.username);
          final curId = (_currentUserId ?? '').toLowerCase().trim();
          final curUname = (_currentUsername ?? '').toLowerCase().trim();
          if (contact.id.toLowerCase().trim() == curId || contact.username.toLowerCase().trim() == curUname) {
            continue;
          }
          contact = _applyProfileCache(contact);
          contact = contact.copyWith(
            isOnline: isUserOnline(contact.id),
            lastSeenText: getUserLastSeen(contact.id),
          );
          final existingIdx = _contacts.indexWhere((c) =>
              c.id.toLowerCase() == cleanContactId ||
              (_normalizeIdentifier(c.username).isNotEmpty &&
               _normalizeIdentifier(c.username) == normContactUname));
          if (existingIdx != -1) {
            _contacts[existingIdx] = contact;
          } else {
            _contacts.add(contact);
          }

          // Clean up any temp contact for this user
          _tempContacts.remove(contact.id);
          _tempContacts.remove(contact.username);
          _tempContacts.remove('usr_${contact.username}');
          _tempContacts.remove('@${contact.username}');
          _tempContacts.remove(_normalizeIdentifier(contact.username));

          // Merge messages from username / usr_ keys into canonical contact.id
          _mergeMessageKeys(contact.username, contact.id);
          _mergeMessageKeys('usr_${contact.username}', contact.id);
          _mergeMessageKeys('@${contact.username}', contact.id);
          _mergeMessageKeys(_normalizeIdentifier(contact.username), contact.id);

          _subscribeToContactChat(contact.id);
          _subscribeToContactPresence(contact.id);

          if (contact.isGroup) {
            for (final memberId in contact.memberIds) {
              if (memberId != _currentUserId) {
                _subscribeToContactPresence(memberId);
              }
            }
          }
        }
      }
      notifyListeners();
    }
  }

  void _listenToFirebaseUserContacts(String userId) {
    _contactsSubscription?.cancel();
    _contactsLowerSubscription?.cancel();
    _contacts.clear();
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId/contacts');
      _contactsSubscription = ref.onValue.listen((event) {
        _processContactsSnapshot(event.snapshot.value);
      }, onError: (e) {
        debugPrint('Firebase RTDB contacts error: $e');
      });

      final lowerId = userId.toLowerCase().trim();
      if (lowerId != userId) {
        final lowerRef = FirebaseDatabase.instance.ref('users/$lowerId/contacts');
        _contactsLowerSubscription = lowerRef.onValue.listen((event) {
          _processContactsSnapshot(event.snapshot.value);
        }, onError: (e) {
          debugPrint('Firebase RTDB lower contacts error: $e');
        });
      }
    } catch (e) {
      debugPrint('Firebase RTDB not initialized or offline: $e');
    }
  }

  PrivateMessageModel _parseAndDecryptMessage(Map<String, dynamic> rawJson, String channelId) {
    final msg = PrivateMessageModel.fromJson(rawJson);
    final normChannel = getConversationChannelId(channelId);

    String decryptedText = EncryptionService.decryptText(msg.text, normChannel);
    if (decryptedText.startsWith('🔒') && msg.chatId.isNotEmpty && msg.chatId != normChannel) {
      final alt = EncryptionService.decryptText(msg.text, msg.chatId);
      if (!alt.startsWith('🔒')) decryptedText = alt;
    }
    if (decryptedText.startsWith('🔒') && channelId != normChannel) {
      final alt = EncryptionService.decryptText(msg.text, channelId);
      if (!alt.startsWith('🔒')) decryptedText = alt;
    }

    String? decryptedReply = msg.replyToText;
    if (msg.replyToText != null && msg.replyToText!.isNotEmpty) {
      decryptedReply = EncryptionService.decryptText(msg.replyToText!, normChannel);
      if (decryptedReply.startsWith('🔒') && msg.chatId.isNotEmpty && msg.chatId != normChannel) {
        final alt = EncryptionService.decryptText(msg.replyToText!, msg.chatId);
        if (!alt.startsWith('🔒')) decryptedReply = alt;
      }
      if (decryptedReply.startsWith('🔒') && channelId != normChannel) {
        final alt = EncryptionService.decryptText(msg.replyToText!, channelId);
        if (!alt.startsWith('🔒')) decryptedReply = alt;
      }
    }

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
      bool isFirstSnapshot = true;
      _channelSubscriptions[channelId] = ref.onValue.listen((event) {
        final msgs = <PrivateMessageModel>[];
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final rawMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          msgs.addAll(rawMap.values
              .whereType<Map>()
              // Skip orphan status-only records (ghost bubbles) — a valid message MUST have a senderId
              .where((val) => val['senderId'] != null && val['senderId'].toString().isNotEmpty)
              .map((val) => _parseAndDecryptMessage(Map<String, dynamic>.from(val), channelId))
              .toList());
          msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }

        // Store messages across channelId, contactId, canonical UID, and activeChatId
        // Merge optimistic (locally-sent but not yet confirmed by Firebase) messages
        // so they don't disappear while in-flight. Deduplicate by message ID.
        List<PrivateMessageModel> mergeWithPending(List<PrivateMessageModel> firebaseMsgs, String key) {
          final existing = _messages[key];
          if (existing == null || existing.isEmpty) return firebaseMsgs;
          final fbIds = firebaseMsgs.map((m) => m.id).toSet();
          final pending = existing.where((m) => isMyMessage(m) && !fbIds.contains(m.id)).toList();
          if (pending.isEmpty) return firebaseMsgs;
          final merged = [...firebaseMsgs, ...pending];
          merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return merged;
        }

        final canonicalId = resolveCanonicalId(contactId);
        final normContact = _normalizeIdentifier(contactId);
        final normCanonical = _normalizeIdentifier(canonicalId);

        final mergedMsgs = mergeWithPending(msgs, channelId);
        _messages[channelId] = mergedMsgs;
        _messages[contactId] = mergedMsgs;
        _messages[canonicalId] = mergedMsgs;
        if (normContact.isNotEmpty) _messages[normContact] = mergedMsgs;
        if (normCanonical.isNotEmpty) _messages[normCanonical] = mergedMsgs;

        if (_activeChatId != null &&
            (getConversationChannelId(_activeChatId!) == channelId ||
             resolveCanonicalId(_activeChatId!) == canonicalId ||
             _normalizeIdentifier(_activeChatId!) == normCanonical ||
             _normalizeIdentifier(_activeChatId!) == normContact ||
             _activeChatId == contactId)) {
          _messages[_activeChatId!] = mergedMsgs;
        }

        if (msgs.isNotEmpty) {
          final hasIncoming = msgs.any((m) => !isMyMessage(m));
          if (hasIncoming) {
            // Deleting a chat is not blocking: un-tombstone so incoming messages appear
            _unDeleteConversation(contactId);
            _unDeleteConversation(canonicalId);
            final normC = _normalizeIdentifier(contactId);
            if (normC.isNotEmpty) _unDeleteConversation(normC);
            final normCan = _normalizeIdentifier(canonicalId);
            if (normCan.isNotEmpty) _unDeleteConversation(normCan);
          }

          final isAppResumed = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
          final isUserViewingActiveChat = (_activeChatId == contactId ||
                  _activeChatId == canonicalId ||
                  (_activeChatId != null && getConversationChannelId(_activeChatId!) == channelId)) &&
              isAppResumed;

          for (final m in msgs) {
            if (!isMyMessage(m)) {
              if (isUserViewingActiveChat && _sendReadReceipts) {
                if (m.status != 'seen' && !_pendingStatusUpdates.contains(m.id)) {
                  _pendingStatusUpdates.add(m.id);
                  try {
                    FirebaseDatabase.instance
                        .ref('chats/$channelId/messages/${m.id}/status')
                        .set('seen')
                        .then((_) {
                      _pendingStatusUpdates.remove(m.id);
                    }).catchError((_) {
                      _pendingStatusUpdates.remove(m.id);
                    });
                  } catch (_) {
                    _pendingStatusUpdates.remove(m.id);
                  }
                }
              } else {
                if (m.status == 'sent' && !_pendingStatusUpdates.contains(m.id)) {
                  _pendingStatusUpdates.add(m.id);
                  try {
                    FirebaseDatabase.instance
                        .ref('chats/$channelId/messages/${m.id}/status')
                        .set('delivered')
                        .then((_) {
                      _pendingStatusUpdates.remove(m.id);
                    }).catchError((_) {
                      _pendingStatusUpdates.remove(m.id);
                    });
                  } catch (_) {
                    _pendingStatusUpdates.remove(m.id);
                  }
                }
                
                if (isFirstSnapshot) {
                  _notifiedMessageIds.add(m.id);
                } else if (_notifiedMessageIds.add(m.id)) {
                  if (!StealthNotificationService.isAppActive) {
                    if (m.type == 'urgent') {
                      StealthNotificationService.showUrgentNotification();
                    } else if (m.type == 'redacted') {
                      StealthNotificationService.showSystemPushNotification(
                        title: 'Longcat Redacted Notice',
                        body: m.text,
                      );
                    } else {
                      StealthNotificationService.showSystemPushNotification();
                    }
                  }
                }
              }
            }
          }
        }
        isFirstSnapshot = false;
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
    _requestsLowerSubscription?.cancel();
    _usernameRequestsSubscription?.cancel();
    _usernameLowerRequestsSubscription?.cancel();
    _emailRequestsSubscription?.cancel();

    final safeUserId = sanitizeDbKey(userId);
    final lowerSafeUserId = safeUserId.toLowerCase().trim();
    try {
      final ref = FirebaseDatabase.instance.ref('friend_requests/$safeUserId');
      _requestsSubscription = ref.onValue.listen((event) {
        _handleFriendRequestsSnapshot(event.snapshot);
      }, onError: (e) {
        debugPrint('Firebase RTDB friend requests error: $e');
      });

      if (lowerSafeUserId != safeUserId) {
        final lowerRef = FirebaseDatabase.instance.ref('friend_requests/$lowerSafeUserId');
        _requestsLowerSubscription = lowerRef.onValue.listen((event) {
          _handleFriendRequestsSnapshot(event.snapshot);
        }, onError: (_) {});
      }

      if (username != null && username.isNotEmpty) {
        final safeUname = sanitizeDbKey(username);
        final lowerSafeUname = safeUname.toLowerCase().trim();
        if (safeUname != safeUserId && safeUname != lowerSafeUserId) {
          final uRef = FirebaseDatabase.instance.ref('friend_requests/$safeUname');
          _usernameRequestsSubscription = uRef.onValue.listen((event) {
            _handleFriendRequestsSnapshot(event.snapshot);
          }, onError: (_) {});
        }
        if (lowerSafeUname != safeUname && lowerSafeUname != safeUserId && lowerSafeUname != lowerSafeUserId) {
          final uLowerRef = FirebaseDatabase.instance.ref('friend_requests/$lowerSafeUname');
          _usernameLowerRequestsSubscription = uLowerRef.onValue.listen((event) {
            _handleFriendRequestsSnapshot(event.snapshot);
          }, onError: (_) {});
        }
      }

      if (email != null && email.isNotEmpty) {
        final safeEmail = sanitizeDbKey(email);
        if (safeEmail != safeUserId && safeEmail != lowerSafeUserId) {
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

  /// Proactively refresh latest friend requests so UI is always updated instantly without app restart
  Future<void> refreshFriendRequests() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;
    final safeUid = sanitizeDbKey(uid);
    final lowerSafeUid = safeUid.toLowerCase().trim();
    final uname = _currentUsername;
    final safeUname = (uname != null && uname.isNotEmpty) ? sanitizeDbKey(uname) : '';
    final lowerSafeUname = safeUname.toLowerCase().trim();

    final pathsToFetch = <String>{
      'friend_requests/$safeUid',
      if (lowerSafeUid != safeUid) 'friend_requests/$lowerSafeUid',
      if (safeUname.isNotEmpty && safeUname != safeUid && safeUname != lowerSafeUid) 'friend_requests/$safeUname',
      if (lowerSafeUname.isNotEmpty && lowerSafeUname != safeUname && lowerSafeUname != safeUid && lowerSafeUname != lowerSafeUid) 'friend_requests/$lowerSafeUname',
    };

    try {
      for (final p in pathsToFetch) {
        final snap = await FirebaseDatabase.instance.ref(p).get();
        if (snap.exists) {
          _handleFriendRequestsSnapshot(snap);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing friend requests: $e');
    }
    notifyListeners();
  }

  void _handleFriendRequestsSnapshot(DataSnapshot snapshot) {
    if (snapshot.value != null && snapshot.value is Map) {
      final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in rawMap.entries) {
        if (entry.value is Map) {
          final reqJson = Map<String, dynamic>.from(entry.value as Map);
          final req = FriendRequestModel.fromJson(reqJson);

          if (req.senderId.startsWith('chat_') ||
              req.senderUsername.startsWith('chat_') ||
              req.id.startsWith('chat_')) {
            // Clean up corrupted friend request node
            if (_currentUserId != null) {
              final safeUid = sanitizeDbKey(_currentUserId!);
              try {
                FirebaseDatabase.instance.ref('friend_requests/$safeUid/${req.id}').remove();
              } catch (_) {}
            }
            continue;
          }

          final cleanSenderId = req.senderId.toLowerCase().trim();
          final normReqUname = _normalizeIdentifier(req.senderUsername);

          if (req.status == 'pending') {
            // Incoming pending friend request: un-tombstone sender so it is never suppressed
            _unDeleteConversation(cleanSenderId);
            if (normReqUname.isNotEmpty) {
              _unDeleteConversation(normReqUname);
            }
            if (req.senderId.isNotEmpty) {
              _unDeleteConversation(req.senderId);
            }
          } else {
            if (_deletedConversationIds.contains(cleanSenderId) ||
                (normReqUname.isNotEmpty && _deletedConversationIds.contains(normReqUname))) {
              continue;
            }
          }

          bool matchesSender(FriendRequestModel r) {
            if (r.id == req.id) return true;
            if (r.senderId.isNotEmpty && req.senderId.isNotEmpty && r.senderId == req.senderId) return true;
            final rUname = _normalizeIdentifier(r.senderUsername);
            final reqUname = _normalizeIdentifier(req.senderUsername);
            if (rUname.isNotEmpty && reqUname.isNotEmpty && rUname == reqUname) return true;
            return false;
          }

          if (req.status == 'pending') {
            if (isContact(req.senderId, req.senderUsername)) {
              _pendingFriendRequests.removeWhere(matchesSender);
              continue;
            }
            final idx = _pendingFriendRequests.indexWhere(matchesSender);
            if (idx == -1) {
              _pendingFriendRequests.add(req);
            } else {
              _pendingFriendRequests[idx] = req;
            }
            if (req.senderId.isNotEmpty) {
              _subscribeToContactChat(req.senderId);
              _subscribeToContactPresence(req.senderId);
            }
          } else {
            _pendingFriendRequests.removeWhere(matchesSender);
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

  bool _isWifeyIdentifier(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final clean = text.toLowerCase().trim();
    return clean.contains('ashlin') ||
           clean.contains('mirsha') ||
           clean.contains('shashi') ||
           clean.endsWith('mirsha') ||
           clean.endsWith('shashi') ||
           clean.endsWith('ashlin');
  }

  bool _isHubbyIdentifier(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final clean = text.toLowerCase().trim();
    return clean.contains('aarush') ||
           clean.contains('lohit') ||
           clean.endsWith('aarushlohit');
  }

  /// Returns non-null cuddle message if block is prevented by Easter Egg rule
  String? checkBlockCuddleEasterEgg({
    required String targetId,
    required String targetUsername,
    required String targetDisplayName,
    String? currentUsername,
  }) {
    final curUname = (currentUsername ?? _currentUsername ?? '').toLowerCase().trim();
    final curId = (_currentUserId ?? '').toLowerCase().trim();

    final curIsHubby = _isHubbyIdentifier(curId) || _isHubbyIdentifier(curUname) || _isHubbyIdentifier(_currentDisplayName);
    final curIsWifey = _isWifeyIdentifier(curId) || _isWifeyIdentifier(curUname) || _isWifeyIdentifier(_currentDisplayName);

    final targetIsHubby = _isHubbyIdentifier(targetId) || _isHubbyIdentifier(targetUsername) || _isHubbyIdentifier(targetDisplayName);
    final targetIsWifey = _isWifeyIdentifier(targetId) || _isWifeyIdentifier(targetUsername) || _isWifeyIdentifier(targetDisplayName);

    if (curIsWifey && targetIsHubby) {
      return "how u can block your future hubby go cuddle him 💕";
    }
    if (curIsHubby && targetIsWifey) {
      return "how you can block your wifeyyy go do some cuddle !!! 💕";
    }
    return null;
  }

  /// Returns null on success, or a cuddle message string if block is prevented by Easter Egg
  Future<String?> blockUser({
    required String targetId,
    required String targetUsername,
    required String targetDisplayName,
    String? currentUsername,
  }) async {
    final cuddleMsg = checkBlockCuddleEasterEgg(
      targetId: targetId,
      targetUsername: targetUsername,
      targetDisplayName: targetDisplayName,
      currentUsername: currentUsername,
    );

    if (cuddleMsg != null) {
      return cuddleMsg;
    }

    final cleanId = targetId.toLowerCase().trim();
    final cleanUname = targetUsername.toLowerCase().trim();
    _blockedUserIds.add(cleanId);
    if (cleanUname.isNotEmpty) _blockedUserIds.add(cleanUname);
    notifyListeners();

    if (_currentUserId == null) return null;
    try {
      await FirebaseDatabase.instance
          .ref('blocked_users/$_currentUserId/$targetId')
          .set({
        'userId': targetId,
        'username': targetUsername,
        'displayName': targetDisplayName,
        'blockedAt': DateTime.now().toIso8601String(),
      });
      if (cleanUname.isNotEmpty && cleanUname != cleanId) {
        await FirebaseDatabase.instance
            .ref('blocked_users/$_currentUserId/$cleanUname')
            .set({
          'userId': targetId,
          'username': targetUsername,
          'displayName': targetDisplayName,
          'blockedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firebase block user error: $e');
    }
    return null;
  }

  Future<void> unblockUser(String targetId, [String? targetUsername]) async {
    final cleanId = targetId.toLowerCase().trim();
    final cleanUname = targetUsername != null ? targetUsername.toLowerCase().trim() : '';

    _blockedUserIds.remove(cleanId);
    if (cleanUname.isNotEmpty) _blockedUserIds.remove(cleanUname);
    notifyListeners();

    if (_currentUserId == null) return;
    try {
      await FirebaseDatabase.instance
          .ref('blocked_users/$_currentUserId/$targetId')
          .remove();
      if (cleanUname.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref('blocked_users/$_currentUserId/$cleanUname')
            .remove();
      }
    } catch (e) {
      debugPrint('Firebase unblock user error: $e');
    }
  }

  String getConversationChannelId(String contactId) {
    if (contactId.startsWith('group_')) {
      return contactId;
    }
    String cleanId = contactId;
    while (cleanId.startsWith('chat_')) {
      cleanId = cleanId.substring(5);
    }
    cleanId = _normalizeIdentifier(cleanId);

    if (cleanId.contains('_')) {
      final parts = cleanId.split('_');
      if (parts.length >= 2) {
        final u1 = _normalizeIdentifier(resolveCanonicalId(parts[0]));
        final u2 = _normalizeIdentifier(resolveCanonicalId(parts[1]));
        final sorted = [u1, u2]..sort();
        return 'chat_${sorted[0]}_${sorted[1]}';
      }
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) return 'chat_$cleanId';

    final canonicalTarget = resolveCanonicalId(contactId);
    final normCurrent = _normalizeIdentifier(_currentUserId!);
    final normTarget = _normalizeIdentifier(canonicalTarget);

    final sorted = [normCurrent, normTarget]..sort();
    return 'chat_${sorted[0]}_${sorted[1]}';
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
    _unDeleteConversation(chatId);
    if (username != null) _unDeleteConversation(username);

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

    final canonicalId = resolveCanonicalId(chatId);
    _unDeleteConversation(canonicalId);
    _mergeMessageKeys(chatId, canonicalId);
    _mergeMessageKeys('usr_$chatId', canonicalId);
    _mergeMessageKeys('@$chatId', canonicalId);
    if (username != null) {
      _mergeMessageKeys(username, canonicalId);
      _mergeMessageKeys('usr_$username', canonicalId);
      _mergeMessageKeys('@$username', canonicalId);
    }

    _activeChatId = canonicalId;
    final contactIndex = _contacts.indexWhere(
      (c) => c.id == canonicalId || _normalizeIdentifier(c.username) == _normalizeIdentifier(username ?? chatId),
    );
    if (contactIndex != -1) {
      _contacts[contactIndex] = _contacts[contactIndex].copyWith(unreadCount: 0);
    } else {
      // Check if it's a pending friend request
      final req = _pendingFriendRequests.firstWhere(
        (r) => r.senderId == canonicalId || _normalizeIdentifier(r.senderUsername) == _normalizeIdentifier(username ?? chatId),
        orElse: () => FriendRequestModel(
          id: '',
          senderId: '',
          senderName: '',
          senderUsername: '',
          receiverId: '',
          receiverUsername: '',
          status: '',
          createdAt: DateTime.now(),
        ),
      );

      if (canonicalId.startsWith('chat_')) {
        // Do not add internal transport keys to _tempContacts
      } else if (req.id.isNotEmpty) {
        _tempContacts[canonicalId] = PrivateContactModel(
          id: canonicalId,
          displayName: req.senderName,
          username: req.senderUsername,
          isOnline: isUserOnline(canonicalId),
          lastSeenText: getUserLastSeen(canonicalId),
          unreadCount: 0,
          isPendingInvitation: true,
        );
      } else if (displayName != null || username != null) {
        _tempContacts[canonicalId] = PrivateContactModel(
          id: canonicalId,
          displayName: displayName ?? username ?? 'User',
          username: username ?? (chatId.startsWith('usr_') ? chatId.replaceFirst('usr_', '') : chatId),
          isOnline: isUserOnline(canonicalId),
          lastSeenText: getUserLastSeen(canonicalId),
          unreadCount: 0,
        );
      } else {
        _fetchUserForChatIfMissing(canonicalId);
      }
    }
    _subscribeToContactChat(canonicalId);
    _subscribeToContactPresence(canonicalId);
    _listenToTyping(canonicalId);
    Future.microtask(() {
      markMessagesAsSeen(canonicalId);
    });
    notifyListeners();
  }

  void setTypingStatus(String contactId, bool isTyping) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    if (_myTypingStatus[contactId] == isTyping) return;
    _myTypingStatus[contactId] = isTyping;
    final channelId = getConversationChannelId(contactId);
    try {
      final ref = FirebaseDatabase.instance.ref('typing/$channelId/$_currentUserId');
      if (isTyping) {
        ref.set({
          'isTyping': true,
          'username': _currentUsername ?? 'User',
          'displayName': _currentDisplayName ?? 'User',
          'timestamp': ServerValue.timestamp,
        });
      } else {
        ref.remove();
      }
    } catch (e) {
      debugPrint('Firebase typing update notice: $e');
    }
  }

  void _listenToTyping(String contactId) {
    final channelId = getConversationChannelId(contactId);
    if (_typingSubscriptions.containsKey(channelId)) return;
    try {
      final ref = FirebaseDatabase.instance.ref('typing/$channelId');
      _typingSubscriptions[channelId] = ref.onValue.listen((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          _typingUsers[contactId] = false;
          _typingUserNames.remove(contactId);
          notifyListeners();
          return;
        }
        bool anyoneElseTyping = false;
        String? typingName;
        if (event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          for (final entry in data.entries) {
            if (entry.key != _currentUserId && entry.value is Map) {
              final val = Map<String, dynamic>.from(entry.value as Map);
              if (val['isTyping'] == true) {
                anyoneElseTyping = true;
                typingName = val['displayName']?.toString() ?? val['username']?.toString();
                break;
              }
            }
          }
        }
        _typingUsers[contactId] = anyoneElseTyping;
        if (typingName != null) {
          _typingUserNames[contactId] = typingName;
        } else {
          _typingUserNames.remove(contactId);
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firebase typing listener notice: $e');
    }
  }

  Future<void> _fetchUserForChatIfMissing(String chatId) async {
    if (chatId.startsWith('chat_')) return;
    final cleanId = chatId.toLowerCase().trim();
    if (_deletedConversationIds.contains(cleanId)) return;
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
        final targetCanonical = resolveCanonicalId(_activeChatId!);
        final lowerTarget = targetCanonical.toLowerCase().trim();
        final lowerMe = _currentUserId!.toLowerCase().trim();

        // Write to recipient's recent_chats under their canonical ID
        FirebaseDatabase.instance.ref('users/$targetCanonical/recent_chats/$_currentUserId').set(dataForRecipient);
        if (lowerTarget != targetCanonical) {
          FirebaseDatabase.instance.ref('users/$lowerTarget/recent_chats/$_currentUserId').set(dataForRecipient);
        }
        if (lowerMe != _currentUserId) {
          FirebaseDatabase.instance.ref('users/$targetCanonical/recent_chats/$lowerMe').set(dataForRecipient);
          if (lowerTarget != targetCanonical) {
            FirebaseDatabase.instance.ref('users/$lowerTarget/recent_chats/$lowerMe').set(dataForRecipient);
          }
        }
        if (_activeChatId != targetCanonical && !_activeChatId!.startsWith('chat_')) {
          FirebaseDatabase.instance.ref('users/$_activeChatId/recent_chats/$_currentUserId').set(dataForRecipient);
        }
        if (myUname.isNotEmpty && myUname != _currentUserId) {
          FirebaseDatabase.instance.ref('users/$targetCanonical/recent_chats/$myUname').set(dataForRecipient);
          if (lowerTarget != targetCanonical) {
            FirebaseDatabase.instance.ref('users/$lowerTarget/recent_chats/$myUname').set(dataForRecipient);
          }
        }
        // If recipient has a distinct username, also write under users/$contactUname
        if (contactUname.isNotEmpty && contactUname != 'user' && contactUname != targetCanonical) {
          FirebaseDatabase.instance.ref('users/$contactUname/recent_chats/$_currentUserId').set(dataForRecipient);
          if (myUname.isNotEmpty && myUname != _currentUserId) {
            FirebaseDatabase.instance.ref('users/$contactUname/recent_chats/$myUname').set(dataForRecipient);
          }
        }

        // If it's a group, sync recent_chats to all group members
        if (activeContact?.isGroup == true && activeContact?.memberIds != null) {
          for (final memberId in activeContact!.memberIds) {
            if (memberId != _currentUserId) {
              FirebaseDatabase.instance.ref('users/$memberId/recent_chats/$_activeChatId').set({
                'lastMessage': lastText,
                'timestamp': nowIso,
                'senderId': _activeChatId,
                'senderName': contactName,
                'senderUsername': contactUname,
              });
            }
          }
        }

        // 2. Data for ME: shows the other user (activeContact) as my contact
        final dataForSender = {
          'lastMessage': lastText,
          'timestamp': nowIso,
          'senderId': targetCanonical,
          'senderName': contactName,
          'senderUsername': contactUname,
        };
        FirebaseDatabase.instance.ref('users/$_currentUserId/recent_chats/$targetCanonical').set(dataForSender);
        if (lowerMe != _currentUserId) {
          FirebaseDatabase.instance.ref('users/$lowerMe/recent_chats/$targetCanonical').set(dataForSender);
        }
        if (lowerTarget != targetCanonical) {
          FirebaseDatabase.instance.ref('users/$_currentUserId/recent_chats/$lowerTarget').set(dataForSender);
          if (lowerMe != _currentUserId) {
            FirebaseDatabase.instance.ref('users/$lowerMe/recent_chats/$lowerTarget').set(dataForSender);
          }
        }
        if (_activeChatId != targetCanonical && !_activeChatId!.startsWith('chat_')) {
          FirebaseDatabase.instance.ref('users/$_currentUserId/recent_chats/$_activeChatId').set(dataForSender);
        }
        if (myUname.isNotEmpty && myUname != _currentUserId) {
          FirebaseDatabase.instance.ref('users/$myUname/recent_chats/$targetCanonical').set(dataForSender);
        }
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
      if (c.id.toLowerCase().trim() == cleanActive ||
          c.username.toLowerCase().trim() == cleanActive ||
          _normalizeIdentifier(c.username) == _normalizeIdentifier(cleanActive)) {
        return true;
      }
    }
    final canonical = resolveCanonicalId(_activeChatId!);
    final cleanCanonical = canonical.toLowerCase().trim();
    if (cleanCanonical != cleanActive) {
      if (_sentRequestStatuses[cleanCanonical] == 'accepted') return true;
      for (final c in _contacts) {
        if (c.id.toLowerCase().trim() == cleanCanonical ||
            c.username.toLowerCase().trim() == cleanCanonical ||
            _normalizeIdentifier(c.username) == _normalizeIdentifier(cleanCanonical)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns true if current user has already sent a cold DM (before friendship or any response).
  bool get coldDmLimitReached {
    if (_activeChatId == null || _currentUserId == null) return false;
    if (_activeChatId!.startsWith('group_')) return false;
    if (isActiveChatFriend) return false;
    final activeC = activeContact;
    if (activeC != null && isContact(activeC.id, activeC.username)) {
      return false;
    }
    final msgs = activeMessages;
    // If the other user has replied or sent any message, this is a mutual conversation — NEVER block
    final hasOtherReplies = msgs.any((m) => !isMyMessage(m));
    if (hasOtherReplies) return false;

    // Count how many messages the CURRENT user has sent in this chat
    final myMsgCount = msgs.where((m) => isMyMessage(m)).length;
    return myMsgCount >= 1;
  }

  void sendTextMessage(String text, {String? replyToText}) {
    if (text.trim().isEmpty || _activeChatId == null) return;
    _unDeleteConversation(_activeChatId!);
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

    String msgType = 'text';
    String finalContent = text.trim();

    if (finalContent.toLowerCase().startsWith('/urgent ')) {
      msgType = 'urgent';
      finalContent = finalContent.substring(8).trim();
    } else if (finalContent.toLowerCase().startsWith('/redact ') ||
        finalContent.toLowerCase().startsWith('/redacted ')) {
      msgType = 'redacted';
      final isShort = finalContent.toLowerCase().startsWith('/redact ');
      finalContent = finalContent.substring(isShort ? 8 : 10).trim();
    }

    final senderId = _currentUserId ?? 'me';
    final senderName = _currentDisplayName ?? _currentUsername ?? 'User';
    final channelId = getConversationChannelId(_activeChatId!);
    final isRecipientOnline = activeContact?.isOnline == true;
    final initialStatus = isRecipientOnline ? 'delivered' : 'sent';

    final newMsg = PrivateMessageModel(
      id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: channelId,
      senderId: senderId,
      senderName: senderName,
      type: msgType,
      text: finalContent,
      replyToText: replyToText,
      createdAt: DateTime.now(),
      status: initialStatus,
    );

    final canonicalId = resolveCanonicalId(_activeChatId!);
    _messages.putIfAbsent(_activeChatId!, () => []).add(newMsg);
    if (canonicalId != _activeChatId!) {
      _messages.putIfAbsent(canonicalId, () => []).add(newMsg);
    }
    if (channelId != _activeChatId! && channelId != canonicalId) {
      _messages.putIfAbsent(channelId, () => []).add(newMsg);
    }
    notifyListeners();
    _syncMessageToFirebase(newMsg, channelId);
  }

  void editTextMessage(String messageId, String newText) {
    if (newText.trim().isEmpty) return;
    bool updatedAny = false;
    PrivateMessageModel? updatedMsg;
    String? channelId;

    for (final list in _messages.values) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final msg = list[idx];
        if (msg.type != 'text' && msg.type != 'urgent' && msg.type != 'redacted') return;
        if (DateTime.now().difference(msg.createdAt).inMinutes >= 15) return;
        final updated = msg.copyWith(
          text: newText.trim(),
          isEdited: true,
        );
        list[idx] = updated;
        updatedAny = true;
        updatedMsg = updated;
        if (channelId == null || channelId.isEmpty) {
          channelId = getConversationChannelId(msg.chatId.isNotEmpty ? msg.chatId : (_activeChatId ?? ''));
        }
      }
    }

    if (updatedAny && updatedMsg != null) {
      notifyListeners();
      if (channelId != null && channelId.isNotEmpty) {
        _syncMessageToFirebase(updatedMsg, channelId);
      }
    }
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
    _unDeleteConversation(_activeChatId!);
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
    final isRecipientOnline = activeContact?.isOnline == true;
    final initialStatus = isRecipientOnline ? 'delivered' : 'sent';

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
      status: initialStatus,
    );

    final canonicalId = resolveCanonicalId(_activeChatId!);
    _messages.putIfAbsent(_activeChatId!, () => []).add(newMsg);
    if (canonicalId != _activeChatId!) {
      _messages.putIfAbsent(canonicalId, () => []).add(newMsg);
    }
    if (channelId != _activeChatId! && channelId != canonicalId) {
      _messages.putIfAbsent(channelId, () => []).add(newMsg);
    }
    notifyListeners();
    _syncMessageToFirebase(newMsg, channelId);
  }

  void editMessage(String messageId, String newText) {
    editTextMessage(messageId, newText);
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

  Future<void> _syncGroupToAllMembers(PrivateContactModel group) async {
    try {
      for (final mId in group.memberIds) {
        await FirebaseDatabase.instance
            .ref('users/$mId/contacts/${group.id}')
            .set(group.toJson());
      }
    } catch (e) {
      debugPrint('Error syncing group chat to Firebase: $e');
    }
  }

  Future<String?> createGroupChat({
    required String groupName,
    required List<String> memberIds,
    String? groupBio,
    String? avatarUrl,
  }) async {
    if (_currentUserId == null) return null;
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final allMembers = <String>{...memberIds, _currentUserId!}.toList();

    final groupContact = PrivateContactModel(
      id: groupId,
      displayName: groupName.trim(),
      username: 'group_$groupId',
      isGroup: true,
      avatarUrl: avatarUrl,
      groupBio: groupBio?.trim(),
      memberIds: allMembers,
      ownerId: _currentUserId,
      adminIds: [_currentUserId!],
      settingsPermission: 'admins_only',
    );

    _contacts.add(groupContact);
    _subscribeToContactChat(groupId);
    setActiveChat(groupId, displayName: groupName.trim(), username: 'group_$groupId');
    notifyListeners();

    await _syncGroupToAllMembers(groupContact);
    return groupId;
  }

  Future<void> updateGroupDetails({
    required String groupId,
    String? groupName,
    String? groupBio,
    String? avatarUrl,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final updated = current.copyWith(
      displayName: groupName != null && groupName.trim().isNotEmpty ? groupName.trim() : current.displayName,
      groupBio: groupBio ?? current.groupBio,
      avatarUrl: avatarUrl ?? current.avatarUrl,
    );
    _contacts[idx] = updated;
    notifyListeners();
    await _syncGroupToAllMembers(updated);
  }

  Future<void> updateGroupSettingsPermission({
    required String groupId,
    required String permission,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final updated = _contacts[idx].copyWith(settingsPermission: permission);
    _contacts[idx] = updated;
    notifyListeners();
    await _syncGroupToAllMembers(updated);
  }

  Future<void> setGroupAdmin({
    required String groupId,
    required String memberId,
    required bool isAdmin,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final currentAdmins = List<String>.from(current.adminIds);
    if (isAdmin && !currentAdmins.contains(memberId)) {
      currentAdmins.add(memberId);
    } else if (!isAdmin) {
      currentAdmins.remove(memberId);
    }

    final updated = current.copyWith(adminIds: currentAdmins);
    _contacts[idx] = updated;
    notifyListeners();
    await _syncGroupToAllMembers(updated);
  }

  Future<void> transferGroupOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final currentAdmins = List<String>.from(current.adminIds);
    if (!currentAdmins.contains(newOwnerId)) {
      currentAdmins.add(newOwnerId);
    }

    final updated = current.copyWith(
      ownerId: newOwnerId,
      adminIds: currentAdmins,
    );
    _contacts[idx] = updated;
    notifyListeners();
    await _syncGroupToAllMembers(updated);
  }

  Future<void> assignMemberRole({
    required String groupId,
    required String memberId,
    String? role,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final currentRoles = Map<String, String>.from(current.memberRoles);
    if (role != null && role.trim().isNotEmpty) {
      currentRoles[memberId] = role.trim();
    } else {
      currentRoles.remove(memberId);
    }

    final updated = current.copyWith(memberRoles: currentRoles);
    _contacts[idx] = updated;
    notifyListeners();
    await _syncGroupToAllMembers(updated);
  }

  Future<void> addMembersToGroup({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final mergedMembers = <String>{...current.memberIds, ...memberIds}.toList();
    final updated = current.copyWith(memberIds: mergedMembers);
    _contacts[idx] = updated;
    notifyListeners();
    await _syncGroupToAllMembers(updated);
  }

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final currentMembers = List<String>.from(current.memberIds)..remove(memberId);
    final currentAdmins = List<String>.from(current.adminIds)..remove(memberId);
    final currentRoles = Map<String, String>.from(current.memberRoles)..remove(memberId);

    final updated = current.copyWith(
      memberIds: currentMembers,
      adminIds: currentAdmins,
      memberRoles: currentRoles,
    );
    _contacts[idx] = updated;
    notifyListeners();

    try {
      await FirebaseDatabase.instance
          .ref('users/$memberId/contacts/$groupId')
          .remove();
    } catch (_) {}

    await _syncGroupToAllMembers(updated);
  }

  Future<void> leaveGroup({required String groupId}) async {
    if (_currentUserId == null) return;
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    if (idx == -1) return;

    final current = _contacts[idx];
    final remainingMembers = List<String>.from(current.memberIds)..remove(_currentUserId);

    if (remainingMembers.isEmpty) {
      await deleteGroup(groupId: groupId);
      return;
    }

    String? newOwner = current.ownerId;
    if (current.isOwner(_currentUserId)) {
      newOwner = current.adminIds.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => remainingMembers.first,
      );
    }

    final updatedAdmins = List<String>.from(current.adminIds)..remove(_currentUserId);
    if (newOwner != null && !updatedAdmins.contains(newOwner)) {
      updatedAdmins.add(newOwner);
    }
    final updatedRoles = Map<String, String>.from(current.memberRoles)..remove(_currentUserId);

    final updated = current.copyWith(
      memberIds: remainingMembers,
      ownerId: newOwner,
      adminIds: updatedAdmins,
      memberRoles: updatedRoles,
    );

    _contacts.removeAt(idx);
    if (_activeChatId == groupId) {
      _activeChatId = null;
    }
    notifyListeners();

    try {
      await FirebaseDatabase.instance
          .ref('users/$_currentUserId/contacts/$groupId')
          .remove();
    } catch (_) {}

    await _syncGroupToAllMembers(updated);
  }

  Future<void> deleteGroup({required String groupId}) async {
    final idx = _contacts.indexWhere((c) => c.id == groupId && c.isGroup);
    final members = idx != -1 ? List<String>.from(_contacts[idx].memberIds) : <String>[];

    _contacts.removeWhere((c) => c.id == groupId);
    _messages.remove(groupId);
    if (_activeChatId == groupId) {
      _activeChatId = null;
    }
    notifyListeners();

    final channelId = getConversationChannelId(groupId);
    try {
      await FirebaseDatabase.instance.ref('chats/$channelId').remove();
      for (final mId in members) {
        await FirebaseDatabase.instance
            .ref('users/$mId/contacts/$groupId')
            .remove();
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
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
    deleteConversation(_activeChatId!);
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

    final cleanWithoutAt = clean.startsWith('@') ? clean.substring(1).trim() : clean;

    final results = <Map<String, String>>[];
    final seenUsernames = <String>{};
    final seenIds = <String>{};

    try {
      final snap = await FirebaseDatabase.instance.ref('users').get();
      if (snap.exists && snap.value is Map) {
        final rawMap = Map<String, dynamic>.from(snap.value as Map);
        for (var entry in rawMap.entries) {
          if (entry.value is Map) {
            final u = Map<String, dynamic>.from(entry.value as Map);
            final uname = (u['username'] ?? '').toString().trim().toLowerCase();
            final email = (u['email'] ?? '').toString().trim().toLowerCase();
            final name = (u['displayName'] ?? u['name'] ?? '').toString().trim();
            final id = (u['id'] ?? entry.key).toString().trim();
            final avatarUrl = (u['avatarUrl'] ?? u['photoUrl'] ?? '').toString();

            // A valid user MUST have a non-empty username
            if (uname.isEmpty) {
              continue;
            }

            // Exclude system nodes or ghost keys
            final keyLower = entry.key.toLowerCase();
            final idLower = id.toLowerCase();
            if (idLower.startsWith('chat_') ||
                keyLower.startsWith('chat_') ||
                keyLower == 'contacts' ||
                keyLower == 'recent_chats' ||
                keyLower == 'blocked_users' ||
                keyLower == 'friend_requests' ||
                keyLower == 'invitations' ||
                keyLower == 'messages') {
              continue;
            }

            // Exclude current user from search results to prevent self-friend requests
            if ((_currentUserId != null && _currentUserId!.isNotEmpty && id == _currentUserId) ||
                (_currentUsername != null && _currentUsername!.isNotEmpty && uname == _currentUsername?.toLowerCase()) ||
                (_currentUserEmail != null && _currentUserEmail!.isNotEmpty && email == _currentUserEmail?.toLowerCase())) {
              continue;
            }

            // Deduplicate search results by username and id
            if (seenUsernames.contains(uname) || (id.isNotEmpty && seenIds.contains(id))) {
              continue;
            }

            final matchesUname = uname.contains(clean) || (cleanWithoutAt.isNotEmpty && uname.contains(cleanWithoutAt));
            final matchesEmail = email.contains(clean);
            final matchesName = name.toLowerCase().contains(clean) || (cleanWithoutAt.isNotEmpty && name.toLowerCase().contains(cleanWithoutAt));

            if (matchesUname || matchesEmail || matchesName) {
              seenUsernames.add(uname);
              if (id.isNotEmpty) seenIds.add(id);

              results.add({
                'id': id,
                'name': name.isEmpty ? uname : name,
                'username': uname,
                'email': email,
                'avatarUrl': avatarUrl,
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

    final safeSenderId = sanitizeDbKey(senderId);
    final safeTargetId = sanitizeDbKey(targetId);
    final safeTargetUsername = sanitizeDbKey(targetUsername);
    final lowerTargetId = safeTargetId.toLowerCase().trim();
    final lowerTargetUsername = safeTargetUsername.toLowerCase().trim();
    final requestId = 'req_${safeSenderId}_$safeTargetId';
    final lowerRequestId = 'req_${safeSenderId.toLowerCase().trim()}_$lowerTargetId';

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

    // Write to Firebase Realtime Database under target user's real ID AND username (multi-case support)
    try {
      final reqJson = request.toJson();
      await FirebaseDatabase.instance
          .ref('friend_requests/$safeTargetId/$requestId')
          .set(reqJson);
      if (lowerTargetId != safeTargetId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$lowerTargetId/$requestId')
            .set(reqJson);
      }
      if (lowerRequestId != requestId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$safeTargetId/$lowerRequestId')
            .set(reqJson);
        if (lowerTargetId != safeTargetId) {
          await FirebaseDatabase.instance
              .ref('friend_requests/$lowerTargetId/$lowerRequestId')
              .set(reqJson);
        }
      }
      if (safeTargetUsername != safeTargetId && safeTargetUsername != lowerTargetId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$safeTargetUsername/$requestId')
            .set(reqJson);
      }
      if (lowerTargetUsername != safeTargetUsername &&
          lowerTargetUsername != safeTargetId &&
          lowerTargetUsername != lowerTargetId) {
        await FirebaseDatabase.instance
            .ref('friend_requests/$lowerTargetUsername/$requestId')
            .set(reqJson);
      }
      if (clean.contains('@')) {
        final safeCleanEmail = sanitizeDbKey(clean);
        if (safeCleanEmail != safeTargetId &&
            safeCleanEmail != safeTargetUsername &&
            safeCleanEmail != lowerTargetId) {
          await FirebaseDatabase.instance
              .ref('friend_requests/$safeCleanEmail/$requestId')
              .set(reqJson);
        }
      }
      // Also write to sender's sent_requests node so status persists on reopen
      if (_currentUserId != null) {
        final sentData = {
          'requestId': requestId,
          'targetId': targetId,
          'targetUsername': targetUsername,
          'targetDisplayName': targetDisplayName,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        };
        await FirebaseDatabase.instance
            .ref('sent_requests/$_currentUserId/$requestId')
            .set(sentData);
        final lowerCurrentUserId = _currentUserId!.toLowerCase().trim();
        if (lowerCurrentUserId != _currentUserId) {
          await FirebaseDatabase.instance
              .ref('sent_requests/$lowerCurrentUserId/$requestId')
              .set(sentData);
        }
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
    final lowerReceiverId = safeReceiverId.toLowerCase().trim();
    final safeReceiverUsername = sanitizeDbKey(req.receiverUsername);
    final lowerReceiverUsername = safeReceiverUsername.toLowerCase().trim();
    final safeSenderId = sanitizeDbKey(req.senderId);
    final lowerSenderId = safeSenderId.toLowerCase().trim();
    final deterministicId = 'req_${safeSenderId}_$safeReceiverId';
    final lowerDeterministicId = 'req_${lowerSenderId}_$lowerReceiverId';

    try {
      // Remove friend request node from receiver across all case variants
      final pathsToRemove = <String>{
        'friend_requests/$safeReceiverId/${req.id}',
        'friend_requests/$lowerReceiverId/${req.id}',
        'friend_requests/$safeReceiverUsername/${req.id}',
        'friend_requests/$lowerReceiverUsername/${req.id}',
        'friend_requests/$safeReceiverId/$deterministicId',
        'friend_requests/$lowerReceiverId/$deterministicId',
        'friend_requests/$safeReceiverUsername/$deterministicId',
        'friend_requests/$lowerReceiverUsername/$deterministicId',
        'friend_requests/$safeReceiverId/$lowerDeterministicId',
        'friend_requests/$lowerReceiverId/$lowerDeterministicId',
        'friend_requests/$safeReceiverUsername/$lowerDeterministicId',
        'friend_requests/$lowerReceiverUsername/$lowerDeterministicId',
      };
      for (final p in pathsToRemove) {
        await FirebaseDatabase.instance.ref(p).remove();
      }

      // Update status in the SENDER's sent_requests node so their UI updates in real-time
      final sentPathsToUpdate = <String>{
        'sent_requests/$safeSenderId/${req.id}',
        'sent_requests/$lowerSenderId/${req.id}',
        'sent_requests/$safeSenderId/$deterministicId',
        'sent_requests/$lowerSenderId/$deterministicId',
        'sent_requests/$safeSenderId/$lowerDeterministicId',
        'sent_requests/$lowerSenderId/$lowerDeterministicId',
      };
      for (final p in sentPathsToUpdate) {
        await FirebaseDatabase.instance.ref(p).update({'status': status});
      }
    } catch (e) {
      debugPrint('Firebase respond to request error: $e');
    }

    // Remove ALL requests matching this sender ID or username from pending requests
    _pendingFriendRequests.removeWhere((r) =>
        r.id == req.id ||
        (req.senderId.isNotEmpty && r.senderId == req.senderId) ||
        (_normalizeIdentifier(req.senderUsername).isNotEmpty &&
            _normalizeIdentifier(r.senderUsername) == _normalizeIdentifier(req.senderUsername)));

    _sentRequestStatuses[req.senderId.toLowerCase().trim()] = status;
    _sentRequestStatuses[req.senderUsername.toLowerCase().trim()] = status;
    _tempContacts.remove(req.senderId);
    _tempContacts.remove(req.senderUsername);
    _tempContacts.remove('usr_${req.senderUsername}');
    _tempContacts.remove('@${req.senderUsername}');
    _tempContacts.remove(_normalizeIdentifier(req.senderUsername));

    if (accept) {
      _unDeleteConversation(req.senderId);
      _unDeleteConversation(req.senderUsername);
      final newContact = PrivateContactModel(
        id: req.senderId,
        displayName: req.senderName,
        username: req.senderUsername,
        isOnline: isUserOnline(req.senderId),
        lastSeenText: getUserLastSeen(req.senderId),
        unreadCount: 0,
      );
      final existingIndex = _contacts.indexWhere(
        (c) => c.id == req.senderId || _normalizeIdentifier(c.username) == _normalizeIdentifier(req.senderUsername),
      );
      if (existingIndex != -1) {
        _contacts[existingIndex] = newContact;
      } else {
        _contacts.insert(0, newContact);
      }

      // Merge messages from all possible keys into canonical UID
      _mergeMessageKeys(req.senderUsername, req.senderId);
      _mergeMessageKeys('usr_${req.senderUsername}', req.senderId);
      _mergeMessageKeys('@${req.senderUsername}', req.senderId);
      _mergeMessageKeys(_normalizeIdentifier(req.senderUsername), req.senderId);

      // Point activeChatId to canonical UID if it was username
      if (_activeChatId == req.senderUsername ||
          _activeChatId == 'usr_${req.senderUsername}' ||
          _activeChatId == '@${req.senderUsername}' ||
          _activeChatId == _normalizeIdentifier(req.senderUsername)) {
        _activeChatId = req.senderId;
      }

      _subscribeToContactPresence(req.senderId);
      _subscribeToContactChat(req.senderId);

      if (_currentUserId != null) {
        try {
          final curUid = _currentUserId!;
          final lowerCurUid = curUid.toLowerCase().trim();
          final senderId = req.senderId;
          final lowerSenderId = senderId.toLowerCase().trim();

          // 1. Add sender to receiver's contacts
          await FirebaseDatabase.instance
              .ref('users/$curUid/contacts/$senderId')
              .set(newContact.toJson());
          if (lowerCurUid != curUid) {
            await FirebaseDatabase.instance
                .ref('users/$lowerCurUid/contacts/$senderId')
                .set(newContact.toJson());
          }
          if (lowerSenderId != senderId) {
            await FirebaseDatabase.instance
                .ref('users/$curUid/contacts/$lowerSenderId')
                .set(newContact.toJson());
            if (lowerCurUid != curUid) {
              await FirebaseDatabase.instance
                  .ref('users/$lowerCurUid/contacts/$lowerSenderId')
                  .set(newContact.toJson());
            }
          }

          // 2. Also add receiver to sender's contacts (fetch receiver's display name)
          String receiverDisplayName = req.receiverUsername;
          try {
            final receiverSnap = await FirebaseDatabase.instance.ref('users/$curUid').get();
            if (receiverSnap.exists && receiverSnap.value is Map) {
              final data = Map<String, dynamic>.from(receiverSnap.value as Map);
              receiverDisplayName = data['displayName']?.toString() ?? req.receiverUsername;
            }
          } catch (_) {}

          final receiverContact = PrivateContactModel(
            id: curUid,
            displayName: receiverDisplayName,
            username: req.receiverUsername,
            isOnline: _showOnlineStatus && _isAppForeground,
            lastSeenText: (_showOnlineStatus && _isAppForeground) ? 'Online' : 'Active recently',
            unreadCount: 0,
          );
          await FirebaseDatabase.instance
              .ref('users/$senderId/contacts/$curUid')
              .set(receiverContact.toJson());
          if (lowerSenderId != senderId) {
            await FirebaseDatabase.instance
                .ref('users/$lowerSenderId/contacts/$curUid')
                .set(receiverContact.toJson());
          }
          if (lowerCurUid != curUid) {
            await FirebaseDatabase.instance
                .ref('users/$senderId/contacts/$lowerCurUid')
                .set(receiverContact.toJson());
            if (lowerSenderId != senderId) {
              await FirebaseDatabase.instance
                  .ref('users/$lowerSenderId/contacts/$lowerCurUid')
                  .set(receiverContact.toJson());
            }
          }
        } catch (e) {
          debugPrint('Firebase contact write error on accept: $e');
        }
      }
    }
    notifyListeners();
  }

  /// Delete an entire conversation directly from the sidebar or settings
  Future<void> deleteConversation(String contactId) async {
    final cleanId = contactId.trim();
    if (cleanId.isEmpty) return;

    final canonicalId = resolveCanonicalId(cleanId);
    final channelId = getConversationChannelId(cleanId);

    // Find contact to get username
    final contact = getContact(cleanId);
    final uname = contact?.username ?? '';
    final normUname = _normalizeIdentifier(uname);

    final allKeysToRemove = <String>{
      cleanId,
      cleanId.toLowerCase(),
      canonicalId,
      canonicalId.toLowerCase(),
      channelId,
      channelId.toLowerCase(),
      if (uname.isNotEmpty) uname,
      if (uname.isNotEmpty) uname.toLowerCase(),
      if (normUname.isNotEmpty) normUname,
      if (normUname.isNotEmpty) 'usr_$normUname',
      if (normUname.isNotEmpty) '@$normUname',
    };

    // 1. In-memory cleanup IMMEDIATELY (synchronously)
    for (final k in allKeysToRemove) {
      _deletedConversationIds.add(k.toLowerCase().trim());
      _messages.remove(k);
      _tempContacts.remove(k);
    }
    _contacts.removeWhere((c) =>
        allKeysToRemove.contains(c.id) ||
        allKeysToRemove.contains(c.id.toLowerCase()) ||
        allKeysToRemove.contains(c.username) ||
        allKeysToRemove.contains(c.username.toLowerCase()) ||
        allKeysToRemove.contains(_normalizeIdentifier(c.username)));

    // Also remove from pending friend requests if any
    _pendingFriendRequests.removeWhere((r) =>
        allKeysToRemove.contains(r.senderId) ||
        allKeysToRemove.contains(r.senderId.toLowerCase()) ||
        allKeysToRemove.contains(r.senderUsername) ||
        allKeysToRemove.contains(r.senderUsername.toLowerCase()) ||
        allKeysToRemove.contains(_normalizeIdentifier(r.senderUsername)) ||
        allKeysToRemove.contains(r.id));

    // Cancel active stream subscription for this channel
    final sub = _channelSubscriptions.remove(channelId);
    sub?.cancel();

    if (_activeChatId != null && allKeysToRemove.contains(_activeChatId!)) {
      _activeChatId = null;
    }

    notifyListeners();

    // 2. Persist to local storage so it stays deleted on app reopen
    await _persistDeletedConversations();

    // 3. Remove from Firebase Realtime Database across ALL casing variants
    if (_currentUserId != null) {
      final curUid = sanitizeDbKey(_currentUserId!);
      final lowerCurUid = curUid.toLowerCase().trim();
      final curUname = _currentUsername != null ? sanitizeDbKey(_currentUsername!) : '';
      final lowerCurUname = curUname.toLowerCase().trim();

      final userNodesToClean = <String>{
        curUid,
        if (lowerCurUid != curUid) lowerCurUid,
        if (curUname.isNotEmpty) curUname,
        if (lowerCurUname.isNotEmpty && lowerCurUname != curUname) lowerCurUname,
      };

      try {
        for (final uKey in userNodesToClean) {
          for (final k in allKeysToRemove) {
            final safeK = sanitizeDbKey(k);
            await FirebaseDatabase.instance.ref('users/$uKey/recent_chats/$safeK').remove();
            await FirebaseDatabase.instance.ref('users/$uKey/contacts/$safeK').remove();
          }
          // Remove from friend_requests for this user
          final fReqSnap = await FirebaseDatabase.instance.ref('friend_requests/$uKey').get();
          if (fReqSnap.exists && fReqSnap.value is Map) {
            final raw = Map<String, dynamic>.from(fReqSnap.value as Map);
            for (final entry in raw.entries) {
              if (entry.value is Map) {
                final rData = Map<String, dynamic>.from(entry.value as Map);
                final sId = (rData['senderId'] ?? '').toString();
                final sUname = (rData['senderUsername'] ?? '').toString();
                if (allKeysToRemove.contains(sId) ||
                    allKeysToRemove.contains(sId.toLowerCase()) ||
                    allKeysToRemove.contains(sUname) ||
                    allKeysToRemove.contains(sUname.toLowerCase()) ||
                    allKeysToRemove.contains(_normalizeIdentifier(sUname)) ||
                    allKeysToRemove.contains(entry.key)) {
                  await FirebaseDatabase.instance.ref('friend_requests/$uKey/${entry.key}').remove();
                }
              }
            }
          }
        }
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
    deleteImageMessage(msg);
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
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _setMyPresenceOffline();
    for (var sub in _channelSubscriptions.values) {
      sub.cancel();
    }
    _channelSubscriptions.clear();
    _clearAllSubscriptions();
    super.dispose();
  }
}

