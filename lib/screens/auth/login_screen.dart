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
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_button.dart';
import '../../widgets/common/miralo_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  int _failedAttempts = 0;
  String? _lastAttemptedTarget;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final identifier = _emailController.text.trim();
    final pass = _passwordController.text;

    if (identifier.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email or username and password.');
      return;
    }
    setState(() => _errorMessage = null);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(identifier, pass);
    if (success && mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');

      _failedAttempts = 0;
      _lastAttemptedTarget = null;
      if (auth.currentUser != null) {
        final uid = auth.currentUser!.id;
        final uname = auth.currentUser!.username;
        final uemail = auth.currentUser!.email;
        final vault = Provider.of<VaultProvider>(context, listen: false);
        final aiChat = Provider.of<AiChatProvider>(context, listen: false);
        final chat = Provider.of<PrivateChatProvider>(context, listen: false);
        final library = Provider.of<LibraryProvider>(context, listen: false);

        // Register automatic logout cleanup
        auth.addLogoutListener(chat.clearSession);
        auth.addLogoutListener(vault.clearSession);
        auth.addLogoutListener(aiChat.clearSession);
        auth.addLogoutListener(library.clearSession);

        // Pre-wipe any residual memory state
        chat.clearSession();
        vault.clearSession();
        aiChat.clearSession();
        library.clearSession();

        await vault.attachUser(uid);
        await aiChat.initUserSession(uid);
        chat.initUserSession(uid, username: uname, email: uemail);
        await library.initUserSession(uid);
      }
      if (mounted) {
        final vault = Provider.of<VaultProvider>(context, listen: false);
        if (!vault.hasPrivateSecret || !vault.hasLibraryPin) {
          Navigator.pushReplacementNamed(context, AppRoutes.securitySetup);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } else if (mounted) {
      final cleanTarget = identifier.trim().toLowerCase();
      if (_lastAttemptedTarget != cleanTarget) {
        _failedAttempts = 0;
        _lastAttemptedTarget = cleanTarget;
      }

      final targetUserId = auth.lastFailedTargetUserId;
      final targetUsername = auth.lastFailedTargetUsername;

      // If user does NOT exist in database (wrong username), DROP IT to eliminate false positives!
      if (targetUserId == null || targetUserId.isEmpty) {
        _failedAttempts = 0;
        setState(() {
          _errorMessage = auth.errorMessage ?? 'Incorrect email, username or password. Please try again.';
        });
        return;
      }

      // Valid existing user entered with wrong password:
      _failedAttempts++;
      final vault = Provider.of<VaultProvider>(context, listen: false);

      if (_failedAttempts >= 2) {
        vault.recordLoginIntruderAttempt(
          _failedAttempts,
          targetUserId: targetUserId,
          targetUsername: targetUsername,
        );
        setState(() {
          _errorMessage = auth.errorMessage ??
              'Incorrect credentials. Security photo captured after $_failedAttempts failed attempts.';
        });
      } else {
        setState(() {
          _errorMessage = auth.errorMessage ?? 'Incorrect email, username or password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Text('Welcome back',
                                style: AppTypography.display(color: textPrimary)),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Sign in to MIRALO AI',
                                style: AppTypography.body(color: textSecondary)),
                            const SizedBox(height: AppSpacing.xl),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(_errorMessage!,
                              style: AppTypography.bodySmall(
                                  color: AppColors.danger))),
                    ],
                  ),
                ),
              ],

              // Email or Username
              MiraloTextField(
                controller: _emailController,
                hint: 'Email or username',
                prefixIcon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              // Password
              MiraloTextField(
                controller: _passwordController,
                hint: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                showToggleObscure: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: _handleLogin,
              ),
              const SizedBox(height: AppSpacing.lg),

              MiraloButton(
                label: 'Sign in',
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _handleLogin,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Text('or continue with',
                        style: AppTypography.caption(color: textSecondary)),
                  ),
                  Expanded(child: Divider(color: border)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Social
              Row(
                children: [
                  Expanded(
                    child: MiraloButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      variant: MiraloButtonVariant.secondary,
                      expand: false,
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.home),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MiraloButton(
                      label: 'Apple',
                      icon: Icons.apple,
                      variant: MiraloButtonVariant.secondary,
                      expand: false,
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.home),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.signup),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: AppTypography.bodySmall(color: textSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: AppTypography.bodySmall(
                              color: AppColors.accent)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  },
),
            ),
          ],
        ),
      ),
    );
  }
}
