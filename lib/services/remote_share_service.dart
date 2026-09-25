import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/miralo_tokens.dart';
import '../providers/private_chat_provider.dart';
import '../providers/vault_provider.dart';

/// Secure Remote Share Gateway for Android Intents & Multi-Platform Files
class RemoteShareService {
  RemoteShareService._();

  static void promptRemoteShareDialog(
    BuildContext context, {
    required List<String> filePaths,
    String? sharedText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RemoteShareModal(
        filePaths: filePaths,
        sharedText: sharedText,
      ),
    );
  }
}

class _RemoteShareModal extends StatefulWidget {
  final List<String> filePaths;
  final String? sharedText;

  const _RemoteShareModal({
    required this.filePaths,
    this.sharedText,
  });

  @override
  State<_RemoteShareModal> createState() => _RemoteShareModalState();
}

class _RemoteShareModalState extends State<_RemoteShareModal> {
  final TextEditingController _passcodeController = TextEditingController();
  bool _isVerified = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _shareTarget = 'chats'; // 'chats' or 'library'
  String? _selectedContactId;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _verifySecret() async {
    final secret = _passcodeController.text.trim();
    if (secret.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vault = Provider.of<VaultProvider>(context, listen: false);

    // Strict Server-Side Validation against Firebase RTDB first
    bool ok = await vault.unlockPrivateAsync(secret);
    if (!ok) {
      ok = await vault.unlockLibraryAsync(secret);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (ok) {
          _isVerified = true;
        } else {
          _errorMessage = 'Invalid Secret Key. Server validation failed.';
        }
      });
    }
  }

  Future<void> _executeRemoteShare() async {
    final chat = Provider.of<PrivateChatProvider>(context, listen: false);
    if (_shareTarget == 'chats') {
      if (_selectedContactId == null) {
        setState(() => _errorMessage = 'Please select a contact to share with.');
        return;
      }
      chat.setActiveChat(_selectedContactId!);
      if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
        chat.sendTextMessage(widget.sharedText!);
      }
      for (final path in widget.filePaths) {
        final isImg = path.toLowerCase().endsWith('.jpg') ||
            path.toLowerCase().endsWith('.png') ||
            path.toLowerCase().endsWith('.jpeg');
        chat.sendMediaMessage(
          type: isImg ? 'image' : 'file',
          mediaUrl: path,
          fileName: path.split('/').last,
        );
      }
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item shared securely via Miralo Remote Gateway.'),
          backgroundColor: MiraloColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary;
    final textSecondary = isDark ? MiraloColors.darkTextSecondary : MiraloColors.lightTextSecondary;

    return AlertDialog(
      backgroundColor: isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.security_rounded, color: MiraloColors.accent, size: 22),
          const SizedBox(width: 8),
          Text('Miralo Remote Share', style: MiraloTypography.titleMedium(color: textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isVerified) ...[
              Text(
                'Enter your Secret Key or Passcode to authorize remote sharing without opening the app.',
                style: MiraloTypography.bodySmall(color: textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Secret Passcode',
                  errorText: _errorMessage,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _verifySecret(),
              ),
            ] else ...[
              Text('Select Share Destination', style: MiraloTypography.titleMedium(color: textPrimary)),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _shareTarget,
                onChanged: (val) {
                  if (val != null) setState(() => _shareTarget = val);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Share to Private Contact Chat'),
                      value: 'chats',
                    ),
                    RadioListTile<String>(
                      title: const Text('Save to Private Library Vault'),
                      value: 'library',
                    ),
                  ],
                ),
              ),
              if (_shareTarget == 'chats') ...[
                const SizedBox(height: 8),
                Consumer<PrivateChatProvider>(
                  builder: (context, chat, _) {
                    final contacts = chat.contacts;
                    if (contacts.isEmpty) {
                      return Text('No contacts available.', style: MiraloTypography.caption(color: textSecondary));
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedContactId,
                      hint: const Text('Choose Contact'),
                      items: contacts.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text('@${c.username} (${c.displayName})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedContactId = val),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_isVerified)
          ElevatedButton(
            onPressed: _isLoading ? null : _verifySecret,
            style: ElevatedButton.styleFrom(backgroundColor: MiraloColors.accent),
            child: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Unlock', style: TextStyle(color: Colors.white)),
          )
        else
          ElevatedButton(
            onPressed: _executeRemoteShare,
            style: ElevatedButton.styleFrom(backgroundColor: MiraloColors.accent),
            child: const Text('Share Now', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}
