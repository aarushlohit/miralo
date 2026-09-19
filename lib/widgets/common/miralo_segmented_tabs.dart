import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Segmented tab bar — used in Library (All / Images / Videos / Files)
class MiraloSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<int>? onTabSelected;

  const MiraloSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabChanged,
    this.onTabSelected,
  }) : assert(onTabChanged != null || onTabSelected != null);

  ValueChanged<int> get _callback => onTabChanged ?? onTabSelected!;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final selectedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfacePrimary;
    final selectedBorder = isDark ? AppColors.darkBorderHighlight : AppColors.lightBorderHighlight;
    final selectedText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final unselectedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => _callback(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: selected
                      ? Border.all(color: selectedBorder, width: 0.6)
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: AppTypography.label(
                      color: selected ? selectedText : unselectedText,
                    ).copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
