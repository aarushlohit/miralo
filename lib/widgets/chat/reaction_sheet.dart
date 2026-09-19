import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Minimal reaction sheet for quick reactions.
class ReactionSheet extends StatelessWidget {
  final Function(String emoji) onSelectEmoji;

  const ReactionSheet({super.key, required this.onSelectEmoji});

  static const List<String> defaultReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  static void show(BuildContext context, {required Function(String emoji) onSelectEmoji}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => ReactionSheet(onSelectEmoji: onSelectEmoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MiraloColors.darkSurfaceSecondary
        : MiraloColors.lightSurfacePrimary;
    final border = isDark
        ? MiraloColors.darkBorder
        : MiraloColors.lightBorder;

    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(MiraloRadius.bottomSheet),
            border: Border.all(color: border),
            boxShadow: MiraloElevation.medium(isDark),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
