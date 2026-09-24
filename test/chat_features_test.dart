import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miralo/models/private_contact_model.dart';
import 'package:miralo/models/private_message_model.dart';
import 'package:miralo/widgets/chat/chat_header.dart';
import 'package:miralo/widgets/chat/composer.dart';
import 'package:miralo/widgets/chat/message_actions.dart';
import 'package:miralo/widgets/chat/message_renderer.dart';
import 'package:miralo/widgets/chat/pinned_messages_banner.dart';
import 'package:miralo/widgets/chat/pinned_messages_sheet.dart';
import 'package:miralo/screens/images/private_images_screen.dart';
import 'package:provider/provider.dart';
import 'package:miralo/providers/library_provider.dart';
import 'package:miralo/providers/vault_provider.dart';
import 'package:miralo/providers/ai_chat_provider.dart';
import 'package:miralo/providers/private_chat_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ChatHeader triggers onDoubleTapAvatar on double tap', (tester) async {
    bool doubleTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ChatHeader(
            isPrivate: true,
            title: 'Test Contact',
            onDoubleTapAvatar: () {
              doubleTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Contact'), findsOneWidget);

    // Find the avatar container
    final avatarFinder = find.byTooltip('Double-tap for quick panic exit');
    expect(avatarFinder, findsOneWidget);

    // Perform double tap
    await tester.tap(avatarFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(avatarFinder);
    await tester.pumpAndSettle();

    expect(doubleTapped, isTrue);
  });

  testWidgets('Composer displays slash commands suggestions overlay when "/" is typed', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VaultProvider()),
          ChangeNotifierProvider(create: (_) => AiChatProvider()),
          ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Composer(
              isPrivate: true,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    // Initially no slash commands overlay
    expect(find.text('Available Commands'), findsNothing);

    // Enter '/'
    await tester.enterText(find.byType(TextField), '/');
    await tester.pump();

    // Now overlay appears
    expect(find.text('Available Commands'), findsOneWidget);
    expect(find.text('/gif'), findsOneWidget);
    expect(find.text('/favorite'), findsOneWidget);

    // Filter by typing '/gi'
    await tester.enterText(find.byType(TextField), '/gi');
    await tester.pump();

    expect(find.text('/gif'), findsOneWidget);
    expect(find.text('/favorite'), findsNothing);

    // Filter by typing '/log'
    await tester.enterText(find.byType(TextField), '/log');
    await tester.pump();

    expect(find.text('/logout'), findsOneWidget);
    expect(find.text('/gif'), findsNothing);
  });

  testWidgets('Composer displays group mention suggestions overlay when "@" is typed and selects @all', (tester) async {
    final controller = TextEditingController();
    final member1 = PrivateContactModel(
      id: 'user_1',
      username: 'alice',
      displayName: 'Alice Cooper',
    );
    final member2 = PrivateContactModel(
      id: 'user_2',
      username: 'bob',
      displayName: 'Bob Builder',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VaultProvider()),
          ChangeNotifierProvider(create: (_) => AiChatProvider()),
          ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Composer(
              isPrivate: true,
              isGroup: true,
              groupMembers: [member1, member2],
              controller: controller,
            ),
          ),
        ),
      ),
    );

    // Initially no group mention overlay
    expect(find.text('Group Mentions'), findsNothing);

    // Enter '@'
    await tester.enterText(find.byType(TextField), '@');
    await tester.pump();

    // Now overlay appears with @all and group members
    expect(find.text('Group Mentions'), findsOneWidget);
    expect(find.text('@all'), findsOneWidget);
    expect(find.text('Mention Everyone'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('@bob'), findsOneWidget);

    // Tap '@all'
    await tester.tap(find.text('@all'));
    await tester.pump();

    expect(controller.text, equals('@all '));
    // Overlay should now be hidden
    expect(find.text('Group Mentions'), findsNothing);

    // Test member mention: type '@ali'
    await tester.enterText(find.byType(TextField), 'Hello @ali');
    await tester.pump();

    expect(find.text('Group Mentions'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('@bob'), findsNothing);

    // Tap '@alice'
    await tester.tap(find.text('@alice'));
    await tester.pump();

    expect(controller.text, equals('Hello @alice '));
  });

  testWidgets('Composer direct @ button inserts @all into group chat input', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VaultProvider()),
          ChangeNotifierProvider(create: (_) => AiChatProvider()),
          ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Composer(
              isPrivate: true,
              isGroup: true,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    final atButton = find.byTooltip('Mention all (@all)');
    expect(atButton, findsOneWidget);

    await tester.tap(atButton);
    await tester.pump();

    expect(controller.text, equals('@all '));
  });

  testWidgets('Composer /all slash command sets input to @all', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VaultProvider()),
          ChangeNotifierProvider(create: (_) => AiChatProvider()),
          ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Composer(
              isPrivate: true,
              isGroup: true,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '/all');
    await tester.pump();

    // Verify /all option is shown in slash commands
    final optionFinder = find.widgetWithText(InkWell, '/all');
    expect(optionFinder, findsOneWidget);

    // Tap /all option
    await tester.tap(optionFinder);
    await tester.pump();

    expect(controller.text, equals('@all '));
  });

  testWidgets('MessageRenderer renders @all and @username with rich highlight styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageRenderer(
            id: 'msg_1',
            text: 'Hello @all and @ashlinmirsha welcome!',
            isMe: false,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );

    // Should find the SelectableText with rich TextSpan
    final selectableFinder = find.byType(SelectableText);
    expect(selectableFinder, findsOneWidget);

    final selectable = tester.widget<SelectableText>(selectableFinder);
    expect(selectable.textSpan, isNotNull);
    final spans = (selectable.textSpan as TextSpan).children!;
    expect(spans.isNotEmpty, isTrue);

    // Verify @all span is present with bold styling
    final allSpan = spans.firstWhere(
      (s) => s is TextSpan && s.text == '@all',
    ) as TextSpan;
    expect(allSpan.text, equals('@all'));
    expect(allSpan.style?.fontWeight, equals(FontWeight.w800));

    // Verify @ashlinmirsha span is present with bold styling
    final userSpan = spans.firstWhere(
      (s) => s is TextSpan && s.text == '@ashlinmirsha',
    ) as TextSpan;
    expect(userSpan.text, equals('@ashlinmirsha'));
    expect(userSpan.style?.fontWeight, equals(FontWeight.w700));
  });

  testWidgets('MessageActionsSheet displays Save Favorite and Remove from Favorites', (tester) async {
    bool favorited = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageActionsSheet(
            text: 'Test message',
            isFavorite: false,
            onFavorite: () {
              favorited = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Save Favorite'), findsOneWidget);
    await tester.tap(find.text('Save Favorite'));
    await tester.pump();
    expect(favorited, isTrue);

    // Test when isFavorite: true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageActionsSheet(
            text: 'Test message',
            isFavorite: true,
            onFavorite: () {},
          ),
        ),
      ),
    );

    expect(find.text('Remove from Favorites'), findsOneWidget);
  });

  testWidgets('GIFs are excluded from allChatImages and included in favoriteGifs when favorited', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final chatProvider = PrivateChatProvider();
    chatProvider.setActiveChat('user_test');
    
    // Add normal photo image message
    chatProvider.sendMediaMessage(
      type: 'image',
      mediaUrl: 'https://example.com/photo.jpg',
      fileName: 'photo.jpg',
      fileSize: '1.2 MB',
    );

    // Add GIF message
    chatProvider.sendMediaMessage(
      type: 'image',
      mediaUrl: 'https://media.giphy.com/media/abc/giphy.gif',
      fileName: 'funny.gif',
      fileSize: 'GIF',
    );

    // Verify allChatImages has the photo but NOT the GIF
    expect(chatProvider.allChatImages.length, equals(1));
    expect(chatProvider.allChatImages.first.fileName, equals('photo.jpg'));
    expect(chatProvider.favoriteGifs.isEmpty, isTrue);

    // Find the GIF message in active chat
    final gifMsg = chatProvider.activeMessages.firstWhere((m) => m.isGif);
    expect(gifMsg.isGif, isTrue);

    // Favorite the GIF
    await chatProvider.toggleFavoriteMessage(gifMsg);
    expect(chatProvider.favoriteGifs.length, equals(1));
    expect(chatProvider.favoriteGifs.first.fileName, equals('funny.gif'));

    // allChatImages still does NOT contain the GIF
    expect(chatProvider.allChatImages.length, equals(1));
    expect(chatProvider.allChatImages.any((m) => m.isGif), isFalse);
  });

  testWidgets('Composer /favorite slash command appears in suggestions', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VaultProvider()),
          ChangeNotifierProvider(create: (_) => AiChatProvider()),
          ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Composer(
              isPrivate: true,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '/fav');
    await tester.pump();

    expect(find.text('Available Commands'), findsOneWidget);
    expect(find.text('/favorite'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('PrivateImagesScreen displays Chat Images and Favorites GIF tabs without describe field', (tester) async {
    final vaultProvider = VaultProvider();
    await vaultProvider.setLibraryPin('1234');
    vaultProvider.unlockLibrary('1234');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vaultProvider),
          ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
          ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ],
        child: const MaterialApp(
          home: PrivateImagesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify tabs
    expect(find.text('Chat Images'), findsOneWidget);
    expect(find.text('Favorites GIF'), findsOneWidget);
    expect(find.text('Templates'), findsNothing);

    // Verify describe image field is removed
    expect(find.text('Describe an image…'), findsNothing);

    // Tap on Favorites GIF tab
    await tester.tap(find.text('Favorites GIF'));
    await tester.pumpAndSettle();

    // The favorited GIF should be displayed in the grid
    expect(find.text('funny.gif'), findsOneWidget);
    expect(find.text('GIF'), findsOneWidget);
  });

  group('Pinned Messages Feature (Max 6 limit & WhatsApp-style)', () {
    test('PrivateChatProvider allows pinning up to 6 messages and rejects 7th', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PrivateChatProvider();

      // Create 7 messages for chat_123
      final messages = List.generate(
        7,
        (i) => PrivateMessageModel(
          id: 'msg_$i',
          chatId: 'chat_123',
          senderId: 'me',
          text: 'Message $i',
          createdAt: DateTime.now().subtract(Duration(minutes: 10 - i)),
        ),
      );

      // Pin first 6 messages
      for (int i = 0; i < 6; i++) {
        final success = await provider.togglePinMessage(messages[i]);
        expect(success, isTrue, reason: 'Message $i should pin successfully');
        expect(provider.isMessagePinned('msg_$i'), isTrue);
      }

      // Verify count is 6
      expect(provider.getPinnedMessageCount('chat_123'), equals(6));
      expect(provider.getPinnedMessages('chat_123').length, equals(6));

      // Attempt to pin the 7th message -> should fail and return false
      final seventhPinResult = await provider.togglePinMessage(messages[6]);
      expect(seventhPinResult, isFalse, reason: '7th pinned message must be rejected');
      expect(provider.isMessagePinned('msg_6'), isFalse);
      expect(provider.getPinnedMessageCount('chat_123'), equals(6));

      // Unpin msg_0
      await provider.unpinMessage('msg_0');
      expect(provider.isMessagePinned('msg_0'), isFalse);
      expect(provider.getPinnedMessageCount('chat_123'), equals(5));

      // Now pinning msg_6 should succeed
      final retryPinResult = await provider.togglePinMessage(messages[6]);
      expect(retryPinResult, isTrue);
      expect(provider.isMessagePinned('msg_6'), isTrue);
      expect(provider.getPinnedMessageCount('chat_123'), equals(6));

      // Clear all pinned messages in chat_123
      await provider.clearAllPinnedMessages('chat_123');
      expect(provider.getPinnedMessageCount('chat_123'), equals(0));
      expect(provider.getPinnedMessages('chat_123').isEmpty, isTrue);
    });

    testWidgets('MessageActionsSheet displays Pin Message and triggers onPin', (tester) async {
      bool pinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageActionsSheet(
              text: 'Hello world',
              isPinned: false,
              onPin: () {
                pinCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Pin Message'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);

      await tester.tap(find.text('Pin Message'));
      await tester.pump();

      expect(pinCalled, isTrue);
    });

    testWidgets('MessageActionsSheet displays Unpin Message when already pinned', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageActionsSheet(
              text: 'Pinned message text',
              isPinned: true,
              onPin: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unpin Message'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    });

    testWidgets('PinnedMessagesBanner displays active snippet, indicator, and cycles on tap', (tester) async {
      PrivateMessageModel? tappedMessage;
      PrivateMessageModel? unpinnedMessage;
      bool viewAllCalled = false;

      final pinnedList = <PrivateMessageModel>[
        PrivateMessageModel(
          id: 'pin_1',
          chatId: 'chat_1',
          senderId: 'alice_id',
          text: 'First pinned message',
          senderName: 'Alice',
          isPinned: true,
          pinnedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        PrivateMessageModel(
          id: 'pin_2',
          chatId: 'chat_1',
          senderId: 'me',
          text: 'Second pinned message',
          isPinned: true,
          pinnedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinnedMessagesBanner(
              pinnedMessages: pinnedList,
              onTapMessage: (msg) {
                tappedMessage = msg;
              },
              onUnpinMessage: (msg) {
                unpinnedMessage = msg;
              },
              onViewAll: () {
                viewAllCalled = true;
              },
            ),
          ),
        ),
      );

      // Verify banner content for first message
      expect(find.text('Pinned message'), findsOneWidget);
      expect(find.text('• 1/2'), findsOneWidget);
      expect(find.text('First pinned message'), findsOneWidget);
      expect(find.text('(Alice)'), findsOneWidget);

      // Tap banner to cycle
      await tester.tap(find.text('First pinned message'));
      await tester.pumpAndSettle();

      expect(tappedMessage?.id, equals('pin_1'));
      // Should now display second message
      expect(find.text('Pinned message'), findsOneWidget);
      expect(find.text('• 2/2'), findsOneWidget);
      expect(find.text('Second pinned message'), findsOneWidget);
      expect(find.text('(You)'), findsOneWidget);

      // Tap view all button
      final listButton = find.byTooltip('View all pinned (2/6)');
      expect(listButton, findsOneWidget);
      await tester.tap(listButton);
      await tester.pump();
      expect(viewAllCalled, isTrue);

      // Tap unpin button
      final unpinButton = find.byTooltip('Unpin message');
      expect(unpinButton, findsOneWidget);
      await tester.tap(unpinButton);
      await tester.pump();
      expect(unpinnedMessage?.id, equals('pin_2'));
    });

    testWidgets('PinnedMessagesSheet shows all pinned messages and handles actions', (tester) async {
      final pinnedList = <PrivateMessageModel>[
        PrivateMessageModel(
          id: 'pin_1',
          chatId: 'chat_1',
          senderId: 'bob_id',
          text: 'Pinned note 1',
          senderName: 'Bob',
          isPinned: true,
          createdAt: DateTime.now(),
        ),
        PrivateMessageModel(
          id: 'pin_2',
          chatId: 'chat_1',
          senderId: 'me',
          text: 'Pinned note 2',
          isPinned: true,
          createdAt: DateTime.now(),
        ),
      ];

      PrivateMessageModel? jumpedMsg;
      PrivateMessageModel? unpinnedMsg;
      bool clearedAll = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PinnedMessagesSheet.show(
                    ctx,
                    pinnedMessages: pinnedList,
                    onTapMessage: (msg) {
                      jumpedMsg = msg;
                    },
                    onUnpinMessage: (msg) {
                      unpinnedMsg = msg;
                    },
                    onUnpinAll: () {
                      clearedAll = true;
                    },
                  );
                },
                child: const Text('Open Pinned Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open Pinned Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Pinned Messages'), findsOneWidget);
      expect(find.text('2/6'), findsOneWidget);
      expect(find.text('Pinned note 1'), findsOneWidget);
      expect(find.text('Pinned note 2'), findsOneWidget);

      // Tap unpin on second message
      final unpinButtons = find.byTooltip('Unpin');
      expect(unpinButtons, findsNWidgets(2));
      await tester.tap(unpinButtons.at(1));
      await tester.pump();
      expect(unpinnedMsg?.id, equals('pin_2'));

      // Tap first message to jump (and auto-close modal sheet)
      await tester.tap(find.text('Pinned note 1'));
      await tester.pumpAndSettle();
      expect(jumpedMsg?.id, equals('pin_1'));
      // Sheet is closed now
      expect(find.text('Pinned Messages'), findsNothing);

      // Open again to test unpin all
      await tester.tap(find.text('Open Pinned Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unpin all'));
      await tester.pumpAndSettle();
      expect(clearedAll, isTrue);
      expect(find.text('Pinned Messages'), findsNothing);
    });

    testWidgets('Composer includes /pinned slash command suggestion', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VaultProvider()),
            ChangeNotifierProvider(create: (_) => AiChatProvider()),
            ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Composer(
                isPrivate: true,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '/pin');
      await tester.pump();

      expect(find.text('Available Commands'), findsOneWidget);
      expect(find.text('/pinned'), findsOneWidget);
      expect(find.text('View pinned messages (max 6) 📌'), findsOneWidget);
    });
  });
}
