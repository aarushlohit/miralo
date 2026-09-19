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
  final _pinPadKey = GlobalKey<MiraloPinPadState>();
  String? _error;
  bool _isVerifying = false;

  void _onPinComplete(String pin) async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final vault = Provider.of<VaultProvider>(context, listen: false);
    final ok = vault.unlockLibrary(pin);

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.library);
    } else {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
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
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
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
              'Enter your vault PIN to unlock',
              style: AppTypography.body(color: textSecondary),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: AppTypography.caption(color: AppColors.danger)),
            ],

            const SizedBox(height: AppSpacing.xl),

            // PIN pad using shared component
            Expanded(
              child: MiraloPinPad(
                key: _pinPadKey,
                title: '',
                onComplete: _onPinComplete,
                showBiometric: true,
                onBiometric: _simulateBiometric,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
