import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miralo/providers/vault_provider.dart';
import 'package:miralo/providers/ai_chat_provider.dart';
import 'package:miralo/providers/private_chat_provider.dart';
import 'package:miralo/providers/library_provider.dart';
import 'package:miralo/providers/auth_provider.dart';
import 'package:miralo/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VaultProvider Tests', () {
    test('Independent vault unlock and lock credentials', () async {
      final vault = VaultProvider();

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
    });

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
    test('Sends private message and updates active chat', () {
      final chatProvider = PrivateChatProvider();
      final contact = chatProvider.contacts.first;
      chatProvider.setActiveChat(contact.id);

      final initialMsgCount = chatProvider.activeMessages.length;
      chatProvider.sendTextMessage('Hey there, are we still on?');

      expect(chatProvider.activeMessages.length, initialMsgCount + 1);
      expect(chatProvider.activeMessages.last.text, 'Hey there, are we still on?');
      expect(chatProvider.activeMessages.last.isMe, isTrue);
    });

    test('Toggles emoji reaction on private message', () {
      final chatProvider = PrivateChatProvider();
      final contact = chatProvider.contacts.first;
      chatProvider.setActiveChat(contact.id);

      final firstMsg = chatProvider.activeMessages.first;
      expect(firstMsg.reactions.containsKey('❤️'), isFalse);

      chatProvider.toggleReaction(firstMsg.id, '❤️');
      final afterReaction = chatProvider.activeMessages.firstWhere((m) => m.id == firstMsg.id);
      expect(afterReaction.reactions.containsKey('❤️'), isTrue);
      expect(afterReaction.reactions['❤️'], 1);
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
      expect(auth.isAuthenticated, isTrue); // Initial test seed

      auth.updateProfile(
        displayName: 'Aarush Lohl',
        username: 'aarush_lohl',
      );
      expect(auth.currentUser?.displayName, 'Aarush Lohl');

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

    test('OpenCode model sendPrompt returns live response via fallback engine', () async {
      final response = await AiService.instance.sendPrompt(
        prompt: 'What is 2+2?',
        model: AiModels.bigPickle,
      );
      expect(response, isNotEmpty);
      expect(response.contains('4') || response.contains('2'), isTrue);
    });
  });
}
