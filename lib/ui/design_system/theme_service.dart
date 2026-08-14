import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vx_themes.dart';
import 'vx_colors.dart';

/// Modern Theme Service for Volex Terminal
/// Handles persistence and dynamic theme switching with premium attributes
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'user_theme_pref';
  VolexTheme _currentTheme = VolexTheme.cyberpunk;
  final SharedPreferences _prefs;

  ThemeService(this._prefs) {
    _loadTheme();
  }

  // --- Core Theme Accessors ---
  VolexTheme get currentTheme => _currentTheme;
  VolexThemeType get themeType => _currentTheme.type;

  // --- Semantic Color Shortcuts ---
  Color get background => _currentTheme.background;
  Color get surface => _currentTheme.surface;
  Color get primary => _currentTheme.primary;
  Color get accent => _currentTheme.accent;
  Color get success => _currentTheme.success;
  Color get danger => _currentTheme.danger;
  Color get candleUp => _currentTheme.candleUp;
  Color get candleDown => _currentTheme.candleDown;
  Color get gridColor => _currentTheme.chartGridColor;

  // --- Dynamic Theme Switching ---
  Future<void> setTheme(VolexThemeType type) async {
    if (_currentTheme.type == type) return;

    _currentTheme = VolexTheme.fromType(type);
    await _prefs.setString(_themeKey, type.name);
    notifyListeners();
  }

  void toggleTheme() {
    final nextIndex =
        (_currentTheme.type.index + 1) % VolexThemeType.values.length;
    setTheme(VolexThemeType.values[nextIndex]);
  }

  void _loadTheme() {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      try {
        final type =
            VolexThemeType.values.firstWhere((e) => e.name == savedTheme);
        _currentTheme = VolexTheme.fromType(type);
      } catch (_) {
        // Fallback to default if string is corrupted
        _currentTheme = VolexTheme.cyberpunk;
      }
    }
  }

  // --- ThemeData Generator for Material App ---
  //
  // A single, consistent professional dark theme so every page's Material
  // widgets (app bars, buttons, inputs, dialogs, sheets, snackbars, chips)
  // inherit the same polished styling. Colors come from VxColors — the palette
  // the whole app already uses — so themed defaults match hand-styled screens.
  ThemeData buildThemeData() {
    final base = ThemeData.dark();
    // One consistent app-wide font (DM Sans) to match VxTypography, instead of
    // the per-theme display fonts (Orbitron/RobotoMono) that made different
    // pages render in different fonts.
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: VxColors.textPrimary,
      displayColor: VxColors.textPrimary,
    );

    const radius12 = BorderRadius.all(Radius.circular(12));
    const radius16 = BorderRadius.all(Radius.circular(16));

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: VxColors.primary,
      scaffoldBackgroundColor: VxColors.background,
      canvasColor: VxColors.background,
      colorScheme: const ColorScheme.dark(
        primary: VxColors.primary,
        onPrimary: Colors.white,
        secondary: VxColors.primary,
        onSecondary: Colors.white,
        surface: VxColors.surface,
        onSurface: VxColors.textPrimary,
        error: VxColors.negative,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: Color(0x14FFFFFF),
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: VxColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VxColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: VxColors.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: VxColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VxColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, letterSpacing: 0.2, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VxColors.primary,
          side: const BorderSide(color: VxColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, letterSpacing: 0.2, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: VxColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VxColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: VxColors.textTertiary),
        labelStyle: const TextStyle(color: VxColors.textSecondary),
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(const Color(0x14FFFFFF)),
        focusedBorder: inputBorder(VxColors.primary, 1.5),
        errorBorder: inputBorder(VxColors.negative),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: VxColors.surfaceBright,
        contentTextStyle: TextStyle(color: VxColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: VxColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VxColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: VxColors.surfaceBright,
        labelStyle: TextStyle(color: VxColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        side: BorderSide.none,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: VxColors.primary),
      splashColor: VxColors.primary.withValues(alpha: 0.08),
      highlightColor: VxColors.primary.withValues(alpha: 0.04),
    );
  }
}
