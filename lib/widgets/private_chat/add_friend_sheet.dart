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
  const AddFriendSheet({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (_) => const AddFriendSheet(),
    );
  }

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final privateChat = Provider.of<PrivateChatProvider>(context, listen: false);
    final currentUser = auth.currentUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
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
                  Text('Add Friend', style: AppTypography.heading3(color: textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Search users by username or email. Anyone can send a first message or request mutual friendship.',
                style: AppTypography.bodySmall(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
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
              else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No users found for "${_searchController.text}"',
                        style: AppTypography.caption(color: textMuted)),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: border),
                    itemBuilder: (ctx, i) {
                      final item = _searchResults[i];
                      final name = item['name'] ?? 'User';
                      final username = item['username'] ?? '';
                      final targetId = item['id'] ?? 'usr_$username';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            MiraloAvatar(name: name, size: 36, isOnline: true),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: AppTypography.bodyMedium(color: textPrimary)),
                                  Text('@$username', style: AppTypography.caption(color: textMuted)),
                                ],
                              ),
                            ),
                            // Quick Chat Bubble (First message flow)
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded,
                                  color: AppColors.accent, size: 20),
                              tooltip: 'Send first message',
                              onPressed: () {
                                privateChat.sendFriendRequest(
                                  senderId: currentUser?.id ?? 'me',
                                  senderName: currentUser?.displayName ?? 'User',
                                  senderUsername: currentUser?.username ?? 'user',
                                  targetUsernameOrEmail: username,
                                );
                                privateChat.setActiveChat(targetId);
                                Navigator.pop(ctx);
                                Navigator.pushNamed(context, AppRoutes.privateChat);
                              },
                            ),
                            // Add Friend Request Button
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
                              child: const Text('Add', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
