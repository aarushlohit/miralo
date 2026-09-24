import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Minimal reaction sheet for quick reactions.
class ReactionSheet extends StatelessWidget {
  final Function(String emoji) onSelectEmoji;

  const ReactionSheet({super.key, required this.onSelectEmoji});

  static const List<String> defaultReactions = [
    '👍',
    '❤️',
    '😘',
    '😂',
    '😮',
    '😢',
    '🙏',
    '🔥',
  ];

  static const List<String> extendedEmojis = [
    '😍', '🥰', '🥳', '😎', '🤩', '🥺', '😭', '🤯', '💀',
    '🎉', '💯', '✨', '👏', '💩', '💙', '💜', '🤍', '🧡',
    '💛', '🖤', '💔', '🙈', '🙊', '🎯', '🚀', '🔥', '💯',
    '🤝', '🎈', '👑', '⭐', '⚡', '💣', '👀', '🤐', '🤗',
  ];

  static void show(BuildContext context, {required Function(String emoji) onSelectEmoji}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => ReactionSheet(onSelectEmoji: onSelectEmoji),
    );
  }

  void _showCustomEmojiPicker(BuildContext context) {
    Navigator.pop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('React with Emoji', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: extendedEmojis.map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelectEmoji(emoji);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent taps inside the box from closing
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(MiraloRadius.bottomSheet),
                border: Border.all(color: border),
                boxShadow: MiraloElevation.medium(isDark),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...defaultReactions.map((emoji) {
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
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showCustomEmojiPicker(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
