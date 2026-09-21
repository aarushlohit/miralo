import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_button.dart';
import '../../widgets/common/miralo_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please fill out all fields.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _errorMessage = null);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signup(name, email, pass, username: username.isNotEmpty ? username : null);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.securitySetup);
    } else if (mounted) {
      setState(() => _errorMessage = auth.errorMessage ?? 'Sign up failed. Please try again.');
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
              Text('Create account',
                  style: AppTypography.display(color: textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Join MIRALO AI for private, intelligent workflows.',
                style: AppTypography.body(color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                        width: 1),
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

              // Form fields
              MiraloTextField(
                controller: _nameController,
                hint: 'Display name',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              MiraloTextField(
                controller: _usernameController,
                hint: 'Username (e.g. aarushlohit)',
                prefixIcon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              MiraloTextField(
                controller: _emailController,
                hint: 'Email',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              MiraloTextField(
                controller: _passwordController,
                hint: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                showToggleObscure: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              MiraloTextField(
                controller: _confirmController,
                hint: 'Confirm password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                showToggleObscure: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: _handleSignUp,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Primary CTA
              MiraloButton(
                label: 'Create account',
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _handleSignUp,
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

              // Social row
              Row(
                children: [
                  Expanded(
                    child: MiraloButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      variant: MiraloButtonVariant.secondary,
                      expand: false,
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.securitySetup),
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
                          context, AppRoutes.securitySetup),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Sign in link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.login),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: AppTypography.bodySmall(color: textSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign in',
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
