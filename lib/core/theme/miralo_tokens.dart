import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized token definitions for MIRALO AI
/// Defines colors, typography, spacing, radius, elevation, and icon sizes.

typedef MiraloColors = AppColors;

class MiraloSpacing {
  MiraloSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
}

class MiraloRadius {
  MiraloRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;

  // Specific semantic component radius
  static const double composer = 28.0;
  static const double bottomSheet = 28.0;
  static const double card = 16.0;
  static const double button = 20.0;
  static const double pill = 24.0;

  static BorderRadius get r12 => BorderRadius.circular(sm);
  static BorderRadius get r16 => BorderRadius.circular(md);
  static BorderRadius get r20 => BorderRadius.circular(lg);
  static BorderRadius get r24 => BorderRadius.circular(xl);
  static BorderRadius get r28 => BorderRadius.circular(xxl);
}

class MiraloElevation {
  MiraloElevation._();

  static List<BoxShadow> subtle(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> medium(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

class MiraloIconSizes {
  MiraloIconSizes._();

  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
}

class MiraloTypography {
  MiraloTypography._();

  static TextStyle displayLarge({required Color color}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: color,
      );

  static TextStyle titleLarge({required Color color}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle titleMedium({required Color color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle bodyLarge({required Color color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({required Color color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  static TextStyle bodySmall({required Color color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelMedium({required Color color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
