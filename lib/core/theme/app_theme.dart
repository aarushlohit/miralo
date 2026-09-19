import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// MIRALO AI — Material3 Theme
/// Accent: dark ChatGPT-style blue. No purple.
class AppTheme {
  AppTheme._();

  // ── DARK ────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        // Surfaces
        surface: AppColors.darkSurfacePrimary,
        surfaceDim: AppColors.darkBackground,
        surfaceBright: AppColors.darkSurfaceElevated,
        // Primary = accent blue
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentSoft,
        onPrimaryContainer: AppColors.accentHover,
        // Secondary = muted surface
        secondary: AppColors.darkSurfaceSecondary,
        onSecondary: AppColors.darkTextSecondary,
        secondaryContainer: AppColors.darkSurfaceElevated,
        onSecondaryContainer: AppColors.darkTextPrimary,
        // Tertiary = muted actions
        tertiary: AppColors.darkTextMuted,
        onTertiary: AppColors.darkTextPrimary,
        // Outline
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderHighlight,
        // Text/icon on surface
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        // Error
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(textTheme, AppColors.darkTextPrimary,
          AppColors.darkTextSecondary, AppColors.darkTextMuted),
      appBarTheme: _buildAppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foreground: AppColors.darkTextPrimary,
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: _buildInputTheme(
        fill: AppColors.darkSurfaceInput,
        hint: AppColors.darkTextMuted,
        border: AppColors.darkBorder,
        borderFocus: AppColors.accent,
      ),
      cardTheme: _buildCardTheme(
        color: AppColors.darkSurfacePrimary,
        border: AppColors.darkBorder,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfacePrimary,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.6,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: AppSpacing.xs),
        minLeadingWidth: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.darkTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.darkSurfaceElevated;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildElevatedButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        textStyle: GoogleFonts.inter(
            fontSize: 14, color: AppColors.darkTextPrimary),
      ),
    );
  }

  // ── LIGHT ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: AppColors.lightSurfacePrimary,
        surfaceDim: AppColors.lightBackground,
        surfaceBright: AppColors.lightSurfaceElevated,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentSoftLight,
        onPrimaryContainer: AppColors.accent,
        secondary: AppColors.lightSurfaceSecondary,
        onSecondary: AppColors.lightTextSecondary,
        secondaryContainer: AppColors.lightSurfaceElevated,
        onSecondaryContainer: AppColors.lightTextPrimary,
        tertiary: AppColors.lightTextMuted,
        onTertiary: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorderHighlight,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(textTheme, AppColors.lightTextPrimary,
          AppColors.lightTextSecondary, AppColors.lightTextMuted),
      appBarTheme: _buildAppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foreground: AppColors.lightTextPrimary,
        brightness: Brightness.light,
      ),
      inputDecorationTheme: _buildInputTheme(
        fill: AppColors.lightSurfaceInput,
        hint: AppColors.lightTextMuted,
        border: AppColors.lightBorder,
        borderFocus: AppColors.accent,
      ),
      cardTheme: _buildCardTheme(
        color: AppColors.lightSurfacePrimary,
        border: AppColors.lightBorder,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurfacePrimary,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.lightBorder,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 0.6,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: AppSpacing.xs),
        minLeadingWidth: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.lightSurfaceSecondary;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildElevatedButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        textStyle: GoogleFonts.inter(
            fontSize: 14, color: AppColors.lightTextPrimary),
      ),
    );
  }

  // ── PRIVATE HELPERS ─────────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base, Color primary,
      Color secondary, Color muted) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: base.displayMedium?.copyWith(
          color: primary, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(
          color: primary, fontWeight: FontWeight.w600, fontSize: 19),
      titleMedium: base.titleMedium?.copyWith(
          color: primary, fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: base.bodyLarge?.copyWith(
          color: primary, fontSize: 15, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(
          color: secondary, fontSize: 14, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(color: muted, fontSize: 12),
      labelLarge: base.labelLarge?.copyWith(
          color: primary, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: base.labelMedium?.copyWith(
          color: secondary, fontSize: 12),
      labelSmall: base.labelSmall?.copyWith(
          color: muted, fontSize: 11, letterSpacing: 0.6),
    );
  }

  static AppBarTheme _buildAppBarTheme({
    required Color backgroundColor,
    required Color foreground,
    required Brightness brightness,
  }) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: foreground,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: foreground, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness,
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme({
    required Color fill,
    required Color hint,
    required Color border,
    required Color borderFocus,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: hint, fontSize: 15),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
    );
  }

  static CardThemeData _buildCardTheme(
      {required Color color, required Color border}) {
    return CardThemeData(
      color: color,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: border, width: 0.8),
      ),
    );
  }

  static ButtonStyle _buildElevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      textStyle:
          GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
