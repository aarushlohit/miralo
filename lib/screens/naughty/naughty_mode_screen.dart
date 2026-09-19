import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/naughty_dare_model.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/naughty/dare_card.dart';

class NaughtyModeScreen extends StatefulWidget {
  const NaughtyModeScreen({super.key});

  @override
  State<NaughtyModeScreen> createState() => _NaughtyModeScreenState();
}

class _NaughtyModeScreenState extends State<NaughtyModeScreen> {
  String _selectedCategory = 'Sensual';

  final List<String> _categories = [
    'Sweet',
    'Romantic',
    'Flirty',
    'Sensual',
    'Intimate',
    'Couple Fantasy',
    'Random Mix',
  ];

  final List<NaughtyDareModel> _curatedDares = [
    NaughtyDareModel(
      id: 'dare_1',
      category: 'Sensual',
      intensity: 'Playful',
      dareText:
          'Imagine your partner beside you. If you feel comfortable, share one thing about their touch that you appreciate most.',
    ),
    NaughtyDareModel(
      id: 'dare_2',
      category: 'Romantic',
      intensity: 'Sweet',
      dareText:
          'Give your partner a long, uninterrupted embrace and whisper one memory you cherish about them.',
    ),
    NaughtyDareModel(
      id: 'dare_3',
      category: 'Flirty',
      intensity: 'Playful',
      dareText:
          'Send your partner a teasing compliment describing something you look forward to doing together.',
    ),
    NaughtyDareModel(
      id: 'dare_4',
      category: 'Couple Fantasy',
      intensity: 'Intense',
      dareText:
          'Take turns describing a dream getaway together where neither of you checks a clock or looks at a screen.',
    ),
    NaughtyDareModel(
      id: 'dare_5',
      category: 'Sweet',
      intensity: 'Sweet',
      dareText:
          'Maintain gentle eye contact for 30 seconds without speaking, then smile and share what came into your thoughts.',
    ),
  ];

  late NaughtyDareModel _currentDare;

  @override
  void initState() {
    super.initState();
    _currentDare = _curatedDares.first;
  }

  void _spinDare() {
    final random = Random();
    final matching = _curatedDares.where((d) {
      if (_selectedCategory != 'Random Mix' && d.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    final pool = matching.isNotEmpty ? matching : _curatedDares;
    setState(() {
      _currentDare = pool[random.nextInt(pool.length)];
    });
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
        title: Text('Partner Prompts',
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
              Text('CATEGORY', style: AppTypography.labelSmall(color: textSecondary)),
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

              const SizedBox(height: AppSpacing.xl),

              // Interactive Dare Card
              DareCardWidget(
                dare: _currentDare,
                onSpinAgain: _spinDare,
                onSkip: _spinDare,
                onSendToChat: () {
                  final contact = chatProvider.activeContact ??
                      (chatProvider.contacts.isNotEmpty ? chatProvider.contacts.first : null);
                  if (contact != null) {
                    chatProvider.setActiveChat(contact.id);
                    chatProvider.sendTextMessage('Partner Prompt: ${_currentDare.dareText}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sent prompt to ${contact.displayName}!')),
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

              // Consent guarantee banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Consensual & Private. Prompts can always be skipped. Nothing is recorded or uploaded to AI servers.',
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
}
