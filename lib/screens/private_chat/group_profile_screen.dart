import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/private_contact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../widgets/common/miralo_avatar.dart';

class GroupProfileScreen extends StatefulWidget {
  final String groupId;

  const GroupProfileScreen({super.key, required this.groupId});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupLogo(BuildContext context, PrivateChatProvider chat) async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
                title: const Text('Take Photo'),
                onTap: () async {
                  final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 600, imageQuality: 80);
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await chat.updateGroupDetails(groupId: widget.groupId, avatarUrl: base64String);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group icon updated'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  void _showEditNameDialog(BuildContext context, PrivateChatProvider chat, PrivateContactModel group) {
    final controller = TextEditingController(text: group.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new group name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await chat.updateGroupDetails(groupId: group.id, groupName: newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditBioDialog(BuildContext context, PrivateChatProvider chat, PrivateContactModel group) {
    final controller = TextEditingController(text: group.groupBio ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group Description'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Add a group description or rules'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await chat.updateGroupDetails(groupId: group.id, groupBio: controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTagRoleDialog(BuildContext context, PrivateChatProvider chat, String memberId, String currentRole) {
    final controller = TextEditingController(text: currentRole);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Role / Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a custom role tag (e.g. Moderator, VIP, Designer):', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Role tag (leave blank to clear)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await chat.assignMemberRole(groupId: widget.groupId, memberId: memberId, role: controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersSheet(BuildContext context, PrivateChatProvider chat, PrivateContactModel group) {
    final existingMemberIds = group.memberIds.toSet();
    final nonMembers = chat.contacts.where((c) => !existingMemberIds.contains(c.id)).toList();

    if (nonMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your contacts are already members of this group.')),
      );
      return;
    }

    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Members', style: AppTypography.h3(color: isDark ? Colors.white : Colors.black)),
                    TextButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              await chat.addMembersToGroup(groupId: group.id, memberIds: selected.toList());
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: Text('Add (${selected.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.builder(
                    itemCount: nonMembers.length,
                    itemBuilder: (ctx, i) {
                      final c = nonMembers[i];
                      final isSelected = selected.contains(c.id);
                      return ListTile(
                        leading: MiraloAvatar(name: c.displayName, imageUrl: c.avatarUrl, size: 36),
                        title: Text(c.displayName),
                        subtitle: Text(c.username.isNotEmpty ? '@${c.username}' : (c.phoneNumber ?? '')),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                selected.add(c.id);
                              } else {
                                selected.remove(c.id);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              selected.remove(c.id);
                            } else {
                              selected.add(c.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMemberOptions(
    BuildContext context,
    PrivateChatProvider chat,
    PrivateContactModel group,
    String memberId,
    String memberName,
    String? memberUsername,
    String? memberPhone,
    String currentUserId,
  ) {
    final isMe = memberId == currentUserId;
    final isOwner = group.isOwner(currentUserId);
    final isTargetOwner = group.isOwner(memberId);
    final isTargetAdmin = group.isAdmin(memberId);
    final canManageTarget = isOwner || (group.isAdmin(currentUserId) && !isTargetOwner && !isTargetAdmin);
    final isFriend = chat.contacts.any((c) => c.id == memberId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (memberUsername != null) Text('@$memberUsername', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(),
                if (!isMe) ...[
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent),
                    title: const Text('Message privately'),
                  onTap: () {
                    Navigator.pop(ctx);
                    chat.setActiveChat(memberId);
                    Navigator.pushReplacementNamed(context, AppRoutes.privateChat);
                  },
                ),
                if (!isFriend)
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.green),
                    title: const Text('Send Friend Request'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final targetContact = chat.getContact(memberId) ??
                          PrivateContactModel(
                            id: memberId,
                            displayName: memberName,
                            username: memberUsername ?? memberName,
                            phoneNumber: memberPhone,
                          );
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      await chat.sendFriendRequest(
                        senderId: auth.currentUser?.id ?? 'me',
                        senderName: auth.currentUser?.displayName ?? 'User',
                        senderUsername: auth.currentUser?.username ?? 'user',
                        targetUsernameOrEmail: targetContact.username,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Friend request sent to $memberName')),
                        );
                      }
                    },
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.sell_outlined, color: Colors.amber),
                title: Text(isMe ? 'Edit my role tag' : 'Assign role tag'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTagRoleDialog(context, chat, memberId, group.getRoleFor(memberId));
                },
              ),
              if (isOwner && !isMe) ...[
                ListTile(
                  leading: Icon(isTargetAdmin ? Icons.remove_moderator_outlined : Icons.add_moderator_outlined, color: Colors.blue),
                  title: Text(isTargetAdmin ? 'Dismiss as Admin' : 'Make Group Admin'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await chat.setGroupAdmin(groupId: group.id, memberId: memberId, isAdmin: !isTargetAdmin);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded, color: Colors.orange),
                  title: const Text('Transfer Ownership'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Transfer Ownership?'),
                        content: Text('Are you sure you want to transfer group ownership to $memberName? You will remain an admin.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Transfer', style: TextStyle(color: Colors.orange))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await chat.transferGroupOwnership(groupId: group.id, newOwnerId: memberId);
                    }
                  },
                ),
              ],
              if (canManageTarget && !isMe)
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined, color: AppColors.danger),
                  title: Text('Remove from Group', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await chat.removeMemberFromGroup(groupId: group.id, memberId: memberId);
                  },
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final chat = Provider.of<PrivateChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id ?? '';

    final group = chat.getContact(widget.groupId) ?? chat.activeContact;

    if (group == null || !group.isGroup) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Info')),
        body: const Center(child: Text('Group not found')),
      );
    }

    final isOwner = group.isOwner(currentUserId);
    final isAdmin = group.isAdmin(currentUserId);
    final canEdit = group.canEditSettings(currentUserId);

    // Build member items
    final members = group.memberIds.map((mId) {
      if (mId == currentUserId) {
        final currentUsername = (auth.currentUser?.username != null && auth.currentUser!.username.isNotEmpty)
            ? auth.currentUser!.username
            : ((chat.currentUsername != null && chat.currentUsername!.isNotEmpty)
                ? chat.currentUsername
                : (auth.currentUser?.displayName ?? 'aarushlohit'));
        return {
          'id': mId,
          'name': '${auth.currentUser?.displayName ?? 'You'} (You)',
          'username': currentUsername,
          'phone': auth.currentUser?.email,
          'avatarUrl': auth.currentUser?.avatarUrl,
          'note': chat.currentUserNote,
        };
      }
      final c = chat.getContact(mId);
      final memberUsername = (c?.username != null && c!.username.isNotEmpty)
          ? c.username
          : (c?.displayName != null && c!.displayName.isNotEmpty ? c.displayName : null);
      return {
        'id': mId,
        'name': c?.displayName ?? 'Member $mId',
        'username': memberUsername,
        'phone': c?.phoneNumber,
        'avatarUrl': c?.avatarUrl,
        'note': c?.note,
      };
    }).where((m) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (m['name'] ?? '').toLowerCase();
      final username = (m['username'] ?? '').toLowerCase();
      final phone = (m['phone'] ?? '').toLowerCase();
      return name.contains(query) || username.contains(query) || phone.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Group Info', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          // ── Group Header Card ──────────────────────────────────────
          Center(
            child: Stack(
              children: [
                MiraloAvatar(
                  name: group.displayName,
                  imageUrl: group.avatarUrl,
                  size: 90,
                  backgroundColor: AppColors.accent,
                ),
                if (canEdit)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickGroupLogo(context, chat),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: surface, width: 2),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Group Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  group.displayName,
                  style: AppTypography.h2(color: textPrimary).copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: textMuted,
                  onPressed: () => _showEditNameDialog(context, chat, group),
                ),
            ],
          ),

          Text(
            'Group · ${group.memberIds.length} members',
            style: AppTypography.caption(color: textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Group Bio / Description ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Description', style: AppTypography.labelMedium(color: textMuted)),
                    if (canEdit)
                      InkWell(
                        onTap: () => _showEditBioDialog(context, chat, group),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: AppColors.accent),
                              SizedBox(width: 4),
                              Text('Edit', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (group.groupBio != null && group.groupBio!.trim().isNotEmpty)
                      ? group.groupBio!
                      : 'No description provided yet.',
                  style: AppTypography.body(color: textPrimary).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Permissions Card (Visible to all, editable by Owner/Admin) ────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('Group Settings Permissions', style: AppTypography.labelMedium(color: textPrimary).copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Who can edit group info and settings:', style: AppTypography.caption(color: textMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: group.settingsPermission,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'everyone',
                      child: Text('Everyone (All Members)'),
                    ),
                    DropdownMenuItem(
                      value: 'admins',
                      child: Text('Admins Only'),
                    ),
                    DropdownMenuItem(
                      value: 'roles',
                      child: Text('Role-based (Admins & Tagged Roles)'),
                    ),
                  ],
                  onChanged: (isAdmin || isOwner)
                      ? (val) {
                          if (val != null) {
                            chat.updateGroupSettingsPermission(groupId: group.id, permission: val);
                          }
                        }
                      : null,
                ),
                if (!isAdmin && !isOwner) ...[
                  const SizedBox(height: 6),
                  Text('Only group owner or admins can modify this setting.',
                      style: AppTypography.caption(color: textMuted).copyWith(fontStyle: FontStyle.italic, fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Members Section ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${group.memberIds.length} Members', style: AppTypography.body(color: textPrimary).copyWith(fontWeight: FontWeight.bold)),
                    if (isAdmin || isOwner || group.settingsPermission == 'everyone')
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () => _showAddMembersSheet(context, chat, group),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search members by username or phone...',
                    hintStyle: AppTypography.caption(color: textMuted),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Member List
                ...members.map((m) {
                  final mId = m['id']!;
                  final isTargetOwner = group.isOwner(mId);
                  final isTargetAdmin = group.isAdmin(mId);
                  final roleTag = group.getRoleFor(mId);
                  final note = m['note'];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: MiraloAvatar(
                      name: m['name'] ?? '',
                      imageUrl: m['avatarUrl'],
                      size: 38,
                      note: note,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            m['name'] ?? '',
                            style: AppTypography.bodySmall(color: textPrimary).copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isTargetOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Owner', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ] else if (isTargetAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Admin', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if (roleTag.isNotEmpty &&
                            (!isTargetOwner || roleTag.toLowerCase() != 'owner') &&
                            (!isTargetAdmin || roleTag.toLowerCase() != 'admin')) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(roleTag, style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      m['username'] != null && m['username']!.isNotEmpty
                          ? '@${m['username']}'
                          : (m['phone'] ?? 'Encrypted User'),
                      style: AppTypography.caption(color: textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onPressed: () => _showMemberOptions(
                        context,
                        chat,
                        group,
                        mId,
                        m['name'] ?? '',
                        m['username'],
                        m['phone'],
                        currentUserId,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Leave / Delete Group ───────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.6),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded, color: AppColors.danger),
                  title: const Text('Leave Group', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Leave Group?'),
                        content: const Text('You will no longer receive messages from this group.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Leave', style: TextStyle(color: AppColors.danger))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await chat.leaveGroup(groupId: group.id);
                      if (context.mounted) {
                        Navigator.pop(context); // Close group profile
                        Navigator.pop(context); // Close chat
                      }
                    }
                  },
                ),
                if (isOwner) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                    title: const Text('Delete Group', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Group?'),
                          content: const Text('This will delete the group for all participants and clear its messages.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await chat.deleteGroup(groupId: group.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
