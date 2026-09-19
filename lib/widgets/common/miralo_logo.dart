import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// MIRALO AI — Official Brand Identity
///
/// Authentic brand mark matching the official MIRALO design:
/// - Distinctive circular arc mark `( )`
/// - Full wordmark `MIRALO` with dark & light mode assets
/// - NO galaxy/planet logos, NO generic sparkles, NO blue star squares.
class MiraloLogo extends StatelessWidget {
  final double size;
  final bool isIconOnly;
  final Color? color;
  final bool animate;

  const MiraloLogo({
    super.key,
    this.size = 56,
    this.isIconOnly = true,
    this.color,
    this.animate = false,
    bool showGlow = false,
    bool showSparkle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    if (isIconOnly) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          isDark ? 'assets/miralo_icon_white.png' : 'assets/miralo_icon_dark.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stack) => CustomPaint(
            size: Size(size, size),
            painter: _MiraloMarkPainter(color: primaryColor),
          ),
        ),
      );
    }

    // Full wordmark
    final width = size * 4.5;
    return SizedBox(
      width: width,
      height: size,
      child: Image.asset(
        isDark ? 'assets/miralo_logo_white.png' : 'assets/miralo_logo_dark.png',
        width: width,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) => Center(
          child: Text(
            'M I R A L O',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full MIRALO wordmark widget
class MiraloWordmark extends StatelessWidget {
  final double height;
  final Color? color;

  const MiraloWordmark({
    super.key,
    this.height = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return SizedBox(
      height: height,
      child: Image.asset(
        isDark ? 'assets/miralo_logo_white.png' : 'assets/miralo_logo_dark.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) => Text(
          'M I R A L O',
          style: TextStyle(
            fontSize: height * 0.55,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.5,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Crisp vector fallback for the signature MIRALO `( )` circle glyph
class _MiraloMarkPainter extends CustomPainter {
  final Color color;

  _MiraloMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final strokeWidth = size.width * 0.10;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Left arc: from 110 deg to 250 deg (sweep 140 deg)
    const leftStart = 110.0 * (3.14159265 / 180.0);
    const sweep = 140.0 * (3.14159265 / 180.0);
    canvas.drawArc(rect, leftStart, sweep, false, paint);

    // Right arc: from 290 deg to 70 deg (sweep 140 deg)
    const rightStart = 290.0 * (3.14159265 / 180.0);
    canvas.drawArc(rect, rightStart, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _MiraloMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
