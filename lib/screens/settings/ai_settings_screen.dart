import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
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
            MiraloSectionHeader('DEFAULT MODEL (TEXT-ONLY)'),
            MiraloSettingsGroup(
              children: ai.availableModels.map((m) {
                final isSelected = ai.selectedModel == m;
                return MiraloListTile(
                  icon: isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  iconColor: isSelected ? AppColors.accent : textSecondary,
                  title: m,
                  subtitle: m == AiModels.gemini25
                      ? 'Google Gemini API • High-speed reasoning'
                      : m == AiModels.nvidiaNim
                          ? 'NVIDIA NIM • Llama 3.1 70B'
                          : m == AiModels.openCode
                              ? 'DeepSeek / OpenCode endpoint'
                              : 'Default balanced text reasoning',
                  showChevron: false,
                  onTap: () => ai.selectModel(m),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            MiraloSectionHeader('API KEYS (CLOUD INFERENCE)'),
            Text(
              'Enter your API keys for live cloud model execution. Keys are stored securely on your device.',
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
