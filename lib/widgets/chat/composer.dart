import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/routes/app_routes.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../models/private_contact_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/ai_service.dart';
import '../../services/cloudinary_service.dart';
import 'attachment_sheet.dart';
import 'favorite_gifs_picker_sheet.dart';
import 'giphy_picker_sheet.dart';
import 'pinned_messages_sheet.dart';
import 'voice_note_recorder_sheet.dart';

class _PendingAttachment {
  final String type; // 'image', 'document'
  final String urlOrBase64;
  final String fileName;
  final String fileSize;

  const _PendingAttachment({
    required this.type,
    required this.urlOrBase64,
    required this.fileName,
    required this.fileSize,
  });
}

class _SlashCommand {
  final String command;
  final String description;
  final IconData icon;

  const _SlashCommand({
    required this.command,
    required this.description,
    required this.icon,
  });
}

class _MentionQuery {
  final String query; // characters typed after '@'
  final int atIndex; // index in text of '@'
  final int cursorIndex; // cursor position

  const _MentionQuery({
    required this.query,
    required this.atIndex,
    required this.cursorIndex,
  });
}

class _MentionOption {
  final String id;
  final String label; // "all" or username
  final String displayName;
  final String? avatarUrl;
  final bool isAll;

  const _MentionOption({
    required this.id,
    required this.label,
    required this.displayName,
    this.avatarUrl,
    this.isAll = false,
  });
}

const List<_SlashCommand> _allSlashCommands = [
  _SlashCommand(
    command: '/all',
    description: 'Mention everyone in group chat (@all)',
    icon: Icons.groups_rounded,
  ),
  _SlashCommand(
    command: '/gif',
    description: 'Search and send animated GIPHY GIFs',
    icon: Icons.gif_box_rounded,
  ),
  _SlashCommand(
    command: '/favorite',
    description: 'Search and send favorited GIFs ⭐',
    icon: Icons.star_rounded,
  ),
  _SlashCommand(
    command: '/pinned',
    description: 'View pinned messages (max 6) 📌',
    icon: Icons.push_pin_rounded,
  ),
  _SlashCommand(
    command: '/urgent',
    description: 'Instant panic switch to AI chat & lock vault',
    icon: Icons.flash_on_rounded,
  ),
  _SlashCommand(
    command: '/logout',
    description: 'Lock vault and return to home',
    icon: Icons.lock_outline_rounded,
  ),
  _SlashCommand(
    command: '/clear',
    description: 'Clear messages in this conversation',
    icon: Icons.delete_sweep_outlined,
  ),
  _SlashCommand(
    command: '/naughty',
    description: 'Send a playful truth or dare challenge',
    icon: Icons.favorite_rounded,
  ),
  _SlashCommand(
    command: '/dice',
    description: 'Roll a 6-sided die 🎲',
    icon: Icons.casino_outlined,
  ),
  _SlashCommand(
    command: '/coin',
    description: 'Flip a coin 🪙',
    icon: Icons.monetization_on_outlined,
  ),
  _SlashCommand(
    command: '/shrug',
    description: r'Insert ¯\_(ツ)_/¯',
    icon: Icons.emoji_emotions_outlined,
  ),
  _SlashCommand(
    command: '/tableflip',
    description: 'Insert (╯°□°)╯︵ ┻━┻',
    icon: Icons.sentiment_very_dissatisfied_rounded,
  ),
];

/// Unified Composer used for both AI Chat and Private Chat.
/// - Supports text + staged attachment preview (image or document) with cancel button and caption text.
/// - WhatsApp-style hold-to-record voice note in DM mode with slide-to-cancel and live timer.
/// - Speech-to-text dictation in AI mode.
/// - Smooth sending progress bar while media is encrypting and uploading.
/// - Silently intercepts secret passcode in AI mode to unlock private vault.
/// - Intercepts '/urgent', '/logout', and '/naughty' locally in Private mode.
/// - Supports @ and @all mentions in group chats with autocomplete overlay.
class Composer extends StatefulWidget {
  final bool isPrivate;
  final bool isGroup;
  final List<PrivateContactModel>? groupMembers;
  final ValueChanged<String>? onSubmitted;
  final Function(String text, String? base64Image)? onSubmittedWithImage;
  final Function(String base64Image, String fileName)? onImageAttached;
  final Function(String type, String urlOrBase64, String fileName, String fileSize, String captionText)? onMediaSubmitted;
  final ValueChanged<String>? onJumpToMessage;
  final VoidCallback? onOpenPinnedMessages;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool isSubmitting;

  const Composer({
    super.key,
    this.isPrivate = false,
    this.isGroup = false,
    this.groupMembers,
    this.onSubmitted,
    this.onSubmittedWithImage,
    this.onImageAttached,
    this.onMediaSubmitted,
    this.onJumpToMessage,
    this.onOpenPinnedMessages,
    this.controller,
    this.focusNode,
    this.hintText,
    this.isSubmitting = false,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _controller;
  FocusNode? _focusNode;
  bool _internalController = false;
  bool _hasText = false;

  // Staged Attachment (Preview before send)
  _PendingAttachment? _pendingAttachment;
  bool _isSendingMedia = false;

  // AI Speech Dictation
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  // Private Voice Note Hold-to-Record (WhatsApp-style)
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isVoiceRecording = false;
  bool _isVoiceLocked = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  String? _voicePath;
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  bool _isSlideCancelled = false;

  // Typing indicator debounce
  Timer? _typingDebounce;

  // Voice Note Pre-send Review Stage
  String? _recordedReviewPath;
  int _recordedReviewSeconds = 0;
  AudioPlayer? _reviewAudioPlayer;
  bool _isReviewPlaying = false;
  Duration _reviewPosition = Duration.zero;
  Duration _reviewDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _internalController = true;
    }
    _focusNode = widget.focusNode;
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
    if (!widget.isPrivate) {
      _initSpeech();
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
    }
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);
      try {
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _controller.text = result.recognizedWords;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                _hasText = _controller.text.trim().isNotEmpty;
              });
            }
          },
        );
      } catch (e) {
        if (mounted) setState(() => _isListening = false);
      }
    }
  }

  bool _previousTextStartsWithSlash = false;
  _MentionQuery? _currentMentionQuery;

  _MentionQuery? _getCurrentMentionQuery(String text, int cursor) {
    if (cursor <= 0 || cursor > text.length) return null;
    final sub = text.substring(0, cursor);
    final lastAt = sub.lastIndexOf('@');
    if (lastAt == -1) return null;
    // Ensure '@' is preceded by start of string or whitespace
    if (lastAt > 0 && !sub[lastAt - 1].contains(RegExp(r'\s'))) {
      return null;
    }
    // Ensure no whitespace between '@' and cursor
    final queryText = sub.substring(lastAt + 1);
    if (queryText.contains(RegExp(r'\s'))) {
      return null;
    }
    return _MentionQuery(query: queryText, atIndex: lastAt, cursorIndex: cursor);
  }

  List<_MentionOption> _getMatchingMentions(_MentionQuery query) {
    final q = query.query.toLowerCase();
    final list = <_MentionOption>[];

    // @all is always available if query is empty or starts with query
    if (q.isEmpty || 'all'.startsWith(q)) {
      list.add(
        const _MentionOption(
          id: 'all',
          label: 'all',
          displayName: 'Mention Everyone',
          isAll: true,
        ),
      );
    }

    if (widget.groupMembers != null) {
      for (final member in widget.groupMembers!) {
        if (q.isEmpty ||
            member.username.toLowerCase().contains(q) ||
            member.displayName.toLowerCase().contains(q)) {
          list.add(
            _MentionOption(
              id: member.id,
              label: member.username,
              displayName: member.displayName,
              avatarUrl: member.avatarUrl,
              isAll: false,
            ),
          );
        }
      }
    }

    return list;
  }

  void _selectMention(_MentionOption option, _MentionQuery query) {
    final text = _controller.text;
    final prefix = text.substring(0, query.atIndex);
    final suffix = query.cursorIndex <= text.length ? text.substring(query.cursorIndex) : '';
    final insert = '@${option.label} ';
    final newText = prefix + insert + suffix;
    final newPos = (prefix + insert).length;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPos),
    );
    setState(() {
      _currentMentionQuery = null;
    });
  }

  void _onTextChanged() {
    final text = _controller.text;
    final has = text.trim().isNotEmpty;
    final startsWithSlash = text.startsWith('/');
    final sel = _controller.selection;
    final cursor = sel.isValid ? sel.baseOffset : text.length;
    final mentionQuery = widget.isGroup ? _getCurrentMentionQuery(text, cursor) : null;

    final mentionChanged = (mentionQuery?.query != _currentMentionQuery?.query ||
        mentionQuery?.atIndex != _currentMentionQuery?.atIndex ||
        (mentionQuery == null) != (_currentMentionQuery == null));

    if (has != _hasText || startsWithSlash || _previousTextStartsWithSlash || mentionChanged) {
      _previousTextStartsWithSlash = startsWithSlash;
      _currentMentionQuery = mentionQuery;
      setState(() => _hasText = has);
    }

    // Typing indicator broadcast (private chat only)
    if (widget.isPrivate) {
      final chat = Provider.of<PrivateChatProvider>(context, listen: false);
      final chatId = chat.activeChatId;
      if (chatId != null) {
        if (has) {
          chat.setTypingStatus(chatId, true);
          _typingDebounce?.cancel();
          _typingDebounce = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              chat.setTypingStatus(chatId, false);
            }
          });
        } else {
          _typingDebounce?.cancel();
          chat.setTypingStatus(chatId, false);
        }
      }
    }
  }

  // ─── WhatsApp-style Voice Recording & Review ───
  Future<void> _startVoiceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isVoiceRecording = true;
          _isVoiceLocked = false;
          _voiceSeconds = 0;
          _voicePath = path;
          _dragOffsetX = 0.0;
          _dragOffsetY = 0.0;
          _isSlideCancelled = false;
        });

        _voiceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) {
            setState(() => _voiceSeconds++);
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting voice note recording: $e');
    }
  }

  Future<void> _stopRecordingAndEnterReview() async {
    _voiceTimer?.cancel();
    if (!_isVoiceRecording) return;

    final seconds = _voiceSeconds;
    final wasCancelled = _isSlideCancelled;

    setState(() {
      _isVoiceRecording = false;
      _isVoiceLocked = false;
    });

    try {
      final path = await _audioRecorder.stop();
      final finalPath = path ?? _voicePath;

      if (wasCancelled || finalPath == null) {
        if (finalPath != null) {
          final file = File(finalPath);
          if (file.existsSync()) file.deleteSync();
        }
        return;
      }

      // If recording was less than 1 second, ignore accidental tap
      if (seconds < 1) {
        final file = File(finalPath);
        if (file.existsSync()) file.deleteSync();
        return;
      }

      setState(() {
        _recordedReviewPath = finalPath;
        _recordedReviewSeconds = seconds;
        _reviewDuration = Duration(seconds: seconds);
        _reviewPosition = Duration.zero;
      });

      await _initReviewAudioPlayer();
    } catch (e) {
      debugPrint('Error stopping voice note: $e');
    }
  }

  Future<void> _initReviewAudioPlayer() async {
    _reviewAudioPlayer?.dispose();
    _reviewAudioPlayer = AudioPlayer();

    _reviewAudioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isReviewPlaying = state == PlayerState.playing);
      }
    });

    _reviewAudioPlayer!.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _reviewDuration = d);
      }
    });

    _reviewAudioPlayer!.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => _reviewPosition = p);
      }
    });

    _reviewAudioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isReviewPlaying = false;
          _reviewPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _toggleReviewPlayback() async {
    if (_reviewAudioPlayer == null || _recordedReviewPath == null) return;
    try {
      if (_isReviewPlaying) {
        await _reviewAudioPlayer!.pause();
      } else {
        await _reviewAudioPlayer!.play(DeviceFileSource(_recordedReviewPath!));
      }
    } catch (e) {
      debugPrint('Error playing review audio: $e');
    }
  }

  Future<void> _seekReviewAudio(Duration position) async {
    if (_reviewAudioPlayer == null) return;
    try {
      await _reviewAudioPlayer!.seek(position);
    } catch (e) {
      debugPrint('Error seeking review audio: $e');
    }
  }

  void _discardReviewVoiceNote() {
    _reviewAudioPlayer?.stop();
    _reviewAudioPlayer?.dispose();
    _reviewAudioPlayer = null;
    if (_recordedReviewPath != null) {
      final f = File(_recordedReviewPath!);
      if (f.existsSync()) f.deleteSync();
    }
    setState(() {
      _recordedReviewPath = null;
      _recordedReviewSeconds = 0;
      _isReviewPlaying = false;
      _reviewPosition = Duration.zero;
      _reviewDuration = Duration.zero;
    });
  }

  Future<void> _sendReviewVoiceNote() async {
    if (_recordedReviewPath == null) return;
    final path = _recordedReviewPath!;
    final seconds = _recordedReviewSeconds;

    await _reviewAudioPlayer?.stop();
    await _reviewAudioPlayer?.dispose();
    _reviewAudioPlayer = null;

    setState(() {
      _recordedReviewPath = null;
      _recordedReviewSeconds = 0;
      _isReviewPlaying = false;
      _isSendingMedia = true;
    });

    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final minutes = (seconds ~/ 60).toString().padLeft(1, '0');
        final secs = (seconds % 60).toString().padLeft(2, '0');
        final durationText = '$minutes:$secs';
        final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        final cloudUrl = await CloudinaryService.uploadFileBytes(
          fileBytes: bytes,
          fileName: fileName,
          resourceType: 'video',
        );

        final mediaPayload = (cloudUrl != null && cloudUrl.isNotEmpty) ? cloudUrl : base64Encode(bytes);

        if (mounted) {
          final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
          privateChat.sendMediaMessage(
            type: 'voice',
            mediaUrl: mediaPayload.startsWith('http') ? mediaPayload : null,
            imageBase64: mediaPayload.startsWith('http') ? null : mediaPayload,
            fileName: 'Voice Note ($durationText)',
            fileSize: durationText,
          );
        }
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    } catch (e) {
      debugPrint('Error sending voice note: $e');
    } finally {
      if (mounted) {
        setState(() => _isSendingMedia = false);
      }
    }
  }

  void _cancelVoiceRecording() {
    _voiceTimer?.cancel();
    _isSlideCancelled = true;
    _audioRecorder.stop().then((path) {
      final target = path ?? _voicePath;
      if (target != null) {
        final f = File(target);
        if (f.existsSync()) f.deleteSync();
      }
    });
    setState(() {
      _isVoiceRecording = false;
      _isVoiceLocked = false;
      _voiceSeconds = 0;
      _dragOffsetX = 0.0;
      _dragOffsetY = 0.0;
      _isSlideCancelled = false;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    // Clear typing status when leaving chat
    if (widget.isPrivate && mounted) {
      try {
        final chat = Provider.of<PrivateChatProvider>(context, listen: false);
        final chatId = chat.activeChatId;
        if (chatId != null) chat.setTypingStatus(chatId, false);
      } catch (_) {}
    }
    _voiceTimer?.cancel();
    _audioRecorder.dispose();
    _reviewAudioPlayer?.dispose();
    if (_recordedReviewPath != null) {
      final f = File(_recordedReviewPath!);
      if (f.existsSync()) f.deleteSync();
    }
    if (_isListening) {
      _speech.stop();
    }
    _controller.removeListener(_onTextChanged);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final attachment = _pendingAttachment;

    if (text.isEmpty && attachment == null) return;

    // Stop typing indicator immediately on send
    if (widget.isPrivate) {
      _typingDebounce?.cancel();
      try {
        final chat = Provider.of<PrivateChatProvider>(context, listen: false);
        final chatId = chat.activeChatId;
        if (chatId != null) chat.setTypingStatus(chatId, false);
      } catch (_) {}
    }

    if (!widget.isPrivate) {
      // ─── AI MODE PASSCODE INTERCEPTION ───
      final vault = Provider.of<VaultProvider>(context, listen: false);
      if (vault.verifyPasscode(text) ||
          (!vault.hasPrivateSecret &&
              vault.currentUserId != null &&
              await vault.verifyPrivateSecretServerSide(text))) {
        // Silently intercept secret passcode: NEVER send to AI, NEVER save to chat history!
        vault.unlockPrivate(text);
        _controller.clear();
        setState(() {
          _pendingAttachment = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Private contacts unlocked.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    // ─── SLASH COMMANDS INTERCEPTION ───
    final lower = text.toLowerCase();

    // ─── DM / GROUP CHAT EXCLUSIVE SLASH COMMANDS ───
    if (widget.isPrivate) {
      if (lower == '/gif' || lower.startsWith('/gif ')) {
        _controller.clear();
        _openGiphyPicker();
        return;
      } else if (lower == '/favorite' ||
          lower.startsWith('/favorite ') ||
          lower == '/fav' ||
          lower.startsWith('/fav ')) {
        _controller.clear();
        final trimmed = text.trim();
        String query = '';
        if (trimmed.toLowerCase().startsWith('/favorite')) {
          query = trimmed.length > 9 ? trimmed.substring(9).trim() : '';
        } else if (trimmed.toLowerCase().startsWith('/fav')) {
          query = trimmed.length > 4 ? trimmed.substring(4).trim() : '';
        }
        _openFavoriteGifsPicker(initialQuery: query);
        return;
      } else if (lower == '/pinned' || lower == '/pin') {
        _controller.clear();
        _openPinnedMessages();
        return;
      } else if (lower.startsWith('/naughty')) {
        final param = text.substring(text.toLowerCase().indexOf('/naughty') + 8).trim();
        _controller.clear();
        _executeNaughtySlashCommand(param);
        return;
      } else if (lower == '/all' && widget.isGroup) {
        _controller.clear();
        _executeSlashCommand('/all');
        return;
      }
    }

    // ─── UNIVERSAL / AI CHAT SLASH COMMANDS ───
    if (lower == '/logout') {
      _controller.clear();
      _executeSlashCommand('/logout');
      return;
    } else if (lower == '/urgent') {
      _controller.clear();
      _executeSlashCommand('/urgent');
      return;
    } else if (lower == '/clear') {
      _controller.clear();
      _executeSlashCommand('/clear');
      return;
    } else if (lower == '/dice') {
      _controller.clear();
      _executeSlashCommand('/dice');
      return;
    } else if (lower == '/coin') {
      _controller.clear();
      _executeSlashCommand('/coin');
      return;
    } else if (lower == '/shrug') {
      _controller.clear();
      _executeSlashCommand('/shrug');
      return;
    } else if (lower == '/tableflip') {
      _controller.clear();
      _executeSlashCommand('/tableflip');
      return;
    }

    if (!mounted) return;

    // ─── SENDING MEDIA ATTACHMENT WITH OPTIONAL CAPTION ───
    if (attachment != null) {
      setState(() => _isSendingMedia = true);

      if (widget.onMediaSubmitted != null) {
        widget.onMediaSubmitted!(
          attachment.type,
          attachment.urlOrBase64,
          attachment.fileName,
          attachment.fileSize,
          text,
        );
      } else if (widget.isPrivate) {
        final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
        privateChat.sendMediaMessage(
          type: attachment.type,
          mediaUrl: attachment.urlOrBase64.startsWith('http') ? attachment.urlOrBase64 : null,
          imageBase64: attachment.urlOrBase64.startsWith('http') ? null : attachment.urlOrBase64,
          text: text,
          fileName: attachment.fileName,
          fileSize: attachment.fileSize,
        );
      } else {
        // AI Chat Mode with image attachment
        widget.onSubmittedWithImage?.call(text, attachment.urlOrBase64);
      }

      _controller.clear();
      if (mounted) {
        setState(() {
          _pendingAttachment = null;
          _isSendingMedia = false;
        });
      }
      return;
    }

    // ─── SENDING NORMAL TEXT MESSAGE ───
    if (widget.onSubmittedWithImage != null) {
      widget.onSubmittedWithImage!(text, null);
    } else {
      widget.onSubmitted?.call(text);
    }
    _controller.clear();
  }

  void _executeSlashCommand(String command) {
    switch (command) {
      case '/gif':
        _controller.clear();
        _openGiphyPicker();
        break;
      case '/favorite':
      case '/fav':
        _controller.clear();
        _openFavoriteGifsPicker();
        break;
      case '/pinned':
      case '/pin':
        _controller.clear();
        _openPinnedMessages();
        break;
      case '/logout':
        _controller.clear();
        final vault = Provider.of<VaultProvider>(context, listen: false);
        vault.lockAll();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out of private workspace.'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case '/urgent':
        _controller.clear();
        final vault = Provider.of<VaultProvider>(context, listen: false);
        final ai = Provider.of<AiChatProvider>(context, listen: false);
        vault.lockAll();
        if (ai.activeChat == null) {
          ai.prefillPrompt('Can you explain quantum computing simply?');
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.aiChat,
            (route) => false,
          );
        }
        break;
      case '/clear':
        _controller.clear();
        if (widget.isPrivate) {
          final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
          privateChat.clearActiveChat();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation messages cleared.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          final ai = Provider.of<AiChatProvider>(context, listen: false);
          ai.clearMessages();
        }
        break;
      case '/naughty':
        _executeNaughtySlashCommand('');
        break;
      case '/dice':
        _controller.clear();
        final roll = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
        final msg = '🎲 Rolled a $roll!';
        if (widget.isPrivate) {
          Provider.of<PrivateChatProvider>(context, listen: false).sendTextMessage(msg);
        } else {
          widget.onSubmitted?.call(msg);
        }
        break;
      case '/coin':
        _controller.clear();
        final flip = (DateTime.now().microsecondsSinceEpoch % 2 == 0) ? 'Heads' : 'Tails';
        final msg = '🪙 Flipped $flip!';
        if (widget.isPrivate) {
          Provider.of<PrivateChatProvider>(context, listen: false).sendTextMessage(msg);
        } else {
          widget.onSubmitted?.call(msg);
        }
        break;
      case '/shrug':
        _controller.text = r'¯\_(ツ)_/¯';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        break;
      case '/tableflip':
        _controller.text = '(╯°□°)╯︵ ┻━┻';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        break;
      case '/all':
        _controller.value = const TextEditingValue(
          text: '@all ',
          selection: TextSelection.collapsed(offset: 5),
        );
        break;
      default:
        _controller.text = '$command ';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        break;
    }
  }

  Future<void> _executeNaughtySlashCommand(String param) async {
    final lowerParam = param.toLowerCase();
    String mode = 'mix';
    String? customTopic;

    if (lowerParam == 'dare') {
      mode = 'dare';
    } else if (lowerParam == 'truth') {
      mode = 'truth';
    } else if (lowerParam.startsWith('dare ')) {
      mode = 'dare';
      customTopic = param.substring(5).trim();
    } else if (lowerParam.startsWith('truth ')) {
      mode = 'truth';
      customTopic = param.substring(6).trim();
    } else if (param.isNotEmpty) {
      customTopic = param.trim();
    }

    final prompt = await AiService.instance.generateNaughtyTruthOrDare(
      mode: mode,
      customTopic: customTopic,
    );

    if (!mounted) return;

    if (widget.isPrivate) {
      final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
      privateChat.sendTextMessage(prompt);
    } else {
      widget.onSubmitted?.call(prompt);
    }
  }

  void _openGiphyPicker() {
    GiphyPickerSheet.show(
      context,
      onGifSelected: (gifUrl, title) {
        _handleSendGif(gifUrl, title);
      },
    );
  }

  void _openFavoriteGifsPicker({String initialQuery = ''}) {
    FavoriteGifsPickerSheet.show(
      context,
      initialQuery: initialQuery,
      onGifSelected: (gifUrl, title) {
        _handleSendGif(gifUrl, title);
      },
    );
  }

  void _openPinnedMessages() {
    if (widget.onOpenPinnedMessages != null) {
      widget.onOpenPinnedMessages!();
      return;
    }
    if (!widget.isPrivate) return;
    final chat = Provider.of<PrivateChatProvider>(context, listen: false);
    final pinned = chat.getPinnedMessages();
    PinnedMessagesSheet.show(
      context,
      pinnedMessages: pinned,
      onTapMessage: (msg) {
        widget.onJumpToMessage?.call(msg.id);
      },
      onUnpinMessage: (msg) => chat.togglePinMessage(msg),
      onUnpinAll: () => chat.clearAllPinnedMessages(chat.activeChatId ?? ''),
    );
  }

  void _handleSendGif(String gifUrl, String title) {
    if (widget.isPrivate) {
      final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
      privateChat.sendMediaMessage(
        type: 'image',
        mediaUrl: gifUrl,
        fileName: title.isNotEmpty ? '$title.gif' : 'giphy.gif',
        fileSize: 'GIF',
      );
    } else {
      widget.onSubmittedWithImage?.call(title, gifUrl);
    }
  }

  void _showAttachmentSheet() {
    AttachmentSheet.show(
      context,
      onImageSelected: (urlOrBase64, name) {
        setState(() {
          _pendingAttachment = _PendingAttachment(
            type: 'image',
            urlOrBase64: urlOrBase64,
            fileName: name,
            fileSize: 'Image',
          );
        });
      },
      onDocumentSelected: (docUrlOrBase64, name, size) {
        setState(() {
          _pendingAttachment = _PendingAttachment(
            type: 'document',
            urlOrBase64: docUrlOrBase64,
            fileName: name,
            fileSize: size,
          );
        });
      },
      onVoiceNoteRecorded: (audioUrlOrBase64, durationText) {
        if (widget.isPrivate) {
          final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
          privateChat.sendMediaMessage(
            type: 'voice',
            mediaUrl: audioUrlOrBase64.startsWith('http') ? audioUrlOrBase64 : null,
            imageBase64: audioUrlOrBase64.startsWith('http') ? null : audioUrlOrBase64,
            fileName: 'Voice Note ($durationText)',
            fileSize: durationText,
          );
        }
      },
      onGifSelected: (gifUrl, title) {
        _handleSendGif(gifUrl, title);
      },
    );
  }

  Widget _buildAttachmentThumbnail(_PendingAttachment attachment) {
    if (attachment.type == 'image') {
      try {
        if (attachment.urlOrBase64.startsWith('http')) {
          return Image.network(
            attachment.urlOrBase64,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackThumb(),
          );
        } else {
          return Image.memory(
            base64Decode(attachment.urlOrBase64),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackThumb(),
          );
        }
      } catch (_) {
        return _fallbackThumb();
      }
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MiraloColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.insert_drive_file_rounded, color: MiraloColors.accent, size: 24),
      );
    }
  }

  Widget _fallbackThumb() {
    return Container(
      width: 44,
      height: 44,
      color: Colors.white12,
      child: const Icon(Icons.image_outlined, size: 22, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? MiraloColors.darkSurfaceInput
        : MiraloColors.lightSurfaceInput;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;
    final textPrimary = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final textMuted = isDark
        ? MiraloColors.darkTextMuted
        : MiraloColors.lightTextMuted;

    final hint = widget.hintText ??
        (_pendingAttachment != null
            ? 'Add a caption...'
            : (widget.isPrivate ? 'Message...' : 'Ask anything...'));

    final canSend = _hasText || _pendingAttachment != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiraloSpacing.md,
        vertical: MiraloSpacing.xs,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sending Progress Bar
            if (_isSendingMedia)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(MiraloColors.accent),
                  ),
                ),
              ),

            // Slash Commands Suggestions Overlay
            if (_controller.text.startsWith('/') && _pendingAttachment == null && !_isVoiceRecording)
              Builder(
                builder: (context) {
                  final input = _controller.text.toLowerCase().trim();
                  final matching = _allSlashCommands.where((c) {
                    if (!c.command.startsWith(input)) return false;
                    // Filter DM-personalized commands if in AI Chat mode (!widget.isPrivate)
                    if (!widget.isPrivate) {
                      if (c.command == '/gif' ||
                          c.command == '/favorite' ||
                          c.command == '/pinned' ||
                          c.command == '/naughty' ||
                          c.command == '/all') {
                        return false;
                      }
                    }
                    if (c.command == '/all' && !widget.isGroup) return false;
                    return true;
                  }).toList();
                  if (matching.isEmpty) return const SizedBox.shrink();
                  return _buildSlashSuggestionsOverlay(
                    matching,
                    isDark,
                    border,
                    textPrimary,
                    textMuted,
                  );
                },
              ),

            // Group Mention Suggestions Overlay (@all, @member)
            if (_currentMentionQuery != null && _pendingAttachment == null && !_isVoiceRecording)
              Builder(
                builder: (context) {
                  final matching = _getMatchingMentions(_currentMentionQuery!);
                  if (matching.isEmpty) return const SizedBox.shrink();
                  return _buildMentionSuggestionsOverlay(
                    matching,
                    _currentMentionQuery!,
                    isDark,
                    border,
                    textPrimary,
                    textMuted,
                  );
                },
              ),

            // Staged Attachment Preview Card with Cancel Button & Caption Support
            if (_pendingAttachment != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD9DCE3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildAttachmentThumbnail(_pendingAttachment!),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _pendingAttachment!.fileName,
                            style: MiraloTypography.bodyMedium(color: textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pendingAttachment!.fileSize,
                            style: MiraloTypography.bodySmall(color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: textMuted,
                      onPressed: () {
                        setState(() {
                          _pendingAttachment = null;
                        });
                      },
                      tooltip: 'Cancel file',
                    ),
                  ],
                ),
              ),

            // Voice Review Stage (Preview before sending)
            if (_recordedReviewPath != null)
              _buildVoiceReviewBar(context, isDark, textPrimary, textMuted)
            // Voice Recording Bar (WhatsApp-style active view)
            else if (_isVoiceRecording)
              _buildVoiceRecordingBar(context, isDark)
            else
              // Standard Input Row
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(MiraloRadius.composer),
                  border: Border.all(
                    color: isDark ? const Color(0x12FFFFFF) : border,
                    width: 0.6,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Attachment button
                    IconButton(
                      icon: Icon(
                        widget.isPrivate
                            ? Icons.attach_file_rounded
                            : Icons.add_rounded,
                      ),
                      color: _pendingAttachment != null ? MiraloColors.accent : textMuted,
                      iconSize: 22,
                      onPressed: _showAttachmentSheet,
                      tooltip: widget.isPrivate ? 'Share media / files' : 'Attach image',
                    ),

                    // Direct @ mention button in group chat
                    if (widget.isGroup)
                      IconButton(
                        icon: const Icon(Icons.alternate_email_rounded),
                        color: _currentMentionQuery != null ? MiraloColors.accent : textMuted,
                        iconSize: 20,
                        tooltip: 'Mention all (@all)',
                        onPressed: () {
                          final text = _controller.text;
                          final sel = _controller.selection;
                          final cursor = sel.isValid ? sel.baseOffset : text.length;
                          final prefix = text.substring(0, cursor);
                          final suffix = text.substring(cursor);
                          final insert = (prefix.isEmpty || prefix.endsWith(' ')) ? '@all ' : ' @all ';
                          final newText = prefix + insert + suffix;
                          final newPos = (prefix + insert).length;
                          _controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: newPos),
                          );
                        },
                      ),

                    // Text input field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 5,
                        minLines: 1,
                        style: MiraloTypography.bodyMedium(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: MiraloTypography.bodyMedium(color: textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),

                    // Microphone in AI mode (Speech-to-text dictation)
                    if (!widget.isPrivate)
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          size: 20,
                          color: _isListening ? Colors.redAccent : textMuted,
                        ),
                        onPressed: _toggleListening,
                        tooltip: _isListening ? 'Stop dictating' : 'Voice dictation',
                      ),

                    // Action Button (Send button OR WhatsApp-style Voice Note Hold Button)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: widget.isSubmitting
                          ? Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: MiraloColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.stop_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  final ai = Provider.of<AiChatProvider>(context, listen: false);
                                  ai.stopStreaming();
                                },
                                tooltip: 'Stop response',
                              ),
                            )
                          : canSend || !widget.isPrivate
                              ? Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: canSend
                                        ? MiraloColors.accent
                                        : (isDark
                                            ? MiraloColors.darkSurfaceSecondary
                                            : MiraloColors.lightSurfaceSecondary),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 20,
                                      color: canSend ? Colors.white : textMuted,
                                    ),
                                    onPressed: canSend ? _handleSend : null,
                                  ),
                                )
                               // Private mode hold-to-record or tap to open Voice Note recorder
                              : GestureDetector(
                                  onTap: () {
                                    VoiceNoteRecorderSheet.show(
                                      context,
                                      onVoiceNoteRecorded: (audioUrlOrBase64, durationText) {
                                        final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
                                        privateChat.sendMediaMessage(
                                          type: 'voice',
                                          mediaUrl: audioUrlOrBase64.startsWith('http') ? audioUrlOrBase64 : null,
                                          imageBase64: audioUrlOrBase64.startsWith('http') ? null : audioUrlOrBase64,
                                          fileName: 'Voice Note ($durationText)',
                                          fileSize: durationText,
                                        );
                                      },
                                    );
                                  },
                                  onLongPressStart: (_) => _startVoiceRecording(),
                                  onLongPressMoveUpdate: (details) {
                                    setState(() {
                                      _dragOffsetX = details.localPosition.dx;
                                      _dragOffsetY = details.localPosition.dy;
                                      if (_dragOffsetX < -70) {
                                        _isSlideCancelled = true;
                                      }
                                      if (_dragOffsetY < -50 && !_isSlideCancelled) {
                                        _isVoiceLocked = true;
                                      }
                                    });
                                  },
                                  onLongPressEnd: (_) {
                                    if (_isSlideCancelled) {
                                      _cancelVoiceRecording();
                                    } else if (_isVoiceLocked) {
                                      // User locked recording; keep recording hands-free!
                                    } else {
                                      // Released without locking: stop holding = stop talking, enter review stage!
                                      _stopRecordingAndEnterReview();
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? MiraloColors.darkSurfaceSecondary
                                          : MiraloColors.lightSurfaceSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.mic_rounded,
                                        size: 20,
                                        color: MiraloColors.accent,
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceRecordingBar(BuildContext context, bool isDark) {
    final minutes = (_voiceSeconds ~/ 60).toString().padLeft(1, '0');
    final secs = (_voiceSeconds % 60).toString().padLeft(2, '0');

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201515) : const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(MiraloRadius.composer),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes:$secs',
            style: MiraloTypography.bodyMedium(color: Colors.redAccent)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isVoiceLocked
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Recording locked (Hands-free)',
                        style: MiraloTypography.bodySmall(color: Colors.redAccent)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                : Transform.translate(
                    offset: Offset(_dragOffsetX.clamp(-100.0, 0.0), 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        Text(
                          _isSlideCancelled
                              ? 'Release to cancel'
                              : (_dragOffsetY < -30 ? 'Locking...' : '< Slide to cancel | ^ Lock'),
                          style: MiraloTypography.bodySmall(
                            color: _isSlideCancelled
                                ? Colors.redAccent
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: _cancelVoiceRecording,
            tooltip: 'Cancel recording',
          ),
          if (_isVoiceLocked)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: MiraloColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop_rounded, color: Colors.white, size: 16),
              ),
              onPressed: _stopRecordingAndEnterReview,
              tooltip: 'Stop & review',
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceReviewBar(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final maxMs = (_reviewDuration.inMilliseconds > 0
            ? _reviewDuration.inMilliseconds
            : (_recordedReviewSeconds * 1000))
        .toDouble();
    final currentMs = _reviewPosition.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? MiraloColors.darkSurface : MiraloColors.lightSurface,
        borderRadius: BorderRadius.circular(MiraloRadius.composer),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Discard / Trash button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: MiraloColors.danger, size: 22),
            onPressed: _discardReviewVoiceNote,
            tooltip: 'Discard voice note',
          ),
          // Play / Pause preview
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MiraloColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                _isReviewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: MiraloColors.accent,
                size: 22,
              ),
              onPressed: _toggleReviewPlayback,
              tooltip: _isReviewPlaying ? 'Pause' : 'Play preview',
            ),
          ),
          const SizedBox(width: 8),
          // Audio Scrubber & Timers
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: MiraloColors.accent,
                    inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                    thumbColor: MiraloColors.accent,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: maxMs > 0 ? maxMs : 1000.0,
                    value: currentMs <= (maxMs > 0 ? maxMs : 1000.0) ? currentMs : 0.0,
                    onChanged: (val) {
                      _seekReviewAudio(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_reviewPosition),
                        style: MiraloTypography.labelSmall(color: textMuted).copyWith(fontSize: 10),
                      ),
                      Text(
                        _formatDuration(
                          _reviewDuration.inSeconds > 0
                              ? _reviewDuration
                              : Duration(seconds: _recordedReviewSeconds),
                        ),
                        style: MiraloTypography.labelSmall(color: textMuted).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Send button
          _isSendingMedia
              ? const SizedBox(
                  width: 34,
                  height: 34,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: MiraloColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: _sendReviewVoiceNote,
                    tooltip: 'Send voice note',
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSlashSuggestionsOverlay(
    List<_SlashCommand> commands,
    bool isDark,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: isDark ? MiraloColors.darkSurfaceElevated : MiraloColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 14, color: MiraloColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Available Commands',
                    style: MiraloTypography.labelMedium(color: MiraloColors.accent).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to select',
                    style: MiraloTypography.bodySmall(color: textMuted).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: border),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: commands.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: border.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final cmd = commands[index];
                  return InkWell(
                    onTap: () => _executeSlashCommand(cmd.command),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: MiraloColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(cmd.icon, size: 16, color: MiraloColors.accent),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cmd.command,
                            style: MiraloTypography.bodyMedium(color: textPrimary).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cmd.description,
                              style: MiraloTypography.bodySmall(color: textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentionSuggestionsOverlay(
    List<_MentionOption> options,
    _MentionQuery query,
    bool isDark,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: isDark ? MiraloColors.darkSurfaceElevated : MiraloColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 14, color: MiraloColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Group Mentions',
                    style: MiraloTypography.labelMedium(color: MiraloColors.accent).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to mention',
                    style: MiraloTypography.bodySmall(color: textMuted).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: border),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: border.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final opt = options[index];
                  return InkWell(
                    onTap: () => _selectMention(opt, query),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: opt.isAll
                                  ? MiraloColors.accent
                                  : MiraloColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: opt.isAll
                                ? const Icon(Icons.groups_rounded, size: 16, color: Colors.white)
                                : Center(
                                    child: Text(
                                      opt.displayName.isNotEmpty
                                          ? opt.displayName[0].toUpperCase()
                                          : '@',
                                      style: const TextStyle(
                                        color: MiraloColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '@${opt.label}',
                            style: MiraloTypography.bodyMedium(color: textPrimary).copyWith(
                              fontWeight: FontWeight.w700,
                              color: opt.isAll ? MiraloColors.accent : textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt.displayName,
                              style: MiraloTypography.bodySmall(color: textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
