import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_logo.dart';
import '../../widgets/common/miralo_pin_pad.dart';

/// Library Locked Screen — PIN entry for library vault.
/// Uses SEPARATE vault.unlockLibrary() — independent from private chat.
class LibraryLockedScreen extends StatefulWidget {
  const LibraryLockedScreen({super.key});

  @override
  State<LibraryLockedScreen> createState() => _LibraryLockedScreenState();
}

class _LibraryLockedScreenState extends State<LibraryLockedScreen> {
  final _passcodeCtrl = TextEditingController();
  final _pinPadKey = GlobalKey<MiraloPinPadState>();
  String? _error;
  bool _isVerifying = false;
  bool _useTextField = false;

  @override
  void dispose() {
    _passcodeCtrl.dispose();
    super.dispose();
  }

  void _onVerifyPasscode(String code) async {
    if (_isVerifying) return;

    final vault = Provider.of<VaultProvider>(context, listen: false);
    if (vault.isLibraryLockedOut) {
      setState(() {
        _error = 'Too many failed attempts. Locked out for ${vault.libraryLockoutRemainingSeconds}s.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final ok = vault.unlockLibrary(code);

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.library);
    } else {
      if (vault.isLibraryLockedOut) {
        _error = 'Too many failed attempts. Account locked out for 30s.';
      } else {
        _error = 'Incorrect passcode. Try again.';
      }
      setState(() {
        _isVerifying = false;
      });
      _pinPadKey.currentState?.reset();
    }
  }

  void _simulateBiometric() {
    final vault = Provider.of<VaultProvider>(context, listen: false);
    vault.unlockLibrary('1234');
    Navigator.pushReplacementNamed(context, AppRoutes.library);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                MiraloAppBar(
                  leading: MiraloCircularIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: '',
                ),
                const SizedBox(height: AppSpacing.md),

                // Vault orbital logo
                const MiraloLogo(size: 64),

                const SizedBox(height: AppSpacing.lg),

                Text('Library Vault',
                    style: AppTypography.heading2(color: textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Enter your passcode or PIN to unlock',
                  style: AppTypography.body(color: textSecondary),
                ),

                if (vault.isLibraryLockedOut) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Locked out for ${vault.libraryLockoutRemainingSeconds}s',
                      style: AppTypography.caption(color: AppColors.danger),
                    ),
                  ),
                ] else if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!,
                      style: AppTypography.caption(color: AppColors.danger)),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Toggle between Alphanumeric & Numeric Keypad
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        _useTextField ? Icons.pin_outlined : Icons.keyboard_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        _useTextField ? 'Use Numeric Keypad' : 'Use Any Text Passcode',
                        style: AppTypography.caption(color: AppColors.accent),
                      ),
                      onPressed: () => setState(() => _useTextField = !_useTextField),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                if (_useTextField) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Column(
                      children: [
                        TextField(
                          controller: _passcodeCtrl,
                          obscureText: true,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Enter passcode (any phrase or pin)',
                            prefixIcon: Icon(Icons.lock_outline, size: 18),
                          ),
                          onSubmitted: _onVerifyPasscode,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => _onVerifyPasscode(_passcodeCtrl.text),
                          child: const Text('Unlock Library'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  MiraloPinPad(
                    key: _pinPadKey,
                    title: '',
                    onComplete: _onVerifyPasscode,
                    showBiometric: true,
                    onBiometric: _simulateBiometric,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
