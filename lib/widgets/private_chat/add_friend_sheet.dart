import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../common/miralo_avatar.dart';

class AddFriendSheet extends StatefulWidget {
  final int initialTab;
  const AddFriendSheet({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (_) => AddFriendSheet(initialTab: initialTab),
    );
  }

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isCreatingGroup = false;
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
    final res = await privateChat.searchUsersByQuery(query);
    if (mounted) {
      setState(() {
        _searchResults = res;
        _isSearching = false;
      });
    }
  }

  /// Returns 'contact' | 'pending' | 'accepted' | 'rejected' | 'blocked' | null
  String? _resolveStatus(
    PrivateChatProvider chat,
    String targetId,
    String targetUsername,
  ) {
    if (chat.isBlocked(targetId)) return 'blocked';
    if (chat.isContact(targetId, targetUsername)) return 'contact';
    final sentStatus = chat.getSentRequestStatus(targetUsername) ??
        chat.getSentRequestStatus(targetId);
    return sentStatus; // 'pending' | 'accepted' | 'rejected' | null
  }

  Widget _buildActionButton({
    required String? status,
    required bool isDark,
    required Color textMuted,
    required VoidCallback onAdd,
    VoidCallback? onUnblock,
    required String targetUsername,
  }) {
    switch (status) {
      case 'contact':
      case 'accepted':
        return _statusChip(
          label: 'Added ✓',
          bg: Colors.green.withValues(alpha: 0.15),
          fg: Colors.green,
        );
      case 'pending':
        return _statusChip(
          label: 'Sent ✓',
          bg: isDark ? Colors.white10 : Colors.grey.shade200,
          fg: textMuted,
        );
      case 'blocked':
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onUnblock,
          child: const Text('Unblock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        );
      case 'rejected':
      default:
        // rejected → allow re-sending; null → first time
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onAdd,
          child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        );
    }
  }

  Widget _statusChip({required String label, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _handleBlockUser({
    required BuildContext context,
    required PrivateChatProvider chat,
    required String? currentUsername,
    required String targetId,
    required String targetUsername,
    required String displayName,
  }) {
    final cur = (currentUsername ?? chat.currentUsername ?? '').toLowerCase().trim();
    final target = targetUsername.toLowerCase().trim();

    if ((cur == 'ashlinmirsha' && target == 'aarushlohit') ||
        (cur == 'aarushlohit' && target == 'ashlinmirsha')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("bruh you made me for chatting with your loved one's how u can block its wrong !!!"),
          backgroundColor: AppColors.accent,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    _showBlockConfirm(context, chat, currentUsername, targetId, targetUsername, displayName);
  }

  void _showBlockConfirm(
    BuildContext context,
    PrivateChatProvider chat,
    String? currentUsername,
    String targetId,
    String targetUsername,
    String displayName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user?'),
        content: Text(
          'Blocking @$targetUsername will prevent them from sending you messages or friend requests. '
          'They won\'t be notified.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await chat.blockUser(
                targetId: targetId,
                targetUsername: targetUsername,
                targetDisplayName: displayName,
                currentUsername: currentUsername,
              );
              if (!ok) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("bruh you made me for chatting with your loved one's how u can block its wrong !!!"),
                      backgroundColor: AppColors.accent,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
                return;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('@$targetUsername has been blocked.')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirm(
    BuildContext context,
    PrivateChatProvider chat,
    String targetId,
    String targetUsername,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock user?'),
        content: Text('Allow @$targetUsername to contact you again?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              chat.unblockUser(targetId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('@$targetUsername has been unblocked.')),
              );
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final privateChat = Provider.of<PrivateChatProvider>(context);
    final currentUser = auth.currentUser;
    final currentUid = currentUser?.id ?? '';
    final currentUname = (currentUser?.username ?? '').toLowerCase().trim();
    final currentUemail = (currentUser?.email ?? '').toLowerCase().trim();
    final visibleResults = _searchResults.where((item) {
      final uid = (item['id'] ?? '').toString().trim();
      final uname = (item['username'] ?? '').toString().toLowerCase().trim();
      final uemail = (item['email'] ?? '').toString().toLowerCase().trim();
      if (currentUid.isNotEmpty && uid == currentUid) return false;
      if (currentUname.isNotEmpty && uname == currentUname) return false;
      if (currentUemail.isNotEmpty && uemail == currentUemail) return false;
      return true;
    }).toList();
    final pendingRequests = privateChat.pendingFriendRequests;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.person_add_outlined, color: AppColors.accent, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Find & Connect', style: AppTypography.heading3(color: textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Search for users or manage incoming invitations.',
                style: AppTypography.bodySmall(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.md),

              // Segmented Tab Switcher (Search vs Invitations)
              Container(
                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isDark ? AppColors.darkSurfacePrimary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 0
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'Search',
                              style: AppTypography.label(
                                color: _selectedTab == 0 ? textPrimary : textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isDark ? AppColors.darkSurfacePrimary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 1
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Invitations',
                                style: AppTypography.label(
                                  color: _selectedTab == 1 ? textPrimary : textMuted,
                                ),
                              ),
                              if (pendingRequests.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pendingRequests.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 2
                                ? (isDark ? AppColors.darkSurfacePrimary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 2
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'New Group',
                              style: AppTypography.label(
                                color: _selectedTab == 2 ? textPrimary : textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_selectedTab == 0) ...[
                // ── Search Tab ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 0.8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: AppTypography.bodyMedium(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter username or email...',
                      hintStyle: AppTypography.bodyMedium(color: textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    ),
                  )
                else if (_searchController.text.trim().isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Type a username above to search for people',
                        style: AppTypography.caption(color: textMuted),
                      ),
                    ),
                  )
                else if (visibleResults.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No users found for "${_searchController.text}"',
                          style: AppTypography.caption(color: textMuted)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: visibleResults.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: border),
                      itemBuilder: (ctx, i) {
                        final item = visibleResults[i];
                        final name = item['name'] ?? 'User';
                        final username = item['username'] ?? '';
                        final targetId = item['id'] ?? 'usr_$username';
                        final status = _resolveStatus(privateChat, targetId, username);
                        final blocked = status == 'blocked';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              MiraloAvatar(name: name, size: 36, isOnline: !blocked),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(name, style: AppTypography.bodyMedium(color: textPrimary)),
                                        if (blocked) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.block_rounded, size: 13, color: Colors.red.withValues(alpha: 0.8)),
                                        ],
                                      ],
                                    ),
                                    Text('@$username', style: AppTypography.caption(color: textMuted)),
                                  ],
                                ),
                              ),

                              // Chat icon (only if not blocked)
                              if (!blocked)
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                                      color: AppColors.accent, size: 20),
                                  tooltip: 'Chat',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    if (currentUser != null) {
                                      privateChat.initUserSession(
                                        currentUser.id,
                                        username: currentUser.username,
                                        email: currentUser.email,
                                      );
                                    }
                                    privateChat.setActiveChat(targetId, displayName: name, username: username);
                                    Navigator.pop(ctx);
                                    Navigator.pushNamed(context, AppRoutes.privateChat);
                                  },
                                ),

                              // ── 3-state action button ──
                              _buildActionButton(
                                status: status,
                                isDark: isDark,
                                textMuted: textMuted,
                                targetUsername: username,
                                onAdd: () {
                                  privateChat.sendFriendRequest(
                                    senderId: currentUser?.id ?? 'me',
                                    senderName: currentUser?.displayName ?? 'User',
                                    senderUsername: currentUser?.username ?? 'user',
                                    targetUsernameOrEmail: username,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Friend request sent to @$username'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                onUnblock: () {
                                  _showUnblockConfirm(context, privateChat, targetId, username);
                                },
                              ),

                              const SizedBox(width: 4),

                              // ── ••• popup menu ──
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, size: 18, color: textMuted),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                itemBuilder: (_) => [
                                  if (!blocked)
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.block_rounded, size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Block user', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    )
                                  else
                                    PopupMenuItem(
                                      value: 'unblock',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.lock_open_rounded, size: 16),
                                          SizedBox(width: 8),
                                          Text('Unblock user'),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (val) {
                                  if (val == 'block') {
                                    _handleBlockUser(
                                      context: context,
                                      chat: privateChat,
                                      currentUsername: currentUser?.username,
                                      targetId: targetId,
                                      targetUsername: username,
                                      displayName: name,
                                    );
                                  } else if (val == 'unblock') {
                                    _showUnblockConfirm(context, privateChat, targetId, username);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ] else ...[
                // ── Invitations Tab ─────────────────────────────────────────
                if (pendingRequests.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 40, color: textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('No pending invitations', style: AppTypography.bodyMedium(color: textMuted)),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pendingRequests.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: border),
                      itemBuilder: (ctx, i) {
                        final req = pendingRequests[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              MiraloAvatar(name: req.senderName, size: 36, isOnline: true),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(req.senderName, style: AppTypography.bodyMedium(color: textPrimary)),
                                    Text('@${req.senderUsername}', style: AppTypography.caption(color: textMuted)),
                                  ],
                                ),
                              ),
                              // Accept Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  privateChat.respondToFriendRequest(req, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Accepted friend request from @${req.senderUsername}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Text('Accept', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              // Decline Button
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textMuted,
                                  side: BorderSide(color: border),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  privateChat.respondToFriendRequest(req, false);
                                },
                                child: const Text('Decline', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 4),
                              // Block from invitations tab too
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, size: 18, color: textMuted),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'block',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.block_rounded, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Block user', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (val) {
                                  if (val == 'block') {
                                    _handleBlockUser(
                                      context: context,
                                      chat: privateChat,
                                      currentUsername: currentUser?.username,
                                      targetId: req.senderId,
                                      targetUsername: req.senderUsername,
                                      displayName: req.senderName,
                                    );
                                    // Also decline the request
                                    privateChat.respondToFriendRequest(req, false);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
               ],
              if (_selectedTab == 2) ...[
                _buildNewGroupTab(
                  context: context,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  border: border,
                  surfaceSecondary: surfaceSecondary,
                  privateChat: privateChat,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildNewGroupTab({
    required BuildContext context,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required Color surfaceSecondary,
    required PrivateChatProvider privateChat,
  }) {
    final friends = privateChat.contacts.where((c) => !c.isGroup).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Name Input
        Container(
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 0.8),
          ),
          child: TextField(
            controller: _groupNameController,
            style: AppTypography.bodyMedium(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter group name...',
              hintStyle: AppTypography.bodyMedium(color: textMuted),
              prefixIcon: const Icon(Icons.group_outlined, size: 20, color: AppColors.accent),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Member selection header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT MEMBERS',
              style: AppTypography.caption(color: textMuted).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8),
            ),
            Text(
              '${_selectedMemberIds.length} selected',
              style: AppTypography.caption(color: AppColors.accent).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Friends list or empty state
        if (friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 36, color: textMuted),
                const SizedBox(height: 8),
                Text(
                  'No contacts available',
                  style: AppTypography.bodyMedium(color: textPrimary).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add friends via the Search tab before creating a group.',
                  style: AppTypography.caption(color: textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: friends.length,
              itemBuilder: (ctx, idx) {
                final friend = friends[idx];
                final isSelected = _selectedMemberIds.contains(friend.id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMemberIds.remove(friend.id);
                      } else {
                        _selectedMemberIds.add(friend.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        MiraloAvatar(name: friend.displayName, imageUrl: friend.avatarUrl, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(friend.displayName, style: AppTypography.bodySmall(color: textPrimary).copyWith(fontWeight: FontWeight.w600)),
                              Text('@${friend.username}', style: AppTypography.caption(color: textMuted)),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.accent : textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // Create Group Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
              disabledForegroundColor: textMuted,
            ),
            onPressed: (_groupNameController.text.trim().isNotEmpty && _selectedMemberIds.isNotEmpty && !_isCreatingGroup)
                ? () async {
                    setState(() => _isCreatingGroup = true);
                    final name = _groupNameController.text.trim();
                    final groupId = await privateChat.createGroupChat(
                      groupName: name,
                      memberIds: _selectedMemberIds.toList(),
                    );
                    if (!mounted) return;
                    Navigator.pop(this.context);
                    if (groupId != null) {
                      privateChat.setActiveChat(groupId, displayName: name);
                      Navigator.pushNamed(this.context, AppRoutes.privateChat);
                    }
                  }
                : null,
            child: _isCreatingGroup
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Group Chat', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
