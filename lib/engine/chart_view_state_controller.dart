import 'package:flutter/material.dart';
import '../domain/trade_zone.dart';

/// Manages chart view state persistence across navigation.
///
/// Stores zoom level, scroll position, and trade zones per symbol
/// so users can return to the same view when navigating back.
class ChartViewStateController extends ChangeNotifier {
  final Map<String, ChartViewState> _stateCache = {};

  /// Saves the current chart state for a symbol
  void saveState(String symbol, ChartViewState state) {
    _stateCache[symbol] = state;
    notifyListeners();
  }

  /// Retrieves saved chart state for a symbol
  ChartViewState? getState(String symbol) {
    return _stateCache[symbol];
  }

  /// Clears saved state for a symbol
  void clearState(String symbol) {
    _stateCache.remove(symbol);
    notifyListeners();
  }

  /// Clears all saved states
  void clearAll() {
    _stateCache.clear();
    notifyListeners();
  }
}

/// Represents the saved state of a chart view
class ChartViewState {
  final double scrollOffset;
  final double zoomLevel;
  final List<TradeZone> zones;

  ChartViewState({
    required this.scrollOffset,
    required this.zoomLevel,
    required this.zones,
  });

  ChartViewState copyWith({
    double? scrollOffset,
    double? zoomLevel,
    List<TradeZone>? zones,
  }) {
    return ChartViewState(
      scrollOffset: scrollOffset ?? this.scrollOffset,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      zones: zones ?? this.zones,
    );
  }
}
