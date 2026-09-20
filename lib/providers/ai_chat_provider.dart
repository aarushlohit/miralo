import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_chat_model.dart';
import '../services/ai_service.dart';

class AiChatProvider extends ChangeNotifier {
  static const String _prefConversationsKey = 'miralo_ai_conversations_v2';

  final List<AiChatModel> _conversations = [];
  String? _activeChatId;
  String _selectedModel = AiModels.gemini35Flash;
  bool _isStreaming = false;
  String? _prefilledPrompt;
  String _searchQuery = '';

  List<AiChatModel> get conversations => _conversations;
  String? get activeChatId => _activeChatId;
  String get selectedModel => _selectedModel;
  bool get isStreaming => _isStreaming;
  List<String> get availableModels => AiModels.all;
  String? get prefilledPrompt => _prefilledPrompt;
  String get searchQuery => _searchQuery;

  void prefillPrompt(String prompt) {
    _prefilledPrompt = prompt;
    notifyListeners();
  }

  String? consumePrefilledPrompt() {
    final val = _prefilledPrompt;
    _prefilledPrompt = null;
    return val;
  }

  AiChatModel? get activeChat {
    if (_activeChatId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeChatId);
    } catch (_) {
      return _conversations.isNotEmpty ? _conversations.first : null;
    }
  }

  List<AiChatModel> get pinnedChats =>
      _conversations.where((c) => c.isPinned).toList();

  List<AiChatModel> get recentChats =>
      _conversations.where((c) => !c.isPinned).toList();

  List<AiChatModel> get filteredPinnedChats {
    if (_searchQuery.trim().isEmpty) return pinnedChats;
    final q = _searchQuery.toLowerCase();
    return pinnedChats.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  List<AiChatModel> get filteredRecentChats {
    if (_searchQuery.trim().isEmpty) return recentChats;
    final q = _searchQuery.toLowerCase();
    return recentChats.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  AiChatProvider() {
    _seedDefaultChat();
    _initService();
  }

  Future<void> _initService() async {
    await AiService.instance.init();
    _selectedModel = AiService.instance.selectedModel;
    await _loadConversations();
    notifyListeners();
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefConversationsKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          _conversations.clear();
          for (final item in list) {
            _conversations.add(AiChatModel.fromJson(item as Map<String, dynamic>));
          }
        }
      } catch (_) {}
    }

    // Ensure at least one chat exists at all times
    if (_conversations.isEmpty) {
      _seedDefaultChat();
    }

    _activeChatId ??= _conversations.first.id;
  }

  void _seedDefaultChat() {
    final welcomeChat = AiChatModel(
      id: 'chat_default_welcome',
      title: 'Welcome to MIRALO AI',
      isPinned: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [
        AiMessageModel(
          id: 'msg_welcome_asst',
          role: 'assistant',
          text:
              'Welcome to MIRALO AI. Your intelligence workspace is ready.\n\n'
              '• Select from NVIDIA NIM, Google Gemini, and OpenCode models.\n'
              '• Use voice dictation or attach images for multimodal analysis.\n'
              '• All your conversations are strictly private.',
          timestamp: DateTime.now(),
          liked: true,
        ),
      ],
    );
    _conversations.add(welcomeChat);
    _activeChatId = welcomeChat.id;
    _saveConversations();
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_prefConversationsKey, raw);
  }

  void selectModel(String model) {
    _selectedModel = model;
    AiService.instance.setSelectedModel(model);
    notifyListeners();
  }

  void openChat(String chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  String createNewChat() {
    final newChat = AiChatModel(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Conversation',
      isPinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );
    _conversations.insert(0, newChat);
    _activeChatId = newChat.id;
    _saveConversations();
    notifyListeners();
    return newChat.id;
  }

  void togglePin(String chatId) {
    final idx = _conversations.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      final chat = _conversations[idx];
      _conversations[idx] = chat.copyWith(isPinned: !chat.isPinned);
      _saveConversations();
      notifyListeners();
    }
  }

  void renameConversation(String chatId, String newTitle) {
    final idx = _conversations.indexWhere((c) => c.id == chatId);
    if (idx != -1 && newTitle.trim().isNotEmpty) {
      _conversations[idx] = _conversations[idx].copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      );
      _saveConversations();
      notifyListeners();
    }
  }

  /// Delete conversation with mandatory safeguard: must keep at least one chat
  void deleteConversation(String chatId) {
    if (_conversations.length <= 1) {
      // Replace with clean conversation so list is never empty
      _conversations.clear();
      final freshChat = AiChatModel(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Conversation',
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [],
      );
      _conversations.add(freshChat);
      _activeChatId = freshChat.id;
      _saveConversations();
      notifyListeners();
      return;
    }

    _conversations.removeWhere((c) => c.id == chatId);
    if (_activeChatId == chatId) {
      _activeChatId = _conversations.first.id;
    }
    _saveConversations();
    notifyListeners();
  }

  Future<void> sendPrompt(
    String prompt, {
    String? imageBase64,
    bool isSpecialUser = false,
  }) async {
    if (prompt.trim().isEmpty && imageBase64 == null) return;

    if (_activeChatId == null) {
      createNewChat();
    }

    final userMsg = AiMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: prompt.trim(),
      imageBase64: imageBase64,
      timestamp: DateTime.now(),
    );

    final chatIndex = _conversations.indexWhere((c) => c.id == _activeChatId);
    if (chatIndex == -1) return;

    final currentChat = _conversations[chatIndex];
    final updatedMessages = List<AiMessageModel>.from(currentChat.messages)..add(userMsg);

    // Auto title if it was first message
    final newTitle = currentChat.messages.isEmpty
        ? (prompt.length > 28 ? '${prompt.substring(0, 25)}...' : (prompt.isNotEmpty ? prompt : 'Image Analysis'))
        : currentChat.title;

    _conversations[chatIndex] = currentChat.copyWith(
      title: newTitle,
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    _isStreaming = true;
    notifyListeners();

    // Streaming placeholder
    final assistantMsgId = 'msg_asst_${DateTime.now().millisecondsSinceEpoch}';
    final assistantMsg = AiMessageModel(
      id: assistantMsgId,
      role: 'assistant',
      text: '',
      timestamp: DateTime.now(),
    );

    _conversations[chatIndex] = _conversations[chatIndex].copyWith(
      messages: List<AiMessageModel>.from(_conversations[chatIndex].messages)..add(assistantMsg),
    );
    notifyListeners();

    // Fetch response from real AiService (Gemini, NVIDIA NIM, OpenCode)
    final fullResponse = await AiService.instance.sendPrompt(
      prompt: prompt,
      model: _selectedModel,
      imageBase64: imageBase64,
      isSpecialUser: isSpecialUser,
    );

    final words = fullResponse.split(' ');
    String currentText = '';

    for (int i = 0; i < words.length; i++) {
      if (!_isStreaming) break; // Interrupted by stop indicator!
      await Future.delayed(const Duration(milliseconds: 20));
      currentText += (i == 0 ? '' : ' ') + words[i];

      final liveIndex = _conversations.indexWhere((c) => c.id == _activeChatId);
      if (liveIndex != -1) {
        final msgs = List<AiMessageModel>.from(_conversations[liveIndex].messages);
        final asstIdx = msgs.indexWhere((m) => m.id == assistantMsgId);
        if (asstIdx != -1) {
          msgs[asstIdx] = msgs[asstIdx].copyWith(text: currentText);
          _conversations[liveIndex] = _conversations[liveIndex].copyWith(messages: msgs);
          notifyListeners();
        }
      }
    }

    _isStreaming = false;
    _saveConversations();
    notifyListeners();
  }

  void stopStreaming() {
    if (_isStreaming) {
      _isStreaming = false;
      notifyListeners();
    }
  }

  void likeMessage(String messageId, bool isLiked) {
    if (_activeChatId == null) return;
    final chatIndex = _conversations.indexWhere((c) => c.id == _activeChatId);
    if (chatIndex == -1) return;

    final msgs = List<AiMessageModel>.from(_conversations[chatIndex].messages);
    final msgIndex = msgs.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final currentLiked = msgs[msgIndex].liked;
    if (currentLiked == isLiked) {
      msgs[msgIndex] = msgs[msgIndex].copyWith(clearLiked: true);
    } else {
      msgs[msgIndex] = msgs[msgIndex].copyWith(liked: isLiked);
    }

    _conversations[chatIndex] = _conversations[chatIndex].copyWith(messages: msgs);
    _saveConversations();
    notifyListeners();
  }

  void regenerateLast({bool isSpecialUser = false}) {
    if (_activeChatId == null) return;
    final chat = activeChat;
    if (chat == null || chat.messages.isEmpty) return;

    final lastUserMsg = chat.messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => chat.messages.first,
    );

    sendPrompt(
      lastUserMsg.text,
      imageBase64: lastUserMsg.imageBase64,
      isSpecialUser: isSpecialUser,
    );
  }

  /// Edits a previous user prompt.
  /// Discards the target user message and all subsequent messages in the conversation,
  /// then resends the edited prompt.
  Future<void> editUserPrompt(
    String messageId,
    String editedText, {
    bool isSpecialUser = false,
  }) async {
    if (_activeChatId == null || editedText.trim().isEmpty) return;
    final chatIndex = _conversations.indexWhere((c) => c.id == _activeChatId);
    if (chatIndex == -1) return;

    final currentChat = _conversations[chatIndex];
    final msgIndex = currentChat.messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final targetMsg = currentChat.messages[msgIndex];

    // Truncate message list up to target user message (removing target and subsequent messages)
    final truncated = currentChat.messages.sublist(0, msgIndex);
    _conversations[chatIndex] = currentChat.copyWith(
      messages: truncated,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Send the edited prompt
    await sendPrompt(
      editedText.trim(),
      imageBase64: targetMsg.imageBase64,
      isSpecialUser: isSpecialUser,
    );
  }
}
