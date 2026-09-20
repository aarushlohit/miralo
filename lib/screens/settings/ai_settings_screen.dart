import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/common/miralo_button.dart';
import '../../widgets/common/miralo_list_tile.dart';
import '../../widgets/common/miralo_text_field.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _geminiKeyCtrl = TextEditingController();
  final _nvidiaKeyCtrl = TextEditingController();
  final _openCodeKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _geminiKeyCtrl.text = AiService.instance.geminiApiKey ?? '';
    _nvidiaKeyCtrl.text = AiService.instance.nvidiaApiKey ?? '';
    _openCodeKeyCtrl.text = AiService.instance.openCodeApiKey ?? '';
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    _nvidiaKeyCtrl.dispose();
    _openCodeKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    await AiService.instance.setGeminiApiKey(_geminiKeyCtrl.text);
    await AiService.instance.setNvidiaApiKey(_nvidiaKeyCtrl.text);
    await AiService.instance.setOpenCodeApiKey(_openCodeKeyCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('API keys saved successfully.'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ai = Provider.of<AiChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isSpecial = auth.isSpecialUser;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back_ios_new, size: 16, color: textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        title: Text(
          'AI Models & Endpoints',
          style: AppTypography.bodyMedium(color: textPrimary).copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.md,
          ),
          children: [
            if (isSpecial) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Access Enabled (@${auth.currentUser?.username})',
                            style: AppTypography.bodyMedium(color: textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Default backend API keys for NVIDIA NIM, Google Gemini, and OpenCode are active. Custom BYOK keys are completely optional.',
                            style: AppTypography.caption(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            MiraloSectionHeader('DEFAULT MODEL (TEXT & MULTIMODAL)'),
            MiraloSettingsGroup(
              children: ai.availableModels.map((m) {
                final isSelected = ai.selectedModel == m;
                String subtitle = 'Default balanced text reasoning';
                if (m == AiModels.gemini25) {
                  subtitle = 'Google Gemini (gemini-3.5-flash / gemini-2.5-flash) • Fast Multimodal';
                } else if (m == AiModels.nvidiaNim) {
                  subtitle = 'NVIDIA NIM (glm-5.3-flash, llama-3.2-11b-vision, kimi-k3)';
                } else if (m == AiModels.openCode) {
                  subtitle = 'OpenCode Zen (big-pickle, mimo-v2.5, muse-spark)';
                }

                return MiraloListTile(
                  icon: isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  iconColor: isSelected ? AppColors.accent : textSecondary,
                  title: m,
                  subtitle: subtitle,
                  showChevron: false,
                  onTap: () => ai.selectModel(m),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            MiraloSectionHeader('API KEYS (CLOUD INFERENCE)'),
            Text(
              isSpecial
                  ? 'Custom API keys (optional for special users). Leave empty to use system backend keys.'
                  : 'Enter your API keys for live cloud model execution. Keys are stored securely on your device.',
              style: AppTypography.caption(color: textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),

            MiraloTextField(
              controller: _geminiKeyCtrl,
              hint: 'Gemini API Key',
              prefixIcon: Icons.vpn_key_outlined,
              obscureText: true,
              showToggleObscure: true,
            ),
            const SizedBox(height: AppSpacing.sm + 2),

            MiraloTextField(
              controller: _nvidiaKeyCtrl,
              hint: 'NVIDIA NIM API Key',
              prefixIcon: Icons.memory_outlined,
              obscureText: true,
              showToggleObscure: true,
            ),
            const SizedBox(height: AppSpacing.sm + 2),

            MiraloTextField(
              controller: _openCodeKeyCtrl,
              hint: 'OpenCode / DeepSeek API Key',
              prefixIcon: Icons.code_rounded,
              obscureText: true,
              showToggleObscure: true,
            ),
            const SizedBox(height: AppSpacing.lg),

            MiraloButton(
              label: 'Save API Keys',
              onPressed: _saveKeys,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
