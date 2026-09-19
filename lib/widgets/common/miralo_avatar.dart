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

  const MiraloAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.isOnline = false,
    this.backgroundColor,
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

    return Stack(
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
