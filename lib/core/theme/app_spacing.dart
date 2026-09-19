/// MIRALO AI — Spacing, Radius, Dimensions & Icon tokens per design specification
class AppSpacing {
  AppSpacing._();

  // ─── SPACING (Spec section 20) ──────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // App horizontal margin: 20 px (Spec section 20)
  static const double screenH = 20.0;
  static const double screenHWide = 24.0;

  // Minimum touch target
  static const double touchTarget = 44.0;

  // ─── CORNER RADIUS (Spec section 20) ────────────────────────────
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16; // Standard radius: 16 px
  static const double radiusLg = 22; // Large radius: 22 px
  static const double radiusXl = 24;
  static const double radiusPill = 28; // Composer radius: 28 px
  static const double radiusSheet = 28; // Bottom sheet radius: 28 px

  // Named semantic aliases — smooth organic curves, no boxy rectangles
  static const double inputRadius = 18.0;
  static const double cardRadius = radiusLg; // 22 px
  static const double buttonRadius = radiusLg; // 22 px
  static const double composerRadius = radiusPill;
  static const double sheetRadius = radiusSheet;
  static const double chipRadius = radiusLg;
}

/// Exact component dimensions (Spec section 20)
class MiraloDimensions {
  MiraloDimensions._();

  static const double appHorizontalMargin = 20.0;
  static const double composerHeight = 54.0; // 52–56 px
  static const double buttonSmallHeight = 42.0; // 40–44 px
  static const double iconButtonSize = 42.0; // 40–44 px

  // Avatars (Spec section 20: 32 / 40 / 48 / 72 px)
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 72.0;

  // Standard radius
  static const double standardRadius = 20.0;
  static const double largeRadius = 24.0;
  static const double composerRadius = 28.0;
  static const double bottomSheetRadius = 28.0;
}

/// Icon sizes (Spec section 21)
class MiraloIconSizes {
  MiraloIconSizes._();

  static const double sm = 16.0;
  static const double md = 20.0; // 20–22 px for navigation
  static const double lg = 24.0;
  static const double xl = 28.0;
}

/// Canonical aliases per section 27
typedef MiraloSpacing = AppSpacing;
typedef MiraloRadius = AppSpacing;

