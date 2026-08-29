import 'package:flutter/material.dart';

enum VolexThemeType { cyberpunk, bloomberg, midnight, matrix }

class VolexTheme {
  final VolexThemeType type;
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color success;
  final Color danger;
  final Color warning;
  final Color textPrimary;
  final Color textSecondary;
  final String fontHeader;
  final double cardElevation;

  const VolexTheme({
    required this.type,
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.success,
    required this.danger,
    required this.warning,
    required this.textPrimary,
    required this.textSecondary,
    required this.fontHeader,
    this.cardElevation = 4.0,
    required this.chartGridColor,
    required this.candleUp,
    required this.candleDown,
    required this.selectionColor,
    required this.glowColor,
  });

  final Color chartGridColor;
  final Color candleUp;
  final Color candleDown;
  final Color selectionColor;
  final Color glowColor;

  // A per-theme getTextTheme() lived here, switching between Orbitron,
  // Roboto Mono, Inter and Share Tech Mono. buildThemeData() deliberately
  // ignored it and uses DM Sans for everything — that unification is what
  // fixed pages rendering in different fonts — so it was dead code whose only
  // effect was to keep four extra font families referenced.
  //
  // With fonts now bundled rather than fetched, each referenced family is
  // weight-per-file in the APK, so an unused one is dead weight as well as
  // dead code.

  static const cyberpunk = VolexTheme(
    type: VolexThemeType.cyberpunk,
    background: Color(0xFF080808),
    surface: Color(0xFF141414),
    primary: Color(0xFF00F0FF),
    accent: Color(0xFFBF00FF),
    success: Color(0xFF00FF94),
    danger: Color(0xFFFF2A2A),
    warning: Color(0xFFFFCC00),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    fontHeader: 'Orbitron',
    chartGridColor: Color(0xFF1A1A1A),
    candleUp: Color(0xFF00FF94),
    candleDown: Color(0xFFFF006E),
    selectionColor: Color(0x3300F0FF),
    glowColor: Color(0x1A00F0FF),
  );

  static const bloomberg = VolexTheme(
    type: VolexThemeType.bloomberg,
    background: Color(0xFF0D1117), // Deep Slate
    surface: Color(0xFF161B22),
    primary: Color(0xFFFFA500), // Bloomberg Amber
    accent: Color(0xFF00A3E0), // Bloomberg Blue
    success: Color(0xFF00FF00), // Pure Lime
    danger: Color(0xFFFF0000), // Pure Red
    warning: Color(0xFFFFD700),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF8B949E),
    fontHeader: 'RobotoMono',
    cardElevation: 1.0,
    chartGridColor: Color(0xFF21262D),
    candleUp: Color(0xFF23D160),
    candleDown: Color(0xFFFF3860),
    selectionColor: Color(0x26FFA500),
    glowColor: Color(0x0DFFA500),
  );

  static const midnight = VolexTheme(
    type: VolexThemeType.midnight,
    background: Color(0xFF000000), // Absolute Black
    surface: Color(0xFF0A0A0A),
    primary: Colors.white,
    accent: Color(0xFF333333),
    success: Color(0xFFFFFFFF),
    danger: Color(0xFF444444),
    warning: Color(0xFF888888),
    textPrimary: Colors.white,
    textSecondary: Colors.white38,
    fontHeader: 'Inter',
    cardElevation: 0.0,
    chartGridColor: Color(0xFF111111),
    candleUp: Colors.white,
    candleDown: Color(0xFF444444),
    selectionColor: Color(0x1AFFFFFF),
    glowColor: Color(0x0DFFFFFF),
  );

  static const matrix = VolexTheme(
    type: VolexThemeType.matrix,
    background: Color(0xFF000000),
    surface: Color(0xFF001100),
    primary: Color(0xFF00FF41), // Matrix Green
    accent: Color(0xFF003B00),
    success: Color(0xFF00FF41),
    danger: Color(0xFF008F11),
    warning: Color(0xFFADFF2F),
    textPrimary: Color(0xFF00FF41),
    textSecondary: Color(0xFF008F11),
    fontHeader: 'RobotoMono',
    cardElevation: 2.0,
    chartGridColor: Color(0xFF001100),
    candleUp: Color(0xFF00FF41),
    candleDown: Color(0xFF003B00),
    selectionColor: Color(0x1A00FF41),
    glowColor: Color(0x0D00FF41),
  );

  static VolexTheme fromType(VolexThemeType type) {
    switch (type) {
      case VolexThemeType.cyberpunk:
        return cyberpunk;
      case VolexThemeType.bloomberg:
        return bloomberg;
      case VolexThemeType.midnight:
        return midnight;
      case VolexThemeType.matrix:
        return matrix;
    }
  }
}
