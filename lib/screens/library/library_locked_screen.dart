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
  final String? targetRoute;
  const LibraryLockedScreen({super.key, this.targetRoute});

  @override
  State<LibraryLockedScreen> createState() => _LibraryLockedScreenState();
}

class _LibraryLockedScreenState extends State<LibraryLockedScreen> {
  final _passcodeCtrl = TextEditingController();
  final _pinPadKey = GlobalKey<MiraloPinPadState>();
  String? _error;
  bool _isVerifying = false;
  bool _useTextField = false;

  bool _obscureText = true;

  @override
  void dispose() {
    _passcodeCtrl.dispose();
    super.dispose();
  }

  String _getTargetRoute(BuildContext context) {
    if (widget.targetRoute != null && widget.targetRoute!.isNotEmpty) {
      return widget.targetRoute!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is String && routeArgs.isNotEmpty) {
      return routeArgs;
    }
    return AppRoutes.library;
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

    final ok = await vault.unlockLibraryAsync(code);

    if (!mounted) return;

    if (ok) {
      final target = _getTargetRoute(context);
      Navigator.pushReplacementNamed(context, target);
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
    final target = _getTargetRoute(context);
    Navigator.pushReplacementNamed(context, target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final target = _getTargetRoute(context);
    final isImages = target == AppRoutes.images;
    final vaultTitle = isImages ? 'Images Vault' : 'Library Vault';
    final vaultSubtitle = isImages
        ? 'Enter library passcode or PIN to unlock images'
        : 'Enter your passcode or PIN to unlock';

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

                Text(vaultTitle,
                    style: AppTypography.heading2(color: textPrimary)),
                const SizedBox(height: 4),
                Text(
                  vaultSubtitle,
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

                // Segmented Toggle between Numeric PIN and Alphanumeric Passcode
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useTextField = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_useTextField
                                  ? (isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: !_useTextField
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pin_outlined,
                                  size: 16,
                                  color: !_useTextField ? AppColors.accent : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Numeric PIN',
                                  style: AppTypography.caption(
                                    color: !_useTextField ? textPrimary : textSecondary,
                                  ).copyWith(fontWeight: !_useTextField ? FontWeight.w600 : FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useTextField = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _useTextField
                                  ? (isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _useTextField
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.password_outlined,
                                  size: 16,
                                  color: _useTextField ? AppColors.accent : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Text Passcode',
                                  style: AppTypography.caption(
                                    color: _useTextField ? textPrimary : textSecondary,
                                  ).copyWith(fontWeight: _useTextField ? FontWeight.w600 : FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                if (_useTextField) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Column(
                      children: [
                        TextField(
                          controller: _passcodeCtrl,
                          obscureText: _obscureText,
                          autofocus: true,
                          keyboardType: TextInputType.text,
                          style: AppTypography.body(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter passcode (letters, words, phrase)',
                            prefixIcon: const Icon(Icons.lock_outline, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                          onSubmitted: _onVerifyPasscode,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isVerifying ? null : () => _onVerifyPasscode(_passcodeCtrl.text),
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(isImages ? 'Unlock Images' : 'Unlock Library Vault', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
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
