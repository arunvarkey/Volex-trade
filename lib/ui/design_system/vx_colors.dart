import 'package:flutter/material.dart';

/// Volex Terminal Design System Colors
/// Complete color palette for all screens
class VxColors {
  // ========================================
  // CORE BRAND COLORS (VOLUMETRIC)
  // ========================================

  /// Ultra-modern obsidian base
  static const deepBlack = Color(0xFF0A0E14);

  /// Background with atmospheric depth
  static const background = Color(0xFF0A0E14);

  /// Midnight indigo surface
  static const surface = Color(0xFF111820);

  /// Card with holographic depth
  static const card = Color(0xFF111820);

  /// Luminous surface for active components
  static const surfaceBright = Color(0xFF1A2230);

  /// Card hover state
  static const surfaceHover = Color(0xFF161D27);

  /// Sleek indigo border
  static const border = Color(0x0FFFFFFF); // 6% white as per CSS var(--border)

  // ========================================
  // REFINED DATA COLORS
  // ========================================

  /// Primary action / brand accent — a calm professional blue. Kept distinct
  /// from the market-direction green/red so accents never read as "up/down".
  static const neonCyan = Color(0xFF3B82F6); // Refined blue (brand/primary)

  /// Market up / success — emerald, reserved for positive P&L and buys.
  static const neonGreen = Color(0xFF34D399);

  /// Crimson Pulse (Danger)
  static const neonRed = Color(0xFFF87171); // Soft coral red, less aggressive

  /// Royal Violet
  static const neonPurple = Color(0xFFA78BFA); // Soft violet

  /// Vivid Magenta
  static const neonMagenta = Color(0xFFF472B6); // Soft pink

  /// Lume Yellow
  static const neonYellow = Color(0xFFFBBF24); // Warm amber

  // ========================================
  // SEMANTIC ALIASES
  // ========================================

  static const primary = neonCyan;
  static const accent = neonCyan;
  static const positive = neonGreen;
  static const negative = neonRed;
  static const success = neonGreen;
  static const danger = neonRed;
  static const warning = neonYellow;
  static const info = Color(0xFF00A3FF);

  // ========================================
  // TEXT COLORS
  // ========================================

  /// Primary text (warm off-white)
  static const textPrimary = Color(0xFFE8ECF1);

  /// Secondary text (blue-gray)
  static const textSecondary = Color(0xFF8494A7);

  /// Tertiary text (muted gray-blue)
  static const textTertiary = Color(0xFF4A5568);

  /// Muted text
  static const textMuted = Color(0xFF2D3748);

  // ========================================
  // NEUTRAL COLORS (FULL SCALE)
  // ========================================

  /// Neutral gray base
  static const neutral = Color(0xFF757575);

  /// Neutral 100 - Lightest
  static const neutral100 = Color(0xFFF5F5F5);

  /// Neutral 200
  static const neutral200 = Color(0xFFEEEEEE);

  /// Neutral 300
  static const neutral300 = Color(0xFFBDBDBD);

  /// Neutral 400
  static const neutral400 = Color(0xFF9E9E9E);

  /// Neutral 500 - Base
  static const neutral500 = Color(0xFF9E9E9E);

  /// Neutral 600
  static const neutral600 = Color(0xFF757575);

  /// Neutral 700
  static const neutral700 = Color(0xFF616161);

  /// Neutral 800 - Dark
  static const neutral800 = Color(0xFF424242);

  /// Neutral 900 - Darkest
  static const neutral900 = Color(0xFF212121);

  // ========================================
  // PRIMARY COLOR SHADES
  // ========================================

  /// Primary 100 - Lightest blue
  static const primary100 = Color(0xFFDBEAFE);

  /// Primary 300
  static const primary300 = Color(0xFF93C5FD);

  /// Primary 500 - Base
  static const primary500 = neonCyan;

  /// Primary 700 - Darker blue
  static const primary700 = Color(0xFF1D4ED8);

  /// Primary 900 - Darkest blue
  static const primary900 = Color(0xFF1E3A8A);

  // ========================================
  // GRADIENTS
  // ========================================

  /// Holographic mesh gradient (Indigo to Black)
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1A2230), Color(0xFF0A0E14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Atomic Success gradient
  static const successGradient = LinearGradient(
    colors: [neonGreen, Color(0xFF00D1FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Lume Danger gradient
  static const dangerGradient = LinearGradient(
    colors: [neonRed, Color(0xFF7000FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep Atmosphere gradient
  static const darkGradient = LinearGradient(
    colors: [Color(0xFF0A0A1F), deepBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Volumetric Highlight
  static const highlightGradient = LinearGradient(
    colors: [Colors.white12, Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ========================================
  // TRADING SPECIFIC COLORS
  // ========================================

  /// Buy/long color
  static const buy = neonGreen;

  /// Sell/short color
  static const sell = neonRed;

  /// Neutral/hold color
  static const hold = Color(0xFFFFA500); // Orange

  // ========================================
  // CHART COLORS
  // ========================================

  /// Bullish candle
  static const bullish = neonGreen;

  /// Bearish candle
  static const bearish = neonRed;

  /// Vivid candle colors — brighter/higher-contrast than the UI green/red so
  /// the chart reads crisp and "hi-def" against the dark background.
  static const chartUp = Color(0xFF26E29A);
  static const chartDown = Color(0xFFFF5A6E);

  /// Grid lines
  static const gridLines = Color(0xFF1E2836);

  /// Crosshair
  static const crosshair = Color(0xFF757575);

  // ========================================
  // STATUS COLORS
  // ========================================

  /// Active status
  static const active = neonCyan;

  /// Inactive status
  static const inactive = neutral500;

  /// Pending status
  static const pending = neonYellow;

  /// Complete status
  static const complete = neonGreen;

  /// Error status
  static const error = neonRed;

  // ========================================
  // OPACITY HELPERS
  // ========================================

  /// Glassmorphic translucent surface
  static Color get glassSurface => Colors.white.withValues(alpha: 0.03);

  /// Luminous holographic border
  static Color get holographicBorder => Colors.white.withValues(alpha: 0.12);

  /// Subtle cyan glow for active elements
  static Color get primaryGlow => neonCyan.withValues(alpha: 0.15);
}
