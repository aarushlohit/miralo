import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/naughty_dare_model.dart';

class DareCardWidget extends StatelessWidget {
  final NaughtyDareModel dare;
  final bool isLoading;
  final VoidCallback onSpinAgain;
  final VoidCallback onSkip;
  final VoidCallback onSendToChat;
  final VoidCallback onSave;

  const DareCardWidget({
    super.key,
    required this.dare,
    this.isLoading = false,
    required this.onSpinAgain,
    required this.onSkip,
    required this.onSendToChat,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dare.category,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'NVIDIA NIM AI ✨',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Generating romantic prompt with NVIDIA NIM AI...',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.accent),
                  ),
                ],
              ),
            )
          else
            Text(
              dare.dareText,
              style: AppTypography.heading3(color: textPrimary).copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : onSpinAgain,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Generate AI Prompt',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: Icon(Icons.skip_next_outlined, size: 18, color: textSecondary),
                label: Text('Skip', style: AppTypography.bodySmall(color: textSecondary)),
                onPressed: onSkip,
              ),
              TextButton.icon(
                icon: const Icon(Icons.send_outlined, size: 18, color: AppColors.accent),
                label: Text('Send to Chat', style: AppTypography.bodySmall(color: AppColors.accent)),
                onPressed: onSendToChat,
              ),
              TextButton.icon(
                icon: Icon(
                  dare.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                  color: textSecondary,
                ),
                label: Text('Save', style: AppTypography.bodySmall(color: textSecondary)),
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
