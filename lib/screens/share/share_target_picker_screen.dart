import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../widgets/common/longcat_app_bar.dart';
import '../../widgets/common/longcat_avatar.dart';

/// Dedicated WhatsApp-style Recipient Selection Screen for External File Sharing.
class ShareTargetPickerScreen extends StatefulWidget {
  final List<String> filePaths;
  final String? sharedText;

  const ShareTargetPickerScreen({
    super.key,
    required this.filePaths,
    this.sharedText,
  });

  @override
  State<ShareTargetPickerScreen> createState() => _ShareTargetPickerScreenState();
}

class _ShareTargetPickerScreenState extends State<ShareTargetPickerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedContactIds = {};
  bool _saveToLibrary = false;
  bool _isSending = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeSend() async {
    if (_selectedContactIds.isEmpty && !_saveToLibrary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact or Library Vault.')),
      );
      return;
    }

    setState(() => _isSending = true);

    final chat = Provider.of<PrivateChatProvider>(context, listen: false);
    final library = Provider.of<LibraryProvider>(context, listen: false);

    try {
      // 1. Send to chosen contact chats
      for (final contactId in _selectedContactIds) {
        chat.setActiveChat(contactId);
        if (widget.sharedText != null && widget.sharedText!.trim().isNotEmpty) {
          chat.sendTextMessage(widget.sharedText!.trim());
        }
        for (final path in widget.filePaths) {
          final isImg = path.toLowerCase().endsWith('.jpg') ||
              path.toLowerCase().endsWith('.png') ||
              path.toLowerCase().endsWith('.jpeg') ||
              path.toLowerCase().endsWith('.webp') ||
              path.toLowerCase().endsWith('.gif');
          final isVid = path.toLowerCase().endsWith('.mp4') ||
              path.toLowerCase().endsWith('.mov') ||
              path.toLowerCase().endsWith('.avi');

          final fileName = path.split('/').last;
          chat.sendMediaMessage(
            type: isImg ? 'image' : (isVid ? 'video' : 'file'),
            mediaUrl: path,
            fileName: fileName,
          );
        }
      }

      // 2. Save to Library Vault if toggled
      if (_saveToLibrary) {
        for (final path in widget.filePaths) {
          final fileName = path.split('/').last;
          final ext = fileName.split('.').last.toLowerCase();
          final type = (ext == 'jpg' || ext == 'png' || ext == 'jpeg')
              ? 'image'
              : (['mp4', 'mov', 'avi'].contains(ext) ? 'video' : 'document');

          library.uploadItem(
            name: fileName,
            type: type,
            size: 'Shared File',
            mediaUrl: path,
            folderId: type == 'image' ? 'folder_images' : 'folder_docs',
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedContactIds.isNotEmpty
                  ? 'File(s) shared with ${_selectedContactIds.length} recipient(s).'
                  : 'File(s) saved to Private Library Vault.',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending shared file: $e');
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = Provider.of<PrivateChatProvider>(context);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final cardBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final contacts = chat.contacts.where((c) {
      if (_searchCtrl.text.trim().isEmpty) return true;
      final q = _searchCtrl.text.toLowerCase().trim();
      return c.displayName.toLowerCase().contains(q) || c.username.toLowerCase().contains(q);
    }).toList();

    final totalSelected = _selectedContactIds.length + (_saveToLibrary ? 1 : 0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            LongcatAppBar(
              leading: LongcatCircularIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
              title: 'Send File(s) to Contact',
            ),

            // ── Shared Items Preview Bar at top ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.sm,
              ),
              color: surfaceBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SHARED ATTACHMENTS (${widget.filePaths.length})',
                        style: AppTypography.caption(color: AppColors.accent)
                            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      if (widget.sharedText != null && widget.sharedText!.isNotEmpty)
                        Text(
                          'Text attached',
                          style: AppTypography.caption(color: textMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.filePaths.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final path = widget.filePaths[idx];
                        final name = path.split('/').last;
                        final isImg = path.toLowerCase().endsWith('.jpg') ||
                            path.toLowerCase().endsWith('.png') ||
                            path.toLowerCase().endsWith('.jpeg');

                        return Container(
                          width: 64,
                          height: 64,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: 0.8),
                          ),
                          child: isImg
                              ? Image.file(File(path), fit: BoxFit.cover, errorBuilder: (ctx, err, stack) {
                                  return const Icon(Icons.insert_drive_file_outlined, color: AppColors.accent);
                                })
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.insert_drive_file_rounded,
                                        size: 24, color: AppColors.accent),
                                    const SizedBox(height: 2),
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption(color: textPrimary)
                                          .copyWith(fontSize: 8),
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

            Divider(height: 1, thickness: 0.6, color: border),

            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border, width: 0.6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: textMuted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: AppTypography.bodySmall(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search contact or username...',
                          hintStyle: AppTypography.bodySmall(color: textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Contact List / Library Target Options ───────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                children: [
                  // Option: Library Vault
                  InkWell(
                    onTap: () => setState(() => _saveToLibrary = !_saveToLibrary),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _saveToLibrary ? AppColors.accent.withValues(alpha: 0.12) : cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _saveToLibrary ? AppColors.accent : border,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.folder_special_rounded,
                                color: AppColors.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save to Private Library Vault',
                                  style: AppTypography.bodyMedium(color: textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Store files privately in encrypted vault',
                                  style: AppTypography.caption(color: textMuted),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: _saveToLibrary,
                            activeColor: AppColors.accent,
                            onChanged: (val) => setState(() => _saveToLibrary = val ?? false),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'PRIVATE CONTACTS',
                    style: AppTypography.caption(color: textMuted)
                        .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),

                  if (contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No contacts found.',
                          style: AppTypography.body(color: textMuted),
                        ),
                      ),
                    )
                  else
                    ...contacts.map((c) {
                      final isSelected = _selectedContactIds.contains(c.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accent.withValues(alpha: 0.6) : border,
                            width: 0.6,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedContactIds.remove(c.id);
                              } else {
                                _selectedContactIds.add(c.id);
                              }
                            });
                          },
                          leading: LongcatAvatar(
                            name: c.displayName,
                            size: 40,
                            isOnline: c.isOnline,
                          ),
                          title: Text(
                            c.displayName,
                            style: AppTypography.bodyMedium(color: textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '@${c.username}',
                            style: AppTypography.caption(color: textMuted),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: AppColors.accent,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedContactIds.add(c.id);
                                } else {
                                  _selectedContactIds.remove(c.id);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        decoration: BoxDecoration(
          color: surfaceBg,
          border: Border(top: BorderSide(color: border, width: 0.6)),
        ),
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: (_isSending || totalSelected == 0) ? null : _executeSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        totalSelected == 0
                            ? 'Select Recipient'
                            : 'Send to $totalSelected target${totalSelected > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
