import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ReactionPickerSheet extends StatelessWidget {
  final Function(String emoji) onSelectEmoji;

  const ReactionPickerSheet({super.key, required this.onSelectEmoji});

  static const List<String> defaultReactions = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😍',
    '😢',
    '🔥',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: defaultReactions.map((emoji) {
          return InkWell(
            onTap: () {
              Navigator.pop(context);
              onSelectEmoji(emoji);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
