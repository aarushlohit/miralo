import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_button.dart';
import '../../widgets/common/miralo_text_field.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _privateSecretController = TextEditingController();
  final _libraryPinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _privateSecretController.dispose();
    _libraryPinController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    // Dismiss virtual keyboard cleanly
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final secret = _privateSecretController.text.trim();
    final pin = _libraryPinController.text.trim();

    if (secret.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Please configure both credentials.');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final aiChat = Provider.of<AiChatProvider>(context, listen: false);
    final chat = Provider.of<PrivateChatProvider>(context, listen: false);
    final library = Provider.of<LibraryProvider>(context, listen: false);
    final uid = auth.currentUser?.id;
    final uname = auth.currentUser?.username;

    await vault.setPrivateChatSecret(secret, userId: uid);
    await vault.setLibraryPin(pin, userId: uid);

    final uemail = auth.currentUser?.email;

    if (uid != null && uid.isNotEmpty) {
      auth.addLogoutListener(chat.clearSession);
      auth.addLogoutListener(vault.clearSession);
      auth.addLogoutListener(aiChat.clearSession);
      auth.addLogoutListener(library.clearSession);

      chat.clearSession();
      vault.clearSession();
      aiChat.clearSession();
      library.clearSession();

      await vault.attachUser(uid);
      await aiChat.initUserSession(uid);
      chat.initUserSession(uid, username: uname, email: uemail);
      await library.initUserSession(uid);
    }

    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Future<void> _handleBackOrExit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          'Cancel Security Setup?',
          style: AppTypography.heading2(color: textPrimary),
        ),
        content: Text(
          'Miralo requires configuring your Private Chat Secret and Library Vault PIN to protect your private workspace. If you leave now, you will be signed out.',
          style: AppTypography.body(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Stay & Complete', style: AppTypography.body(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign Out & Exit', style: AppTypography.body(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final vault = Provider.of<VaultProvider>(context, listen: false);
      final chat = Provider.of<PrivateChatProvider>(context, listen: false);
      final aiChat = Provider.of<AiChatProvider>(context, listen: false);
      final library = Provider.of<LibraryProvider>(context, listen: false);

      chat.clearSession();
      vault.clearSession();
      aiChat.clearSession();
      library.clearSession();
      auth.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackOrExit();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 16, color: textPrimary),
            onPressed: _handleBackOrExit,
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.sm * 2,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              Text('Protect your space',
                  style: AppTypography.display(color: textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Two locks. Complete control. Unlocking one never unlocks the other.',
                style: AppTypography.body(color: textSecondary),
              ),

              const SizedBox(height: AppSpacing.xl),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(_error!,
                              style: AppTypography.bodySmall(
                                  color: AppColors.danger))),
                    ],
                  ),
                ),
              ],

              // Card 1: Private Chat Secret
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.vpn_key_rounded,
                              size: 18, color: AppColors.accent),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Private Chat Secret',
                                  style: AppTypography.bodyMedium(
                                          color: textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                'Typed into normal AI composer to reveal contacts',
                                style: AppTypography.caption(
                                    color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MiraloTextField(
                      controller: _privateSecretController,
                      hint: 'Secret (word, PIN, or phrase)',
                      obscureText: true,
                      showToggleObscure: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Card 2: Library Vault PIN
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accentHover.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.shield_outlined,
                              size: 18, color: AppColors.accentHover),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Library Vault Passcode',
                                  style: AppTypography.bodyMedium(
                                          color: textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                'Independent passcode (PIN, text, or phrase) for encrypted documents & media',
                                style: AppTypography.caption(
                                    color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MiraloTextField(
                      controller: _libraryPinController,
                      hint: 'Passcode (numbers, text, or phrase)',
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      showToggleObscure: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Center(
                child: Text(
                  'Keep them different for maximum privacy.',
                  style: AppTypography.caption(color: textSecondary),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              MiraloButton(
                label: 'Continue',
                onPressed: _handleContinue,
              ),
              const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
