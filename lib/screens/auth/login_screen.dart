import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
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
  final _emailController =
      TextEditingController(text: 'alex.morgan@miralo.ai');
  final _passwordController = TextEditingController();
  String? _errorMessage;

  int _failedAttempts = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }
    setState(() => _errorMessage = null);

    // Demonstration check for invalid login password
    if (pass != 'password' && pass != '123456' && pass != '1234') {
      _failedAttempts++;
      final vault = Provider.of<VaultProvider>(context, listen: false);

      if (_failedAttempts >= 2) {
        vault.recordLoginIntruderAttempt(_failedAttempts);
        setState(() {
          _errorMessage = 'Incorrect credentials. Security photo captured after $_failedAttempts failed attempts.';
        });
      } else {
        setState(() {
          _errorMessage = 'Incorrect password. Try again.';
        });
      }
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(email, pass);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted) {
      setState(() => _errorMessage = 'Incorrect credentials. Please try again.');
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                    AppSpacing.sm, AppSpacing.screenH, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Email
              MiraloTextField(
                controller: _emailController,
                hint: 'Email',
                prefixIcon: Icons.mail_outline,
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
            ],
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}
