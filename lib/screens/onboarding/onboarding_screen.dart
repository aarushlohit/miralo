import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/common/miralo_button.dart';
import '../../widgets/common/miralo_logo.dart';
import '../../widgets/common/miralo_text_field.dart';

/// Complete 7-Step Onboarding Flow per Specification Section 24:
/// 1. Intro: MIRALO logo, MIRALO AI, Your AI. Your Space.
/// 2. Value Prop: Your conversations. Your space.
/// 3. Create Account: Name, Email, Password, Confirm password.
/// 4. Welcome Architecture: AI conversations, Private conversations, Secure Library.
/// 5. Create Private Chat Passcode ("This passcode unlocks your private conversations.")
/// 6. Create Library Vault Passcode ("This passcode protects your private files and media.")
/// 7. Setup Complete: "Open MIRALO AI".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;

  // Step 3 (Account) Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  String? _accountError;

  // Step 5 & 6 (Passcodes) Controllers
  final _privatePasscodeController = TextEditingController();
  final _libraryPasscodeController = TextEditingController();
  String? _passcodeError;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _privatePasscodeController.dispose();
    _libraryPasscodeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep == 2) {
      // Validate Account
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final pass = _passController.text;
      final confirm = _confirmPassController.text;

      if (name.isEmpty || username.isEmpty || email.isEmpty || pass.isEmpty) {
        setState(() => _accountError = 'Please fill in all fields.');
        return;
      }
      if (pass != confirm) {
        setState(() => _accountError = 'Passwords do not match.');
        return;
      }
      setState(() => _accountError = null);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.signup(name, email, pass, username: username);
      _goToStep(3);
      return;
    }

    if (_currentStep == 4) {
      // Validate Private Passcode
      final pass = _privatePasscodeController.text.trim();
      if (pass.isEmpty) {
        setState(() => _passcodeError = 'Please enter a private chat passcode.');
        return;
      }
      setState(() => _passcodeError = null);
      final vault = Provider.of<VaultProvider>(context, listen: false);
      vault.setPrivateChatSecret(pass);
      _goToStep(5);
      return;
    }

    if (_currentStep == 5) {
      // Validate Library Passcode
      final pin = _libraryPasscodeController.text.trim();
      if (pin.isEmpty) {
        setState(() => _passcodeError = 'Please enter a library vault passcode.');
        return;
      }
      setState(() => _passcodeError = null);
      final vault = Provider.of<VaultProvider>(context, listen: false);
      vault.setLibraryPin(pin);
      _goToStep(6);
      return;
    }

    if (_currentStep < 6) {
      _goToStep(_currentStep + 1);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dotActive = AppColors.accent;
    final dotInactive = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0 && _currentStep < 6)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, size: 16, color: textSecondary),
                      onPressed: () => _goToStep(_currentStep - 1),
                    )
                  else
                    const SizedBox(width: 40, height: 40),

                  // Step Dots Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(7, (i) {
                      final selected = i == _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: selected ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected ? dotActive : dotInactive,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      );
                    }),
                  ),

                  // Skip / Sign In (Only on intro steps)
                  if (_currentStep < 2)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                      child: Text('Sign in', style: AppTypography.label(color: AppColors.accent)),
                    )
                  else
                    const SizedBox(width: 40, height: 40),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Intro(textPrimary, textSecondary),
                  _buildStep2ValueProp(textPrimary, textSecondary),
                  _buildStep3CreateAccount(textPrimary, textSecondary),
                  _buildStep4Architecture(textPrimary, textSecondary, isDark),
                  _buildStep5PrivatePasscode(textPrimary, textSecondary),
                  _buildStep6LibraryPasscode(textPrimary, textSecondary),
                  _buildStep7Complete(textPrimary, textSecondary),
                ],
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.md,
              ),
              child: MiraloButton(
                label: _currentStep == 6
                    ? 'Open MIRALO AI'
                    : _currentStep == 2
                        ? 'Create account'
                        : _currentStep == 4 || _currentStep == 5
                            ? 'Set Passcode'
                            : 'Continue',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Intro ──────────────────────────────────────────────────────────
  Widget _buildStep1Intro(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MiraloLogo(size: 64, isIconOnly: true),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'MIRALO AI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your AI. Your Space.',
            style: AppTypography.body(color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Value Prop ─────────────────────────────────────────────────────
  Widget _buildStep2ValueProp(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MiraloLogo(size: 52, isIconOnly: true),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your conversations.\nYour space.',
            style: AppTypography.heading1(color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Designed for clarity, deep focus, and zero privacy leaks.\nFast, modern mobile AI with dual independent security vaults.',
            style: AppTypography.body(color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Step 3: Create Account ─────────────────────────────────────────────────
  Widget _buildStep3CreateAccount(Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Create account', style: AppTypography.heading1(color: textPrimary)),
          const SizedBox(height: 4),
          Text('Set up your credentials for MIRALO AI', style: AppTypography.bodySmall(color: textSecondary)),
          const SizedBox(height: AppSpacing.lg),

          if (_accountError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(_accountError!, style: AppTypography.caption(color: AppColors.danger)),
            ),
          ],

          MiraloTextField(
            controller: _nameController,
            hint: 'Full name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          MiraloTextField(
            controller: _usernameController,
            hint: 'Username (e.g. aarushlohit)',
            prefixIcon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          MiraloTextField(
            controller: _emailController,
            hint: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          MiraloTextField(
            controller: _passController,
            hint: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            showToggleObscure: true,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          MiraloTextField(
            controller: _confirmPassController,
            hint: 'Confirm password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            showToggleObscure: true,
          ),
        ],
      ),
    );
  }

  // ── Step 4: Architecture Overview ──────────────────────────────────────────
  Widget _buildStep4Architecture(Color textPrimary, Color textSecondary, bool isDark) {
    final surface = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome to MIRALO AI',
            style: AppTypography.heading1(color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Three unified spaces in one application:',
            style: AppTypography.bodySmall(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildPillarTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'AI Conversations',
            subtitle: 'Direct cloud & local reasoning with NVIDIA NIM, Gemini, and OpenCode.',
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          _buildPillarTile(
            icon: Icons.shield_outlined,
            title: 'Private Conversations',
            subtitle: 'Encrypted stealth messaging unlocked only via composer secret.',
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          _buildPillarTile(
            icon: Icons.folder_outlined,
            title: 'Secure Library',
            subtitle: 'Personal media vault protected with its own independent passcode.',
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium(color: textPrimary).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption(color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Private Passcode ───────────────────────────────────────────────
  Widget _buildStep5PrivatePasscode(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key_rounded, size: 28, color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Create Private Passcode',
            style: AppTypography.heading1(color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This passcode unlocks your private conversations.',
            style: AppTypography.body(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tip: You will type this directly into the normal AI composer to unlock private contacts.',
            style: AppTypography.caption(color: AppColors.accent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          MiraloTextField(
            controller: _privatePasscodeController,
            hint: 'Secret phrase or passcode (e.g. 1234)',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            showToggleObscure: true,
          ),
          if (_passcodeError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_passcodeError!, style: AppTypography.caption(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }

  // ── Step 6: Library Passcode ───────────────────────────────────────────────
  Widget _buildStep6LibraryPasscode(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_shared_outlined, size: 28, color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Create Library Passcode',
            style: AppTypography.heading1(color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This passcode protects your private files and media.',
            style: AppTypography.body(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Independent from your private chat secret for dual protection.',
            style: AppTypography.caption(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          MiraloTextField(
            controller: _libraryPasscodeController,
            hint: '4-digit Library PIN (e.g. 1234)',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            obscureText: true,
            showToggleObscure: true,
          ),
          if (_passcodeError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_passcodeError!, style: AppTypography.caption(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }

  // ── Step 7: Setup Complete ─────────────────────────────────────────────────
  Widget _buildStep7Complete(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Setup complete',
            style: AppTypography.heading1(color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your private space and AI assistant are ready.\nEnjoy focus, speed, and privacy.',
            style: AppTypography.body(color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
