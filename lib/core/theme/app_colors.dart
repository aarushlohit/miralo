import 'package:flutter/material.dart';

/// MIRALO AI — Centralized Color Tokens
/// Dark ChatGPT-style blue accent (#2878E8). Deep blue-black bg.
/// No purple. No lavender. No cyan. No neon.
class AppColors {
  AppColors._();

  // ─── ACCENT ───────────────────────────────────────────────────
  /// Primary accent: restrained ChatGPT-style blue
  static const Color accent = Color(0xFF2878E8);
  static const Color accentHover = Color(0xFF1F68D0);
  static const Color accentSoft = Color(0xFF0F264A);
  static const Color accentSoftLight = Color(0xFFE8F0FE);

  // Canonical alias
  static const Color accentBlue = accent;

  // ─── DARK THEME (Charcoal Black & Refined Dark Blue Accent) ───
  /// Primary background: #0B0D0F
  static const Color darkBackground = Color(0xFF0B0D0F);
  /// Surface: #121417
  static const Color darkSurfacePrimary = Color(0xFF121417);
  /// Secondary surface: #181B20
  static const Color darkSurfaceSecondary = Color(0xFF181B20);
  /// Elevated surface: #1D2127
  static const Color darkSurfaceElevated = Color(0xFF1D2127);
  static const Color darkSurfaceTertiary = Color(0xFF22262E);
  static const Color darkSurfaceInput = Color(0xFF181B20);

  /// Border: white 6–10% opacity
  static const Color darkBorder = Color(0x14FFFFFF); // 8% opacity
  static const Color darkBorderHighlight = Color(0x1FFFFFFF); // 12% opacity

  /// Primary text: #F5F7FA
  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  /// Secondary text: #A3A9B3
  static const Color darkTextSecondary = Color(0xFFA3A9B3);
  /// Muted: #707782
  static const Color darkTextMuted = Color(0xFF707782);

  // Message surfaces — neutral, identical to AI chat
  static const Color darkMsgUser = Color(0xFF1D2127);
  static const Color darkMsgAi = Color(0xFF121417);

  // ─── LIGHT THEME ──────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurfacePrimary = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F3F6);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceTertiary = Color(0xFFE9EDF2);
  static const Color lightSurfaceInput = Color(0xFFF1F3F6);

  static const Color lightBorder = Color(0xFFE1E4E8);
  static const Color lightBorderHighlight = Color(0xFFCDD2DA);

  static const Color lightTextPrimary = Color(0xFF15171A);
  static const Color lightTextSecondary = Color(0xFF69717C);
  static const Color lightTextMuted = Color(0xFF969DA8);

  // Message surfaces — neutral
  static const Color lightMsgUser = Color(0xFFF1F3F6);
  static const Color lightMsgAi = Color(0xFFFFFFFF);

  // ─── FUNCTIONAL ───────────────────────────────────────────────
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFF3D1015);
  static const Color dangerSoftLight = Color(0xFFFEECED);
  static const Color success = Color(0xFF30A46C);
  static const Color successSoft = Color(0xFF0D2B1F);
  static const Color warning = Color(0xFFF59E0B);

  // Backward compatibility aliases
  static const Color flameOrange = Color(0xFFE5484D);
  static const Color accentIndigo = accent;
  static const Color onlineGreen = Color(0xFF30A46C);

  // ─── LEGACY ALIASES (keep for screens not yet migrated) ───────
  static const Color darkBorderSubtle = darkBorder;
  static const Color lightBorderSubtle = lightBorder;
  static const Color lightAccent = accent;
  static const Color lightAccentHover = accentHover;
  static const Color lightAccentSoft = accentSoftLight;
  static const Color lightDanger = danger;
  static const Color lightSuccess = success;

  // ─── HELPERS ──────────────────────────────────────────────────
  static Color bg(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) =>
      isDark ? darkSurfacePrimary : lightSurfacePrimary;
  static Color surface2(bool isDark) =>
      isDark ? darkSurfaceSecondary : lightSurfaceSecondary;
  static Color border(bool isDark) =>
      isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(bool isDark) =>
      isDark ? darkTextMuted : lightTextMuted;
}

/// Token standard alias
typedef MiraloColors = AppColors;
