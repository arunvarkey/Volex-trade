import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vx_themes.dart';

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
  ThemeData buildThemeData() {
    final base = ThemeData.dark();
    final textTheme = _currentTheme.getTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _currentTheme.primary,
      scaffoldBackgroundColor: _currentTheme.background,
      colorScheme: ColorScheme.dark(
        primary: _currentTheme.primary,
        secondary: _currentTheme.accent,
        surface: _currentTheme.surface,
        error: _currentTheme.danger,
      ),
      textTheme: textTheme,
      dividerColor: _currentTheme.chartGridColor,
      cardTheme: CardThemeData(
        color: _currentTheme.surface,
        elevation: _currentTheme.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _currentTheme.background,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: _currentTheme.fontHeader,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
