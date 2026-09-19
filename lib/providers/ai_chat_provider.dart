import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ai_chat_model.dart';
import '../services/ai_service.dart';

class AiChatProvider extends ChangeNotifier {
  final List<AiChatModel> _conversations = [];
  String? _activeChatId;
  String _selectedModel = AiModels.gpt56;
  bool _isStreaming = false;

  List<AiChatModel> get conversations => _conversations;
  String? get activeChatId => _activeChatId;
  String get selectedModel => _selectedModel;
  bool get isStreaming => _isStreaming;
  List<String> get availableModels => AiModels.all;

  AiChatModel? get activeChat {
    if (_activeChatId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeChatId);
    } catch (_) {
      return null;
    }
  }

  List<AiChatModel> get pinnedChats =>
      _conversations.where((c) => c.isPinned).toList();

  List<AiChatModel> get recentChats =>
      _conversations.where((c) => !c.isPinned).toList();

  AiChatProvider() {
    _initService();
    _seedInitialConversations();
  }

  Future<void> _initService() async {
    await AiService.instance.init();
    _selectedModel = AiService.instance.selectedModel;
    notifyListeners();
  }

  void _seedInitialConversations() {
    final quantumChat = AiChatModel(
      id: 'chat_quantum_001',
      title: 'Quantum computing in simple words',
      isPinned: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      messages: [
        AiMessageModel(
          id: 'msg_q_1',
          role: 'user',
          text: 'Explain quantum computing in simple words.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        AiMessageModel(
          id: 'msg_q_2',
          role: 'assistant',
          text:
              'Quantum computing uses quantum bits, or qubits, which can be 0 and 1 at the same time, to process information in fundamentally different ways than classical computers.\n\n'
              'Here is how you can think about it:\n'
              '• **Superposition**: A coin flipped in the air is both heads and tails until caught.\n'
              '• **Entanglement**: Two coins spun miles apart that magically land on the same side every time.\n\n'
              '```python\n'
              '# Basic Qiskit circuit representation\n'
              'from qiskit import QuantumCircuit\n'
              'qc = QuantumCircuit(2, 2)\n'
              'qc.h(0) # Apply Hadamard gate (superposition)\n'
              'qc.cx(0, 1) # Entangle qubit 0 with qubit 1\n'
              '```\n\n'
              'This unlocks exponential processing power for molecular simulation, cryptography, and complex optimization.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 19)),
          liked: true,
        ),
      ],
    );

    final projectBChat = AiChatModel(
      id: 'chat_proj_b',
      title: 'Project B Architecture',
      isPinned: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      messages: [
        AiMessageModel(
          id: 'msg_pb_1',
          role: 'user',
          text: 'Design microservices architecture for real-time collaboration.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AiMessageModel(
          id: 'msg_pb_2',
          role: 'assistant',
          text:
              'For high-concurrency real-time collaboration, a hybrid CRDT and WebSocket gateway architecture with Redis pub/sub delivers under 15ms latency.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );

    final dsaChat = AiChatModel(
      id: 'chat_dsa',
      title: 'DSA ROADMAP',
      isPinned: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      messages: [
        AiMessageModel(
          id: 'msg_dsa_1',
          role: 'user',
          text: 'Create a 12-week DSA roadmap covering graphs and DP.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );

    final learnChat = AiChatModel(
      id: 'chat_learn_fast',
      title: 'How to learn faster?',
      isPinned: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      messages: [
        AiMessageModel(
          id: 'msg_lf_1',
          role: 'user',
          text: 'What are the top 3 cognitive learning strategies?',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    );

    final flutterChat = AiChatModel(
      id: 'chat_flutter_app',
      title: 'Build a Flutter app',
      isPinned: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      messages: [
        AiMessageModel(
          id: 'msg_fa_1',
          role: 'user',
          text: 'How to build production UI in Flutter?',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ],
    );

    _conversations.addAll([quantumChat, projectBChat, dsaChat, learnChat, flutterChat]);
    _activeChatId = quantumChat.id;
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
    notifyListeners();
    return newChat.id;
  }

  Future<void> sendPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    if (_activeChatId == null) {
      createNewChat();
    }

    final userMsg = AiMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: prompt.trim(),
      timestamp: DateTime.now(),
    );

    final chatIndex = _conversations.indexWhere((c) => c.id == _activeChatId);
    if (chatIndex == -1) return;

    final currentChat = _conversations[chatIndex];
    final updatedMessages = List<AiMessageModel>.from(currentChat.messages)..add(userMsg);
    
    // Auto title if it was first message
    final newTitle = currentChat.messages.isEmpty
        ? (prompt.length > 28 ? '${prompt.substring(0, 25)}...' : prompt)
        : currentChat.title;

    _conversations[chatIndex] = currentChat.copyWith(
      title: newTitle,
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    _isStreaming = true;
    notifyListeners();

    // Streaming response
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

    // Fetch response from real AiService (Gemini, NVIDIA NIM, OpenCode, or fallback)
    final fullResponse = await AiService.instance.sendPrompt(
      prompt: prompt,
      model: _selectedModel,
    );

    final words = fullResponse.split(' ');
    String currentText = '';

    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
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
    notifyListeners();
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
    notifyListeners();
  }

  void regenerateLast() {
    if (_activeChatId == null) return;
    final chat = activeChat;
    if (chat == null || chat.messages.isEmpty) return;

    // Find last user prompt
    final lastUserMsg = chat.messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => chat.messages.first,
    );

    sendPrompt(lastUserMsg.text);
  }

  void deleteConversation(String chatId) {
    _conversations.removeWhere((c) => c.id == chatId);
    if (_activeChatId == chatId) {
      _activeChatId = _conversations.isNotEmpty ? _conversations.first.id : null;
    }
    notifyListeners();
  }
}
