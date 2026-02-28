import 'package:flutter/foundation.dart';

/// State for a single chart instance
class ChartState {
  String timeframe = '1m';
  List<String> activeIndicators = [];
  bool showVolume = true;
  double? lastPrice;

  ChartState();
}

/// Controller for preserving chart state across navigation
class ChartIndicatorController extends ChangeNotifier {
  final Map<String, ChartState> _states = {};

  ChartState getState(String symbol) {
    return _states.putIfAbsent(symbol, () => ChartState());
  }

  void updateTimeframe(String symbol, String timeframe) {
    final state = getState(symbol);
    state.timeframe = timeframe;
    notifyListeners();
  }

  void toggleIndicator(String symbol, String indicator) {
    final state = getState(symbol);
    if (state.activeIndicators.contains(indicator)) {
      state.activeIndicators.remove(indicator);
    } else {
      state.activeIndicators.add(indicator);
    }
    notifyListeners();
  }

  void updateLastPrice(String symbol, double price) {
    final state = getState(symbol);
    state.lastPrice = price;
    notifyListeners();
  }

  void clearState(String symbol) {
    _states.remove(symbol);
    notifyListeners();
  }
}
