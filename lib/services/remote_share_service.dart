import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../core/theme/miralo_tokens.dart';
import '../providers/vault_provider.dart';
import '../screens/share/share_target_picker_screen.dart';

/// Secure Remote Share Gateway for Android Intents & Multi-Platform Files
class RemoteShareService {
  RemoteShareService._();

  static StreamSubscription? _intentMediaStreamSubscription;
  static bool _initialized = false;

  static void initSharingIntentListener(BuildContext context) {
    if (_initialized) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _initialized = true;

    // For sharing items while app is running
    _intentMediaStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && context.mounted) {
        final paths = value.map((f) => f.path).toList();
        promptRemoteShareDialog(context, filePaths: paths);
      }
    }, onError: (err) {
      debugPrint("getIntentMediaStream error: $err");
    });

    // For sharing items when app is launched from intent
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && context.mounted) {
        final paths = value.map((f) => f.path).toList();
        promptRemoteShareDialog(context, filePaths: paths);
        ReceiveSharingIntent.instance.reset();
      }
    });  }

  static void dispose() {
    _intentMediaStreamSubscription?.cancel();
    _initialized = false;
  }

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
  bool _isLoading = false;
  String? _errorMessage;

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

    // Comprehensive Server-Side & Local Vault Passcode Validation
    bool ok = await vault.unlockPrivateAsync(secret);
    if (!ok) {
      ok = await vault.unlockLibraryAsync(secret);
    }
    if (!ok) {
      ok = vault.unlockPrivate(secret);
    }
    if (!ok) {
      ok = vault.unlockLibrary(secret);
    }
    if (!ok) {
      ok = vault.verifyPasscode(secret) || vault.verifyLibraryPin(secret);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (ok) {
        Navigator.pop(context); // Close Secret Key dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShareTargetPickerScreen(
              filePaths: widget.filePaths,
              sharedText: widget.sharedText,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid Secret Key or Passcode.';
        });
      }
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
          Text('External Share Security', style: MiraloTypography.titleMedium(color: textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Secret Key or Passcode to authorize sharing external files into Miralo.',
              style: MiraloTypography.bodySmall(color: textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passcodeController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Secret Passcode / Key',
                errorText: _errorMessage,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: MiraloColors.accent, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _verifySecret(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifySecret,
          style: ElevatedButton.styleFrom(
            backgroundColor: MiraloColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verify & Select Recipient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
