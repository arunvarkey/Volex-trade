import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chart_drawing.dart';

/// Stores user chart drawings, keyed by symbol, in SharedPreferences.
///
/// Self-contained singleton (the same pattern as the other feature services):
/// a lazily-loaded in-memory map that persists on every change and notifies
/// listeners so the chart repaints.
class DrawingService extends ChangeNotifier {
  DrawingService._();
  static final DrawingService instance = DrawingService._();

  static const String _prefsKey = 'chart_drawings_v1';

  /// symbol → drawings.
  final Map<String, List<ChartDrawing>> _bySymbol = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((symbol, list) {
          _bySymbol[symbol] = [
            for (final item in (list as List))
              ChartDrawing.fromJson(item as Map<String, dynamic>),
          ];
        });
      }
    } catch (_) {
      // Corrupt or unavailable storage → start clean rather than crash.
      _bySymbol.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// An unmodifiable view of the drawings for [symbol] (never null).
  List<ChartDrawing> forSymbol(String symbol) =>
      List.unmodifiable(_bySymbol[symbol] ?? const <ChartDrawing>[]);

  int countFor(String symbol) => _bySymbol[symbol]?.length ?? 0;

  Future<void> add(String symbol, ChartDrawing drawing) async {
    (_bySymbol[symbol] ??= <ChartDrawing>[]).add(drawing);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String symbol, String id) async {
    final list = _bySymbol[symbol];
    if (list == null) return;
    final before = list.length;
    list.removeWhere((d) => d.id == id);
    if (list.isEmpty) _bySymbol.remove(symbol);
    if (list.length != before || !_bySymbol.containsKey(symbol)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> clearSymbol(String symbol) async {
    if (_bySymbol.remove(symbol) != null) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      _bySymbol.forEach((symbol, list) {
        map[symbol] = [for (final d in list) d.toJson()];
      });
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {
      // Non-fatal: drawings stay in memory for this session.
    }
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _bySymbol.clear();
    _loaded = false;
    notifyListeners();
    await _persist();
  }
}
