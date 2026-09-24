import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Circle avatar with initials fallback and optional online indicator.
class MiraloAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final Color? backgroundColor;
  final String? note;
  final bool showNote;

  const MiraloAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.isOnline = false,
    this.backgroundColor,
    this.note,
    this.showNote = true,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    // Deterministic color from name — always blue family, no purple
    final colors = [
      AppColors.accent,
      const Color(0xFF0D5FBF),
      const Color(0xFF1251A3),
      const Color(0xFF1565C0),
      const Color(0xFF0277BD),
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? _avatarColor(name);
    final radius = size / 2;

    final hasNote = showNote && note != null && note!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: imageUrl != null ? Colors.transparent : bg,
            shape: BoxShape.circle,
          ),
          child: imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _initialsWidget(radius),
                  ),
                )
              : _initialsWidget(radius),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.onlineGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  width: 1.5,
                ),
              ),
            ),
          ),
        if (hasNote)
          Positioned(
            top: -20,
            left: -16,
            right: -16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                constraints: const BoxConstraints(maxWidth: 88),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242426) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  note!.trim(),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialsWidget(double radius) {
    return Center(
      child: Text(
        _initials,
        style: AppTypography.captionMedium(color: Colors.white).copyWith(
          fontSize: radius * 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
