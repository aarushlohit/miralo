import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../widgets/common/miralo_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();

    _timer = Timer(const Duration(milliseconds: 2400), () {
      _proceed();
    });
  }

  Future<void> _proceed() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isInitialized) {
      await auth.loadFromStorage();
      if (!mounted) return;
    }
    if (auth.isAuthenticated && auth.currentUser != null) {
      final vault = Provider.of<VaultProvider>(context, listen: false);
      final chat = Provider.of<PrivateChatProvider>(context, listen: false);
      await vault.attachUser(auth.currentUser!.id);
      chat.initUserSession(auth.currentUser!.id);
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      auth.isAuthenticated ? AppRoutes.home : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: _proceed,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bespoke Miralo orbital planet ring mark
                  const MiraloLogo(size: 76),
                  const SizedBox(height: 24),
                  Text('MIRALO AI', style: AppTypography.wordmark(color: textColor)),
                  const SizedBox(height: 6),
                  Text('Your AI. Your Space.',
                      style: AppTypography.label(color: mutedColor)),
                  const SizedBox(height: 52),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.accent.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
