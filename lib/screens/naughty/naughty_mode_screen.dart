import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/naughty_dare_model.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/naughty/dare_card.dart';

class NaughtyModeScreen extends StatefulWidget {
  const NaughtyModeScreen({super.key});

  @override
  State<NaughtyModeScreen> createState() => _NaughtyModeScreenState();
}

class _NaughtyModeScreenState extends State<NaughtyModeScreen> {
  String _selectedCategory = 'Sensual';
  String _selectedMode = 'mix'; // 'mix', 'truth', 'dare'
  bool _isLoadingAi = false;
  final TextEditingController _customTopicController = TextEditingController();

  final List<String> _categories = [
    'Sweet',
    'Romantic',
    'Flirty',
    'Sensual',
    'Intimate',
    'Couple Fantasy',
    'Random Mix',
  ];

  late NaughtyDareModel _currentDare;

  @override
  void initState() {
    super.initState();
    _currentDare = NaughtyDareModel(
      id: 'initial',
      category: _selectedCategory,
      intensity: 'Playful',
      dareText: 'Truth 💕: What is one secret thing that always makes you smile about me?',
      isAiGenerated: true,
    );
    _spinDare();
  }

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  Future<void> _spinDare() async {
    if (_isLoadingAi) return;
    setState(() => _isLoadingAi = true);

    final customTopic = _customTopicController.text.trim();
    final aiPromptText = await AiService.instance.generateNaughtyTruthOrDare(
      mode: _selectedMode,
      category: _selectedCategory,
      customTopic: customTopic.isNotEmpty ? customTopic : null,
    );

    if (mounted) {
      setState(() {
        _isLoadingAi = false;
        _currentDare = NaughtyDareModel(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          category: _selectedCategory,
          intensity: _selectedMode == 'truth' ? 'Deep' : (_selectedMode == 'dare' ? 'Spicy' : 'Romantic'),
          dareText: aiPromptText,
          isAiGenerated: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vault = Provider.of<VaultProvider>(context);
    final chatProvider = Provider.of<PrivateChatProvider>(context, listen: false);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final iconBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (!vault.isPrivateUnlocked) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, title: const Text('Partner Prompts')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.accent),
                const SizedBox(height: AppSpacing.md),
                Text('Private Access Required',
                    style: AppTypography.heading2(color: textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Unlock private chat first to access partner prompts.',
                  style: AppTypography.body(color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.privateChats),
                  child: const Text('Go to Private Chats'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
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
        title: Text('Partner Prompts — NVIDIA NIM AI',
            style: AppTypography.bodyMedium(color: textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Selector (Mix / Truth / Dare)
              Text('GAME MODE', style: AppTypography.labelSmall(color: textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _buildModeChip('mix', 'Mix 💖', textPrimary, border),
                  const SizedBox(width: 8),
                  _buildModeChip('truth', 'Truth 💕', textPrimary, border),
                  const SizedBox(width: 8),
                  _buildModeChip('dare', 'Dare 🔥', textPrimary, border),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Category Selector
              Text('CATEGORY STYLE', style: AppTypography.labelSmall(color: textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.accent,
                      backgroundColor: iconBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : border,
                          width: 0.8,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _spinDare();
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Custom Question / Topic Input Field
              Text('CUSTOM TOPIC / QUESTION', style: AppTypography.labelSmall(color: textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTopicController,
                      style: AppTypography.bodySmall(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. first kiss, beach date, cuddle time...',
                        hintStyle: AppTypography.caption(color: textSecondary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border, width: 0.8),
                        ),
                      ),
                      onSubmitted: (_) => _spinDare(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.accent),
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    onPressed: _spinDare,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Interactive Dare Card
              DareCardWidget(
                dare: _currentDare,
                isLoading: _isLoadingAi,
                onSpinAgain: _spinDare,
                onSkip: _spinDare,
                onSendToChat: () {
                  final contact = chatProvider.activeContact ??
                      (chatProvider.contacts.isNotEmpty ? chatProvider.contacts.first : null);
                  if (contact != null) {
                    chatProvider.setActiveChat(contact.id);
                    chatProvider.sendTextMessage(_currentDare.dareText);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sent AI prompt to ${contact.displayName}!')),
                    );
                  }
                },
                onSave: () {
                  setState(() {
                    _currentDare = _currentDare.copyWith(isSaved: !_currentDare.isSaved);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_currentDare.isSaved ? 'Prompt saved!' : 'Prompt unsaved.'),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // AI Engine & Consent guarantee banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Powered by NVIDIA NIM AI flagship model. Generates unique, romantic, flirty, and harmless sexy prompts dynamically for couples.',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String modeKey, String label, Color textPrimary, Color border) {
    final isSelected = _selectedMode == modeKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedMode = modeKey);
          _spinDare();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
