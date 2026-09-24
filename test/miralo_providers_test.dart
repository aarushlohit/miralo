import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miralo/models/friend_request_model.dart';
import 'package:miralo/models/user_model.dart';
import 'package:miralo/models/private_contact_model.dart';
import 'package:miralo/models/library_item_model.dart';
import 'package:miralo/providers/vault_provider.dart';
import 'package:miralo/providers/ai_chat_provider.dart';
import 'package:miralo/providers/private_chat_provider.dart';
import 'package:miralo/providers/library_provider.dart';
import 'package:miralo/providers/auth_provider.dart';
import 'package:miralo/services/ai_service.dart';
import 'package:miralo/services/download_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VaultProvider Tests', () {
    test('Independent vault unlock and lock credentials', () async {
      final vault = VaultProvider();
      vault.setPrivateChatSecret('1234');
      vault.setLibraryPin('1234');

      // Initial state: locked
      expect(vault.isPrivateUnlocked, isFalse);
      expect(vault.isLibraryUnlocked, isFalse);

      // Incorrect secret fails
      final wrongChat = vault.unlockPrivate('9999');
      expect(wrongChat, isFalse);
      expect(vault.isPrivateUnlocked, isFalse);

      // Correct secret succeeds
      final correctChat = vault.unlockPrivate('1234');
      expect(correctChat, isTrue);
      expect(vault.isPrivateUnlocked, isTrue);
      // Library is still locked (independent)
      expect(vault.isLibraryUnlocked, isFalse);

      // Correct library PIN succeeds
      final correctLib = vault.unlockLibrary('1234');
      expect(correctLib, isTrue);
      expect(vault.isLibraryUnlocked, isTrue);

      // Lock private chat only
      vault.lockPrivate();
      expect(vault.isPrivateUnlocked, isFalse);
      expect(vault.isLibraryUnlocked, isTrue);

      // Emergency lock all
      vault.lockAll();
      expect(vault.isPrivateUnlocked, isFalse);
      expect(vault.isLibraryUnlocked, isFalse);
    });

    test('Hide mode state toggle', () {
      final vault = VaultProvider();
      expect(vault.hideMode.isEnabled, isFalse);

      vault.updateHideMode(isEnabled: true);
      expect(vault.hideMode.isEnabled, isTrue);

      vault.updateHideMode(isEnabled: false);
      expect(vault.hideMode.isEnabled, isFalse);
    });

    test('Drops nonexistent username intruder attempts and scopes to specific target account', () async {
      final vault = VaultProvider();

      // 1. Wrong/non-existent username is dropped:
      await vault.recordLoginIntruderAttempt(2, targetUserId: null);
      await vault.recordLoginIntruderAttempt(2, targetUserId: '');
      expect(vault.intruderLogs.isEmpty, isTrue);

      // 2. Existing user 'aarush' with wrong password records intruder log for 'aarush':
      await vault.recordLoginIntruderAttempt(
        2,
        targetUserId: 'usr_aarush_123',
        targetUsername: 'aarush',
      );

      // If active session is test2, test2 sees 0 intruder logs
      await vault.attachUser('usr_test2_456');
      expect(vault.intruderLogs.isEmpty, isTrue);

      // When aarush logs in, aarush sees the intruder log
      await vault.attachUser('usr_aarush_123');
      // Set in memory to simulate active user session match
      await vault.recordLoginIntruderAttempt(
        2,
        targetUserId: 'usr_aarush_123',
        targetUsername: 'aarush',
      );
      expect(vault.intruderLogs.isNotEmpty, isTrue);
      expect(vault.intruderLogs.last.userId, 'usr_aarush_123');
      expect(vault.intruderLogs.last.targetUsername, 'aarush');

      // Dismissing alert clears the logs
      await vault.clearIntruderLogs();
      expect(vault.intruderLogs.isEmpty, isTrue);
    });

    test('Cryptographic salted hashing and passcode verification', () async {
      final vault = VaultProvider();
      const testUid = 'user_test_salt_123';
      await vault.attachUser(testUid);

      await vault.setPrivateChatSecret('mySecretPass123');
      await vault.setLibraryPin('9876');

      expect(vault.hasPrivateSecret, isTrue);
      expect(vault.hasLibraryPin, isTrue);

      // Verify passcode checks salted hash
      expect(vault.verifyPasscode('mySecretPass123'), isTrue);
      expect(vault.verifyPasscode('wrongSecret'), isFalse);

      // Verify library PIN checks salted hash
      expect(vault.verifyLibraryPin('9876'), isTrue);
      expect(vault.verifyLibraryPin('0000'), isFalse);

      // Async unlock verifies correctly
      final privateOk = await vault.unlockPrivateAsync('mySecretPass123');
      expect(privateOk, isTrue);
      expect(vault.isPrivateUnlocked, isTrue);

      final libOk = await vault.unlockLibraryAsync('9876');
      expect(libOk, isTrue);
      expect(vault.isLibraryUnlocked, isTrue);
    });
  });

  group('AiChatProvider Tests', () {
    test('Sends user message and updates active conversation', () async {
      final aiProvider = AiChatProvider();

      final initialChat = aiProvider.pinnedChats.first;
      aiProvider.openChat(initialChat.id);

      expect(aiProvider.activeChat, isNotNull);
      final initialCount = aiProvider.activeChat!.messages.length;

      // Send prompt
      final sendFuture = aiProvider.sendPrompt('Explain quantum computing');
      expect(aiProvider.activeChat!.messages.length, greaterThan(initialCount));
      expect(aiProvider.activeChat!.messages.any((m) => m.text == 'Explain quantum computing'), isTrue);

      await sendFuture;
      expect(aiProvider.isStreaming, isFalse);
    }, timeout: const Timeout(Duration(seconds: 90)));

    test('Toggles thumbs feedback on AI messages', () {
      final aiProvider = AiChatProvider();
      final initialChat = aiProvider.pinnedChats.first;
      aiProvider.openChat(initialChat.id);

      final aiMessage = aiProvider.activeChat!.messages.firstWhere((m) => m.role == 'assistant');
      expect(aiMessage.liked, isNotNull); // seeded with true

      aiProvider.likeMessage(aiMessage.id, true); // toggle off
      final updatedMsg = aiProvider.activeChat!.messages.firstWhere((m) => m.id == aiMessage.id);
      expect(updatedMsg.liked, isNull);
    });
  });

  group('PrivateChatProvider Tests', () {
    test('Sends private message and updates active chat', () async {
      final chatProvider = PrivateChatProvider();
      final req = FriendRequestModel(
        id: 'req_test_01',
        senderId: 'usr_test_01',
        senderName: 'Test User',
        senderUsername: 'test_user',
        receiverId: 'usr_test_02',
        receiverUsername: 'receiver_user',
        createdAt: DateTime.now(),
      );
      await chatProvider.respondToFriendRequest(req, true);
      final contact = chatProvider.contacts.first;
      chatProvider.setActiveChat(contact.id);

      final initialMsgCount = chatProvider.activeMessages.length;
      chatProvider.sendTextMessage('Hey there, are we still on?');

      expect(chatProvider.activeMessages.length, initialMsgCount + 1);
      expect(chatProvider.activeMessages.last.text, 'Hey there, are we still on?');
      expect(chatProvider.activeMessages.last.isMe, isTrue);
    });

    test('Toggles emoji reaction on private message', () async {
      final chatProvider = PrivateChatProvider();
      final req = FriendRequestModel(
        id: 'req_test_02',
        senderId: 'usr_test_01',
        senderName: 'Test User',
        senderUsername: 'test_user',
        receiverId: 'usr_test_02',
        receiverUsername: 'receiver_user',
        createdAt: DateTime.now(),
      );
      await chatProvider.respondToFriendRequest(req, true);
      final contact = chatProvider.contacts.first;
      chatProvider.setActiveChat(contact.id);

      chatProvider.sendTextMessage('Let us test emoji reaction');
      final firstMsg = chatProvider.activeMessages.first;
      expect(firstMsg.reactions.containsKey('❤️'), isFalse);

      chatProvider.toggleReaction(firstMsg.id, '❤️');
      final afterReaction = chatProvider.activeMessages.firstWhere((m) => m.id == firstMsg.id);
      expect(afterReaction.reactions.containsKey('❤️'), isTrue);
      expect(afterReaction.reactions['❤️'], 1);
    });

    test('allChatImages aggregates media across chats and supports Move to Vault', () async {
      final chatProvider = PrivateChatProvider();
      final libraryProvider = LibraryProvider();
      final req = FriendRequestModel(
        id: 'req_test_03',
        senderId: 'usr_test_01',
        senderName: 'Test User',
        senderUsername: 'test_user',
        receiverId: 'usr_test_02',
        receiverUsername: 'receiver_user',
        createdAt: DateTime.now(),
      );
      await chatProvider.respondToFriendRequest(req, true);
      final contact = chatProvider.contacts.first;
      chatProvider.setActiveChat(contact.id);

      // Send image message
      chatProvider.sendMediaMessage(
        type: 'image',
        fileName: 'secret_photo.png',
        imageBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        fileSize: '1.2 MB',
      );

      expect(chatProvider.allChatImages.length, 1);
      final imgMsg = chatProvider.allChatImages.first;
      expect(imgMsg.fileName, 'secret_photo.png');

      // Move image to Library Vault
      final initialLibraryCount = libraryProvider.items.length;
      chatProvider.moveMessageToPrivateVault(imgMsg, libraryProvider);

      // Verify added to library and removed from chat
      expect(libraryProvider.items.length, initialLibraryCount + 1);
      expect(libraryProvider.items.first.name, 'secret_photo.png');
      expect(chatProvider.allChatImages.isEmpty, isTrue);
    });

    test('Special users aarushlohit and ashlinmirsha cannot block each other', () async {
      final chatProvider = PrivateChatProvider();

      // ashlinmirsha attempts to block aarushlohit -> prohibited
      final ashlinAttempts = await chatProvider.blockUser(
        targetId: 'usr_aarush_id',
        targetUsername: 'aarushlohit',
        targetDisplayName: 'Aarush',
        currentUsername: 'ashlinmirsha',
      );
      expect(ashlinAttempts, isFalse);
      expect(chatProvider.isBlocked('usr_aarush_id'), isFalse);

      // aarushlohit attempts to block ashlinmirsha -> prohibited
      final aarushAttempts = await chatProvider.blockUser(
        targetId: 'usr_ashlin_id',
        targetUsername: 'ashlinmirsha',
        targetDisplayName: 'Ashlin',
        currentUsername: 'aarushlohit',
      );
      expect(aarushAttempts, isFalse);
      expect(chatProvider.isBlocked('usr_ashlin_id'), isFalse);

      // Regular user can be blocked
      final regularBlock = await chatProvider.blockUser(
        targetId: 'usr_regular_id',
        targetUsername: 'random_user',
        targetDisplayName: 'Random',
        currentUsername: 'aarushlohit',
      );
      expect(regularBlock, isTrue);
      expect(chatProvider.isBlocked('usr_regular_id'), isTrue);
    });
  });

  group('LibraryProvider Tests', () {
    test('Create folder and filter items', () {
      final library = LibraryProvider();
      final initialFolderCount = library.folders.length;

      library.createFolder('Travel Documents');
      expect(library.folders.length, initialFolderCount + 1);
      expect(library.folders.any((f) => f.name == 'Travel Documents'), isTrue);

      library.setCurrentTab('Images');
      expect(library.filteredItems.every((i) => i.type == 'image'), isTrue);
    });
  });

  group('AuthProvider Tests', () {
    test('Sign up, login, update profile, and logout', () async {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse); // Initially logged out

      await auth.signup('Aarush Lohl', 'aarush.lohl@example.com', 'password123', username: 'aarush_lohl');
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.displayName, 'Aarush Lohl');

      auth.updateProfile(
        displayName: 'Aarush Lohl Updated',
      );
      expect(auth.currentUser?.displayName, 'Aarush Lohl Updated');

      auth.logout();
      expect(auth.isAuthenticated, isFalse);

      final loginSuccess = await auth.login('aarush.lohl@example.com', 'password123');
      expect(loginSuccess, isTrue);
      expect(auth.isAuthenticated, isTrue);
    });

    test('Special users bypass key check correctly', () async {
      final auth = AuthProvider();
      await auth.signup('Aarush Lohit', 'aarush@example.com', 'pass1234', username: 'aarushlohit');
      expect(auth.isSpecialUser, isTrue);

      await auth.signup('Ashlin Mirsha', 'ashlin@example.com', 'pass1234', username: 'ashlinmirsha');
      expect(auth.isSpecialUser, isTrue);

      await auth.signup('Regular User', 'user@example.com', 'pass1234', username: 'regularuser');
      expect(auth.isSpecialUser, isFalse);
    });
  });

  group('AiChat Safeguards and Features Tests', () {
    test('Pins, unpins, renames, and enforces minimum 1 chat safeguard', () {
      final aiProvider = AiChatProvider();
      expect(aiProvider.conversations.isNotEmpty, isTrue);

      final firstId = aiProvider.conversations.first.id;
      final initialPinned = aiProvider.conversations.first.isPinned;

      // Toggle pin
      aiProvider.togglePin(firstId);
      expect(aiProvider.conversations.first.isPinned, !initialPinned);

      // Rename
      aiProvider.renameConversation(firstId, 'Renamed Intelligence Chat');
      expect(aiProvider.conversations.first.title, 'Renamed Intelligence Chat');

      // Attempt to delete when only 1 chat exists
      while (aiProvider.conversations.length > 1) {
        aiProvider.deleteConversation(aiProvider.conversations.last.id);
      }
      expect(aiProvider.conversations.length, 1);

      // Deleting the last chat must automatically replenish with 1 clean chat
      aiProvider.deleteConversation(aiProvider.conversations.first.id);
      expect(aiProvider.conversations.length, 1);
      expect(aiProvider.conversations.first.messages.isEmpty, isTrue);
    });

    test('Active AI model sendPrompt returns live response', () async {
      final response = await AiService.instance.sendPrompt(
        prompt: 'What is 2+2?',
        model: AiModels.gemini25Flash,
      );
      expect(response, isNotEmpty);
      expect(response.contains('4') || response.contains('2'), isTrue);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });

  group('DownloadService Tests', () {
    test('Categorizes file extensions and types properly', () {
      expect(DownloadService.getCategory('voice_note.m4a', 'voice'), 'Audio');
      expect(DownloadService.getCategory('song.mp3'), 'Audio');
      expect(DownloadService.getCategory('clip.wav'), 'Audio');
      expect(DownloadService.getCategory('video.mp4', 'video'), 'Videos');
      expect(DownloadService.getCategory('movie.mov'), 'Videos');
      expect(DownloadService.getCategory('screenshot.png', 'image'), 'Images');
      expect(DownloadService.getCategory('photo.jpeg'), 'Images');
      expect(DownloadService.getCategory('doc.pdf'), 'Documents');
      expect(DownloadService.getCategory('sheet.xlsx'), 'Documents');
      expect(DownloadService.getCategory('unknown.xyz'), 'Documents');
    });
  });

  group('PrivateChatProvider Upgrades Tests', () {
    test('Prohibits texting oneself', () {
      final chat = PrivateChatProvider();
      chat.initUserSession('user_123', username: 'aarushlohit', email: 'aarush@example.com');

      // Attempting to set active chat to own ID
      chat.setActiveChat('user_123');
      expect(chat.activeChatId, isNull);

      // Attempting to set active chat to own username
      chat.setActiveChat('aarushlohit');
      expect(chat.activeChatId, isNull);

      // Successfully sets active chat for another user
      chat.setActiveChat('test_user', displayName: 'Test User', username: 'testuser');
      expect(chat.activeChatId, 'test_user');
    });

    test('Deletes conversation and cleans up messages', () {
      final chat = PrivateChatProvider();
      chat.initUserSession('user_123', username: 'aarushlohit');
      chat.setActiveChat('friend_456', displayName: 'Friend', username: 'friend');

      chat.sendTextMessage('Hello friend');
      expect(chat.activeMessages.length, 1);

      chat.deleteConversation('friend_456');
      expect(chat.activeMessages.isEmpty, isTrue);
      expect(chat.allConversations.any((c) => c.id == 'friend_456'), isFalse);
    });

    test('Privacy settings update and persist', () async {
      final chat = PrivateChatProvider();
      expect(chat.showOnlineStatus, isTrue);
      expect(chat.showLastSeen, isTrue);
      expect(chat.sendReadReceipts, isTrue);

      await chat.updatePrivacySettings(
        showOnlineStatus: false,
        showLastSeen: false,
        sendReadReceipts: false,
      );

      expect(chat.showOnlineStatus, isFalse);
      expect(chat.showLastSeen, isFalse);
      expect(chat.sendReadReceipts, isFalse);
    });
  });

  group('New Feature Upgrades Tests', () {
    test('UserModel supports bio and note serialization', () {
      final user = UserModel(
        id: 'u1',
        email: 'test@example.com',
        username: 'tester',
        displayName: 'Tester',
        bio: 'Hello world bio',
        note: 'Listening to music',
        createdAt: DateTime.now(),
      );

      final json = user.toJson();
      expect(json['bio'], 'Hello world bio');
      expect(json['note'], 'Listening to music');

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.bio, 'Hello world bio');
      expect(deserialized.note, 'Listening to music');

      final updated = user.copyWith(note: 'Updated note');
      expect(updated.note, 'Updated note');
      expect(updated.bio, 'Hello world bio');
    });

    test('PrivateContactModel supports group chat fields', () {
      final group = PrivateContactModel(
        id: 'group_12345',
        displayName: 'Design Team',
        username: 'group_12345',
        isGroup: true,
        memberIds: ['user1', 'user2', 'user3'],
      );

      final json = group.toJson();
      expect(json['isGroup'], isTrue);
      expect(json['memberIds'], ['user1', 'user2', 'user3']);

      final restored = PrivateContactModel.fromJson(json);
      expect(restored.isGroup, isTrue);
      expect(restored.memberIds.length, 3);
      expect(restored.memberIds, contains('user2'));
    });

    test('PrivateChatProvider creates group chat and sets active conversation', () async {
      final chat = PrivateChatProvider();
      chat.initUserSession('current_user', username: 'aarushlohit');

      final groupId = await chat.createGroupChat(
        groupName: 'Super Friends',
        memberIds: ['friend_1', 'friend_2'],
      );

      expect(groupId, startsWith('group_'));
      expect(chat.contacts.any((c) => c.id == groupId && c.isGroup), isTrue);
      expect(chat.activeChatId, groupId);
      expect(chat.activeContact?.displayName, 'Super Friends');
      expect(chat.activeContact?.memberIds, contains('friend_1'));
      expect(chat.activeContact?.memberIds, contains('current_user'));
    });

    test('LibraryItemModel tracks cloud sync status', () {
      final localItem = LibraryItemModel(
        id: 'item_1',
        name: 'photo.jpg',
        type: 'image',
        mimeType: 'image/jpeg',
        size: '1.2 MB',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(localItem.isSavedToCloud, isFalse);

      final cloudItem = localItem.copyWith(cloudUrl: 'https://res.cloudinary.com/test.jpg');
      expect(cloudItem.isSavedToCloud, isTrue);
      expect(cloudItem.cloudUrl, 'https://res.cloudinary.com/test.jpg');

      final json = cloudItem.toJson();
      expect(json['cloudUrl'], 'https://res.cloudinary.com/test.jpg');
      final restored = LibraryItemModel.fromJson(json);
      expect(restored.isSavedToCloud, isTrue);
    });

    test('LibraryProvider moveItem changes item folderId', () {
      final library = LibraryProvider();
      library.createFolder('Folder A');
      library.createFolder('Folder B');

      final folder1 = library.folders.firstWhere((f) => f.name == 'Folder A');
      final folder2 = library.folders.firstWhere((f) => f.name == 'Folder B');

      library.uploadItem(
        name: 'file_in_a.pdf',
        type: 'document',
        size: '250 KB',
        folderId: folder1.id,
      );

      final item = library.items.firstWhere((i) => i.name == 'file_in_a.pdf');
      expect(item.folderId, folder1.id);

      library.moveItem(item.id, folder2.id);
      final movedItem = library.items.firstWhere((i) => i.id == item.id);
      expect(movedItem.folderId, folder2.id);

      // Move back to root (null)
      library.moveItem(item.id, null);
      final rootItem = library.items.firstWhere((i) => i.id == item.id);
      expect(rootItem.folderId, isNull);
    });

    test('Library vault auto-lock prevents access to library and images without passcode', () async {
      final vault = VaultProvider();
      await vault.setLibraryPin('2468');

      // Initially locked
      expect(vault.isLibraryUnlocked, isFalse);

      // Successful unlock
      final unlocked = await vault.unlockLibraryAsync('2468');
      expect(unlocked, isTrue);
      expect(vault.isLibraryUnlocked, isTrue);

      // Exiting screen invokes lockLibrary()
      vault.lockLibrary();
      expect(vault.isLibraryUnlocked, isFalse);

      // Incorrect password fails
      final wrongUnlock = await vault.unlockLibraryAsync('0000');
      expect(wrongUnlock, isFalse);
      expect(vault.isLibraryUnlocked, isFalse);
    });
  });
}
