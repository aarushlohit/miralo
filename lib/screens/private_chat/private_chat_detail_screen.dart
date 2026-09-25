import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../models/friend_request_model.dart';
import '../../models/private_contact_model.dart';
import '../../models/private_message_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/download_service.dart';
import '../../widgets/chat/chat_header.dart';
import '../../widgets/chat/chat_scaffold.dart';
import '../../widgets/chat/composer.dart';
import '../../widgets/chat/message_actions.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/chat/message_renderer.dart';
import '../../widgets/chat/pinned_messages_banner.dart';
import '../../widgets/chat/pinned_messages_sheet.dart';
import '../../widgets/chat/reaction_sheet.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/common/miralo_avatar.dart';
import 'group_profile_screen.dart';

/// Private Chat Screen
/// Uses the exact same Chat UI components as AI Chat:
/// - ChatScaffold
/// - ChatHeader (Back, Editable display name e.g. 'Mira', More menu with 'Return to Chat')
/// - MessageList
/// - MessageRenderer (neutral surfaces, zero romantic/messaging styling)
/// - Composer (images only converted to Base64, /urgent and /clear interception)
/// - ReactionSheet & MessageActionsSheet
class PrivateChatDetailScreen extends StatefulWidget {
  const PrivateChatDetailScreen({super.key});

  @override
  State<PrivateChatDetailScreen> createState() => _PrivateChatDetailScreenState();
}

class _PrivateChatDetailScreenState extends State<PrivateChatDetailScreen> {
  String? _replyToText;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<int> _searchMatchIndices = [];
  int _currentMatchIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _getMessageKey(String messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
    setState(() {
      _highlightedMessageId = messageId;
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  void _performSearch(String query, List<PrivateMessageModel> messages) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchMatchIndices = [];
        _currentMatchIndex = 0;
        _highlightedMessageId = null;
      });
      return;
    }
    final q = query.toLowerCase();
    final matches = <int>[];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].text.toLowerCase().contains(q) ||
          (messages[i].fileName?.toLowerCase().contains(q) ?? false)) {
        matches.add(i);
      }
    }
    setState(() {
      _searchMatchIndices = matches;
      _currentMatchIndex = matches.isNotEmpty ? matches.length - 1 : 0;
    });
    if (matches.isNotEmpty) {
      _jumpToSearchMatch(messages);
    }
  }

  void _jumpToSearchMatch(List<PrivateMessageModel> messages) {
    if (_searchMatchIndices.isEmpty) return;
    final matchMsgIndex = _searchMatchIndices[_currentMatchIndex];
    final msg = messages[matchMsgIndex];
    _scrollToMessage(msg.id);
  }

  void _previousSearchMatch(List<PrivateMessageModel> messages) {
    if (_searchMatchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatchIndices.length) % _searchMatchIndices.length;
    });
    _jumpToSearchMatch(messages);
  }

  void _nextSearchMatch(List<PrivateMessageModel> messages) {
    if (_searchMatchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatchIndices.length;
    });
    _jumpToSearchMatch(messages);
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchMatchIndices = [];
      _currentMatchIndex = 0;
      _highlightedMessageId = null;
    });
  }

  String? _getDateHeader(int index, List<PrivateMessageModel> messages) {
    if (index >= messages.length) return null;
    final currentMsg = messages[index];
    if (index == 0) {
      return _formatDateLabel(currentMsg.createdAt);
    }
    final prevMsg = messages[index - 1];
    final isSameDay = currentMsg.createdAt.year == prevMsg.createdAt.year &&
        currentMsg.createdAt.month == prevMsg.createdAt.month &&
        currentMsg.createdAt.day == prevMsg.createdAt.day;
    if (!isSameDay) {
      return _formatDateLabel(currentMsg.createdAt);
    }
    return null;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(msgDate).inDays;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${date.day}, ${months[date.month - 1]} ${date.year}';

    if (difference == 0) return 'Today • $dateStr';
    if (difference == 1) return 'Yesterday • $dateStr';
    return dateStr;
  }

  void _showStarredMessagesSheet(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel? contact,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final starred = chat.getStarredMessages(contact?.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(MiraloSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Starred Messages (${starred.length})',
                        style: MiraloTypography.titleMedium(
                          color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              if (starred.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No starred messages yet',
                          style: MiraloTypography.bodyMedium(
                            color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Long press any message and tap "Star Message"',
                          style: MiraloTypography.caption(
                            color: isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: starred.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final msg = starred[i];
                      final isMe = chat.isMyMessage(msg);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(
                          isMe ? 'You' : (msg.senderName ?? contact?.displayName ?? 'Contact'),
                          style: MiraloTypography.caption(color: MiraloColors.accent).copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          msg.text.isNotEmpty
                              ? msg.text
                              : (msg.fileName ?? '[Attachment]'),
                          style: MiraloTypography.bodyMedium(
                            color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                          tooltip: 'Unstar',
                          onPressed: () {
                            chat.toggleStarMessage(msg);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message unstarred'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _scrollToMessage(msg.id);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showContactProfileSheet(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel contact,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary;
    final textMuted = isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted;
    final isFriend = chat.contacts.any((c) => c.id == contact.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(MiraloSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              MiraloAvatar(
                name: contact.displayName,
                imageUrl: contact.avatarUrl,
                size: 80,
                note: contact.note,
              ),
              const SizedBox(height: 12),
              Text(
                contact.displayName,
                style: MiraloTypography.titleMedium(color: textPrimary).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (contact.username.isNotEmpty)
                Text('@${contact.username}', style: MiraloTypography.caption(color: textMuted)),
              if (contact.phoneNumber != null)
                Text(contact.phoneNumber!, style: MiraloTypography.caption(color: textMuted)),
              if (contact.note != null && contact.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('💭 "${contact.note}"', style: MiraloTypography.bodySmall(color: textPrimary).copyWith(fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: MiraloSpacing.md),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                title: const Text('Starred Messages'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStarredMessagesSheet(context, chat, contact);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search_rounded, color: MiraloColors.accent),
                title: const Text('Search in Chat'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _isSearching = true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Display Name'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDisplayNameDialog(context, chat, contact);
                },
              ),
              if (!isFriend)
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.green),
                  title: const Text('Send Friend Request'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await chat.sendFriendRequest(
                      senderId: auth.currentUser?.id ?? 'me',
                      senderName: auth.currentUser?.displayName ?? 'User',
                      senderUsername: auth.currentUser?.username ?? 'user',
                      targetUsernameOrEmail: contact.username,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Friend request sent to ${contact.displayName}')),
                      );
                    }
                  },
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _quickExit(BuildContext context) {
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final ai = Provider.of<AiChatProvider>(context, listen: false);

    // Lock private access & clear private state
    vault.lockAll();

    // Return to last AI conversation safely with home as root
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
    if (ai.activeChat != null) {
      Navigator.pushNamed(context, AppRoutes.aiChat);
    } else {
      ai.prefillPrompt('What is an API?');
    }
  }

  void _showMoreMenu(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel? contact,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MiraloColors.darkSurfacePrimary
        : MiraloColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? MiraloColors.darkTextPrimary
        : MiraloColors.lightTextPrimary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MiraloRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MiraloSpacing.lg,
            vertical: MiraloSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: MiraloSpacing.md),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Preferred label: Return to Chat
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded,
                    color: MiraloColors.accent, size: 22),
                title: Text(
                  'Return to Chat',
                  style: MiraloTypography.bodyMedium(color: MiraloColors.accent)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickExit(context);
                },
              ),

              // Search in Chat
              ListTile(
                leading: const Icon(Icons.search_rounded,
                    color: MiraloColors.accent, size: 22),
                title: Text(
                  'Search in Chat',
                  style: MiraloTypography.bodyMedium(color: textPrimary),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _isSearching = true);
                },
              ),

              // Starred Messages
              ListTile(
                leading: const Icon(Icons.star_rounded,
                    color: Color(0xFFF59E0B), size: 22),
                title: Text(
                  'Starred Messages',
                  style: MiraloTypography.bodyMedium(color: textPrimary),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _showStarredMessagesSheet(context, chat, contact);
                },
              ),

              // Group / Contact Info
              if (contact != null)
                ListTile(
                  leading: Icon(
                    contact.isGroup ? Icons.group_outlined : Icons.person_outline_rounded,
                    color: textPrimary,
                    size: 22,
                  ),
                  title: Text(
                    contact.isGroup ? 'Group Info' : 'Contact Info',
                    style: MiraloTypography.bodyMedium(color: textPrimary),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (contact.isGroup) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupProfileScreen(groupId: contact.id),
                        ),
                      );
                    } else {
                      _showContactProfileSheet(context, chat, contact);
                    }
                  },
                ),

              // Edit display name
              if (contact != null)
                ListTile(
                  leading: Icon(Icons.edit_outlined,
                      color: textPrimary, size: 22),
                  title: Text(
                    'Edit display name',
                    style: MiraloTypography.bodyMedium(color: textPrimary),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDisplayNameDialog(context, chat, contact);
                  },
                ),

              // Clear conversation
              ListTile(
                leading: Icon(Icons.clear_all_rounded,
                    color: textPrimary, size: 22),
                title: Text(
                  'Clear conversation',
                  style: MiraloTypography.bodyMedium(color: textPrimary),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  chat.clearActiveChat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation cleared.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // Delete contact
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: MiraloColors.danger, size: 22),
                title: Text(
                  'Delete conversation',
                  style: MiraloTypography.bodyMedium(
                      color: MiraloColors.danger),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  chat.deleteCurrentChat();
                  Navigator.pop(context);
                },
              ),

              // Block / Unblock contact
              if (contact != null && !contact.isGroup)
                ListTile(
                  leading: Icon(
                    chat.isBlocked(contact.id) ? Icons.lock_open_rounded : Icons.block_rounded,
                    color: chat.isBlocked(contact.id) ? textPrimary : MiraloColors.danger,
                    size: 22,
                  ),
                  title: Text(
                    chat.isBlocked(contact.id) ? 'Unblock contact' : 'Block contact',
                    style: MiraloTypography.bodyMedium(
                      color: chat.isBlocked(contact.id) ? textPrimary : MiraloColors.danger,
                    ),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (chat.isBlocked(contact.id)) {
                      chat.unblockUser(contact.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('@${contact.username} has been unblocked.')),
                      );
                      return;
                    }

                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final cur = auth.currentUser?.username.toLowerCase().trim() ?? '';
                    final target = contact.username.toLowerCase().trim();

                    if ((cur == 'ashlinmirsha' && target == 'aarushlohit') ||
                        (cur == 'aarushlohit' && target == 'ashlinmirsha')) {
                      final msg = cur == 'ashlinmirsha'
                          ? "! how u can block your future hubby go cuddle him"
                          : "bruh you made me for chatting with your loved one's how u can block its wrong !!!";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: MiraloColors.accent,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Block contact?'),
                        content: Text('Are you sure you want to block @${contact.username}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dCtx);
                              final ok = await chat.blockUser(
                                targetId: contact.id,
                                targetUsername: contact.username,
                                targetDisplayName: contact.displayName,
                                currentUsername: cur,
                              );
                              if (!ok) {
                                if (context.mounted) {
                                  final msg = cur == 'ashlinmirsha'
                                      ? "bruh you made me for chatting with your loved one's how u can block its wrong !!! how u can block your future hubby go cuddle him"
                                      : "bruh you made me for chatting with your loved one's how u can block its wrong !!!";
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: MiraloColors.accent,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                                return;
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('@${contact.username} has been blocked.')),
                                );
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Block'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: MiraloSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDisplayNameDialog(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel contact,
  ) {
    final controller = TextEditingController(text: contact.displayName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? MiraloColors.darkSurfacePrimary
            : MiraloColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: MiraloRadius.r20),
        title: Text(
          'Edit display name',
          style: MiraloTypography.titleMedium(
            color: isDark
                ? MiraloColors.darkTextPrimary
                : MiraloColors.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: MiraloTypography.bodyMedium(
            color: isDark
                ? MiraloColors.darkTextPrimary
                : MiraloColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Display name',
            hintStyle: MiraloTypography.bodyMedium(
              color: isDark
                  ? MiraloColors.darkTextMuted
                  : MiraloColors.lightTextMuted,
            ),
            filled: true,
            fillColor: isDark
                ? MiraloColors.darkSurfaceSecondary
                : MiraloColors.lightSurfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: MiraloRadius.r12,
              borderSide: BorderSide(
                color: isDark
                    ? MiraloColors.darkBorder
                    : MiraloColors.lightBorder,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: MiraloTypography.labelMedium(
                color: isDark
                    ? MiraloColors.darkTextMuted
                    : MiraloColors.lightTextMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                chat.updateContactDisplayName(contact.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: MiraloTypography.labelMedium(color: MiraloColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    PrivateMessageModel msg,
    PrivateChatProvider chat,
    LibraryProvider library,
  ) {
    MessageActionsSheet.show(
      context,
      text: msg.text,
      onReact: () {
        ReactionSheet.show(
          context,
          onSelectEmoji: (emoji) => chat.toggleReaction(msg.id, emoji),
        );
      },
      onReply: () {
        setState(() {
          _replyToText = msg.text.isNotEmpty
              ? msg.text
              : (msg.type == 'image' ? '[Photo Attachment]' : '[Media]');
        });
      },
      onDownload: (msg.mediaUrl != null || msg.imageBase64 != null)
          ? () => _downloadMessageMedia(context, msg)
          : null,
      onFavorite: msg.isGif
          ? () {
              chat.toggleFavoriteMessage(msg);
              final isFav = chat.isMessageFavorite(msg.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFav ? 'Added to Favorites GIF ⭐' : 'Removed from Favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          : null,
      isFavorite: chat.isMessageFavorite(msg.id),
      onStar: () {
        chat.toggleStarMessage(msg);
        final isStarred = chat.isMessageStarred(msg.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isStarred ? 'Message starred ⭐' : 'Message unstarred'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      isStarred: chat.isMessageStarred(msg.id),
      onPin: () async {
        final ok = await chat.togglePinMessage(msg);
        if (!context.mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only pin up to 6 messages. Unpin a message first.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          final isPinned = chat.isMessagePinned(msg.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isPinned
                  ? 'Message pinned 📌 (${chat.getPinnedMessageCount()}/6)'
                  : 'Message unpinned'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      isPinned: msg.isPinned,
      onSaveToLibrary: () {
        chat.saveMessageToLibrary(msg, library);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Library'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onMoveToVault: () {
        chat.moveMessageToPrivateVault(msg, library);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moved to Private Vault'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onDelete: () => chat.deleteMessage(msg.id),
    );
  }

  Future<void> _downloadMessageMedia(BuildContext context, PrivateMessageModel msg) async {
    try {
      Uint8List? fileBytes;
      if (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty) {
        fileBytes = base64Decode(msg.imageBase64!);
      } else if (msg.mediaUrl != null && msg.mediaUrl!.startsWith('http')) {
        final resp = await http.get(Uri.parse(msg.mediaUrl!));
        if (resp.statusCode == 200) {
          fileBytes = resp.bodyBytes;
        }
      }

      if (fileBytes != null && context.mounted) {
        final ext = msg.type == 'image'
            ? 'jpg'
            : (msg.type == 'voice' ? 'm4a' : 'bin');
        final fname = msg.fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await DownloadService.downloadAndPrompt(
          context,
          fileName: fname,
          bytes: fileBytes,
          type: msg.type,
        );
      }
    } catch (e) {
      debugPrint('Error downloading media: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final chat = Provider.of<PrivateChatProvider>(context, listen: false);
      chat.initUserSession(
        auth.currentUser!.id,
        username: auth.currentUser?.username,
        email: auth.currentUser?.email,
        displayName: auth.currentUser?.displayName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<PrivateChatProvider>(context);
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final contact = chat.activeContact;
    final messages = chat.activeMessages;

    final displayName = contact?.displayName ?? 'Mira';
    final isTyping = contact != null && chat.isContactTyping(contact.id);
    final subtitle = isTyping
        ? 'typing...'
        : (contact?.isGroup == true
            ? '${contact?.memberIds.length ?? 0} members'
            : (contact?.isOnline == true
                ? 'Online'
                : (contact?.lastSeenText ?? 'Active recently')));

    final pinnedMessages = chat.getPinnedMessages(contact?.id);

    return ChatScaffold(
      header: ChatHeader(
        isPrivate: true,
        title: displayName,
        subtitle: subtitle,
        avatarUrl: contact?.avatarUrl,
        isGroup: contact?.isGroup == true,
        onBack: () => Navigator.pop(context),
        onAvatarTap: contact != null
            ? () {
                if (contact.isGroup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupProfileScreen(groupId: contact.id),
                    ),
                  );
                } else {
                  _showContactProfileSheet(context, chat, contact);
                }
              }
            : null,
        onDoubleTapAvatar: () => _panicExitToAiChat(context),
        onEditDisplayName: contact != null
            ? () {
                if (contact.isGroup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupProfileScreen(groupId: contact.id),
                    ),
                  );
                } else {
                  _showEditDisplayNameDialog(context, chat, contact);
                }
              }
            : null,
        onMoreOptions: () => _showMoreMenu(context, chat, contact),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? MiraloColors.darkSurfaceSecondary : MiraloColors.lightSurfaceSecondary,
                border: Border(bottom: BorderSide(color: isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder, width: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search chat...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (query) => _performSearch(query, messages),
                    ),
                  ),
                  if (_searchMatchIndices.isNotEmpty) ...[
                    Text(
                      '${_currentMatchIndex + 1} of ${_searchMatchIndices.length}',
                      style: MiraloTypography.caption(color: isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                      onPressed: () => _previousSearchMatch(messages),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                      onPressed: () => _nextSearchMatch(messages),
                    ),
                  ] else if (_searchController.text.isNotEmpty) ...[
                    Text('0 matches', style: MiraloTypography.caption(color: isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted)),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _closeSearch,
                  ),
                ],
              ),
            ),
          if (pinnedMessages.isNotEmpty)
            PinnedMessagesBanner(
              pinnedMessages: pinnedMessages,
              currentUserId: auth.currentUser?.id,
              onTapMessage: (msg) => _scrollToMessage(msg.id),
              onUnpinMessage: (msg) async {
                await chat.togglePinMessage(msg);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message unpinned'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              onViewAll: () => PinnedMessagesSheet.show(
                context,
                pinnedMessages: pinnedMessages,
                onTapMessage: (msg) => _scrollToMessage(msg.id),
                onUnpinMessage: (msg) => chat.togglePinMessage(msg),
                onUnpinAll: () => chat.clearAllPinnedMessages(contact?.id ?? chat.activeChatId ?? ''),
              ),
            ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: MiraloTypingIndicator(
                showBubble: true,
                userName: contact.displayName,
              ),
            ),
          Expanded(
            child: MessageList(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = chat.isMyMessage(msg);
                return MessageRenderer(
                  key: _getMessageKey(msg.id),
                  id: msg.id,
                  text: msg.text,
                  isMe: isMe,
                  isPinned: msg.isPinned,
                  isStarred: msg.isStarred,
                  dateHeader: _getDateHeader(index, messages),
                  isHighlighted: _highlightedMessageId == msg.id,
                  senderName: isMe ? null : (msg.senderName ?? displayName),
                  createdAt: msg.createdAt,
                  imageBase64: msg.imageBase64,
                  imageUrl: msg.mediaUrl,
                  type: msg.type,
                  fileName: msg.fileName,
                  fileSize: msg.fileSize,
                  status: msg.status,
                  replyToText: msg.replyToText,
                  reactions: msg.reactions,
                  onReactionTap: (emoji) => chat.toggleReaction(msg.id, emoji),
                  onDownload: (msg.mediaUrl != null || msg.imageBase64 != null)
                      ? () => _downloadMessageMedia(context, msg)
                      : null,
                  onSaveToLibrary: () {
                    chat.saveMessageToLibrary(msg, library);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to Library Vault.')),
                    );
                  },
                  onMoveToVault: () {
                    chat.moveMessageToPrivateVault(msg, library);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moved to Library Vault (Removed from chat).')),
                    );
                  },
                  onLongPress: () => _showMessageOptions(context, msg, chat, library),
                );
              },
            ),
          ),
        ],
      ),
      composer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active reply/retag bar banner if selected
          if (_replyToText != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: MiraloSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E7EB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(left: BorderSide(color: MiraloColors.accent, width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: MiraloColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to: "$_replyToText"',
                      style: MiraloTypography.bodySmall(
                        color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyToText = null),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ],
              ),
            ),
          // Blocked Contact Banner
          if (contact != null && chat.isBlocked(contact.id))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have blocked @${contact.username}.',
                      style: MiraloTypography.bodySmall(
                        color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      chat.unblockUser(contact.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('@${contact.username} has been unblocked.')),
                      );
                    },
                    child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Cold DM / Non-contact Relationship Banner
          if (contact != null && !chat.isBlocked(contact.id) && !chat.isContact(contact.id, contact.username))
            Builder(
              builder: (ctx) {
                FriendRequestModel? incomingReq;
                try {
                  incomingReq = chat.pendingFriendRequests.firstWhere(
                    (r) => r.senderId == contact.id || r.senderUsername.toLowerCase() == contact.username.toLowerCase(),
                  );
                } catch (_) {}

                final sentStatus = chat.getSentRequestStatus(contact.username) ?? chat.getSentRequestStatus(contact.id);

                if (incomingReq != null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: MiraloColors.accent.withValues(alpha: 0.12),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_outlined, size: 16, color: MiraloColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '@${contact.username} sent you a friend request.',
                            style: MiraloTypography.bodySmall(
                              color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MiraloColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            chat.respondToFriendRequest(incomingReq!, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Accepted friend request from @${contact.username}')),
                            );
                          },
                          child: const Text('Accept', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? MiraloColors.darkTextMuted : MiraloColors.lightTextMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            chat.respondToFriendRequest(incomingReq!, false);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Decline', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                if (sentStatus == 'pending') {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E7EB),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Friend request sent to @${contact.username} (Pending acceptance).',
                            style: MiraloTypography.bodySmall(
                              color: isDark ? MiraloColors.darkTextSecondary : MiraloColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: MiraloColors.accent.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined, size: 16, color: MiraloColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '@${contact.username} is not in your contacts.',
                          style: MiraloTypography.bodySmall(
                            color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MiraloColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          chat.sendFriendRequest(
                            senderId: auth.currentUser?.id ?? 'me',
                            senderName: auth.currentUser?.displayName ?? 'User',
                            senderUsername: auth.currentUser?.username ?? 'user',
                            targetUsernameOrEmail: contact.username,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Friend request sent to @${contact.username}')),
                          );
                        },
                        child: const Text('Add Friend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

          if (chat.coldDmLimitReached)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: MiraloColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct message limit reached (1 message). Further messages require an accepted friend request.',
                      style: MiraloTypography.bodySmall(
                        color: isDark ? MiraloColors.darkTextSecondary : MiraloColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Composer(
            isPrivate: true,
            isGroup: contact?.isGroup == true,
            groupMembers: contact != null ? chat.getGroupMembers(contact) : const [],
            onJumpToMessage: (id) => _scrollToMessage(id),
            onOpenPinnedMessages: () => PinnedMessagesSheet.show(
              context,
              pinnedMessages: pinnedMessages,
              onTapMessage: (msg) => _scrollToMessage(msg.id),
              onUnpinMessage: (msg) => chat.togglePinMessage(msg),
              onUnpinAll: () => chat.clearAllPinnedMessages(contact?.id ?? chat.activeChatId ?? ''),
            ),
            hintText: contact != null && chat.isBlocked(contact.id)
                ? 'User is blocked. Unblock to message.'
                : (chat.coldDmLimitReached
                    ? 'Friend request pending acceptance...'
                    : 'Message $displayName...'),
            onSubmitted: (text) {
              if (contact != null && chat.isBlocked(contact.id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unblock @${contact.username} to send messages.')),
                );
                return;
              }
              if (chat.coldDmLimitReached) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot send more messages until friend request is accepted.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              chat.sendTextMessage(text, replyToText: _replyToText);
              if (_replyToText != null) setState(() => _replyToText = null);
            },
            onMediaSubmitted: (type, urlOrBase64, fileName, fileSize, captionText) {
              if (contact != null && chat.isBlocked(contact.id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unblock @${contact.username} to send files.')),
                );
                return;
              }
              if (chat.coldDmLimitReached) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot send files until friend request is accepted.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              chat.sendMediaMessage(
                type: type,
                mediaUrl: urlOrBase64.startsWith('http') ? urlOrBase64 : null,
                imageBase64: urlOrBase64.startsWith('http') ? null : urlOrBase64,
                text: captionText,
                fileName: fileName,
                fileSize: fileSize,
              );
              if (_replyToText != null) setState(() => _replyToText = null);
            },
          ),
        ],
      ),
    );
  }

  void _panicExitToAiChat(BuildContext context) {
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final ai = Provider.of<AiChatProvider>(context, listen: false);

    // Instantly lock all secret vaults & conversations
    vault.lockAll();

    // Immediately route to home with clean stack, then optionally push active AI chat
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
    if (ai.activeChat != null) {
      Navigator.pushNamed(context, AppRoutes.aiChat);
    } else {
      ai.prefillPrompt('Can you explain quantum computing simply?');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workspace locked. Switched to AI chat.'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
