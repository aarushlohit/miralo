import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ai_chat_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/chat/composer.dart';
import '../../widgets/common/app_sidebar_drawer.dart';
import '../../widgets/common/miralo_app_bar.dart';
import '../../widgets/common/miralo_logo.dart';

/// AI Home Screen (Empty AI Chat — Reference Mockup Screen 5)
///
/// Features:
/// - Top Bar: [☰] Left, Model Selector Pill Center, [•••] More Right.
/// - NO profile avatar in top right (profile lives in sidebar dock).
/// - NO "MIRALO AI" center title in app bar.
/// - Authentic MIRALO logo mark (NO galaxy, NO planet, NO sparkles).
/// - "How can I help you today?" heading & "Your AI. Your Space." subtitle.
/// - 4 minimal suggestion rows with chevron right (>).
/// - 54px floating pill composer with silent secret interception.
class AiHomeScreen extends StatefulWidget {
  const AiHomeScreen({super.key});

  @override
  State<AiHomeScreen> createState() => _AiHomeScreenState();
}

class _AiHomeScreenState extends State<AiHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_Suggestion> _suggestions = [
    _Suggestion(
      icon: Icons.lightbulb_outline_rounded,
      label: 'Explain something',
      prompt: 'Explain quantum computing in simple terms with an everyday analogy.',
    ),
    _Suggestion(
      icon: Icons.edit_note_rounded,
      label: 'Help me write',
      prompt: 'Help me write a concise and polished email proposing a project update.',
    ),
    _Suggestion(
      icon: Icons.summarize_outlined,
      label: 'Summarize this',
      prompt: 'Summarize the core concepts of zero-knowledge cryptography and its applications.',
    ),
    _Suggestion(
      icon: Icons.auto_awesome_outlined,
      label: 'Give me ideas',
      prompt: 'Give me 5 creative project ideas blending local AI intelligence with offline security.',
    ),
  ];

  void _sendPrompt(BuildContext context, String prompt) {
    final ai = Provider.of<AiChatProvider>(context, listen: false);
    ai.createNewChat();
    ai.sendPrompt(prompt);
    Navigator.pushNamed(context, AppRoutes.chat);
  }

  void _showModelSelector(BuildContext context, AiChatProvider ai) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                0,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select AI Model', style: AppTypography.heading3(color: textColor)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.settingsAi);
                    },
                    child: Text(
                      'API Keys',
                      style: AppTypography.caption(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 0.6, thickness: 0.6, color: border),
            ...ai.availableModels.map((m) {
              final isSelected = ai.selectedModel == m;
              return InkWell(
                onTap: () {
                  ai.selectModel(m);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.accent : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m,
                              style: AppTypography.bodyMedium(color: textColor).copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (m == AiModels.gemini25)
                              Text('Google Gemini API • Text-optimized',
                                  style: AppTypography.caption(color: textSecondary))
                            else if (m == AiModels.nvidiaNim)
                              Text('NVIDIA NIM Cloud • Llama 3.1 70B',
                                  style: AppTypography.caption(color: textSecondary))
                            else if (m == AiModels.openCode)
                              Text('DeepSeek / OpenCode endpoint',
                                  style: AppTypography.caption(color: textSecondary)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showHomeMenu(BuildContext context, AiChatProvider ai) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: AppColors.accent),
              title: Text('New Conversation', style: AppTypography.bodyMedium(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                ai.createNewChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded, color: AppColors.accent),
              title: Text('AI Model & API Keys', style: AppTypography.bodyMedium(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.settingsAi);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.accent),
              title: Text('Settings', style: AppTypography.bodyMedium(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ai = Provider.of<AiChatProvider>(context);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final pillBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: const AppSidebarDrawer(),
      appBar: MiraloAppBar(
        leadingIcon: Icons.menu_rounded,
        leadingTooltip: 'Open sidebar',
        onLeadingTap: () => _scaffoldKey.currentState?.openDrawer(),
        // Subtle compact Model Selector in top bar center per section 9
        titleWidget: GestureDetector(
          onTap: () => _showModelSelector(context, ai),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(MiraloDimensions.composerRadius),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ai.selectedModel,
                  style: AppTypography.caption(color: textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
        // Subtle [•••] action button (NO profile avatar in top right)
        actions: [
          MiraloCircularIconButton(
            icon: Icons.more_horiz_rounded,
            iconSize: 18,
            tooltip: 'Options',
            onPressed: () => _showHomeMenu(context, ai),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Main content area ──────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                  vertical: AppSpacing.sm,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Minimal MIRALO logo brand mark (NO galaxy/planet)
                      const Center(
                        child: MiraloLogo(
                          size: 44,
                          isIconOnly: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Heading
                      Text(
                        'How can I help you today?',
                        style: AppTypography.heading1(color: textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Your AI. Your Space.',
                        style: AppTypography.bodySmall(color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 4 Minimal Suggestion Rows (receding into page with >)
                      ..._suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _SuggestionRow(
                              suggestion: s,
                              surface: surfaceColor,
                              border: borderColor,
                              onTap: () => _sendPrompt(context, s.prompt),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating AI Composer with silent secret interception ──
          Composer(
            isPrivate: false,
            hintText: 'Ask anything...',
            onSubmitted: (prompt) => _sendPrompt(context, prompt),
          ),
        ],
      ),
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String label;
  final String prompt;

  const _Suggestion({
    required this.icon,
    required this.label,
    required this.prompt,
  });
}

/// Minimal suggestion row that visually recedes into page per section 11
class _SuggestionRow extends StatelessWidget {
  final _Suggestion suggestion;
  final Color surface;
  final Color border;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.suggestion,
    required this.surface,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiraloDimensions.standardRadius),
            border: Border.all(color: border, width: 0.6),
          ),
          child: Row(
            children: [
              Icon(suggestion.icon, size: 18, color: textMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  suggestion.label,
                  style: AppTypography.bodySmall(color: textPrimary).copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
