import 'dart:async';
import 'package:flutter/material.dart';
import '../../engine/risk_manager.dart';
import '../../engine/strategy/strategy_engine.dart';
// import '../../data/market_data_repository.dart';
import '../../engine/execution_manager.dart';
import '../../domain/mini_ticker.dart';

import '../../core/service_locator.dart';
import '../../data/i_market_data_repository.dart';
import '../../services/user_mode_service.dart';

class DashboardProvider extends ChangeNotifier {
  final RiskManager _riskManager;
  final IMarketDataRepository _marketRepo;
  final ExecutionManager _execManager;
  StreamSubscription? _priceUpdatesSubscription;

  UserMode _userMode = UserMode.explorer;
  UserMode get userMode => _userMode;

  DashboardProvider({
    RiskManager? riskManager,
    IMarketDataRepository? marketRepo,
    ExecutionManager? execManager,
  })  : _riskManager = riskManager ?? getIt<RiskManager>(),
        _marketRepo = marketRepo ?? getIt<IMarketDataRepository>(),
        _execManager = execManager ?? getIt<ExecutionManager>() {
    _startTimer();
    _subscribeToData();
    _loadUserMode();
  }

  Future<void> _loadUserMode() async {
    final service = getIt<UserModeService>();
    _userMode = await service.getCurrentMode();
    notifyListeners();
  }

  Future<void> refreshUserMode() async {
    await _loadUserMode();
  }

  StrategyEngine? _strategyEngine;

  // Data State
  Map<String, MiniTicker> _watchlistMap = {};
  Map<String, MiniTicker> get watchlistMap => _watchlistMap;

  List<MiniTicker> get watchlistList {
    final list = _watchlistMap.values.toList();

    // Sort by Volume descending first as a baseline
    list.sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));

    // Define priority list
    const priorities = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'BNBUSDT'];

    // Custom sort: Priority items first in defined order, then the rest
    list.sort((a, b) {
      final aIndex = priorities.indexOf(a.symbol);
      final bIndex = priorities.indexOf(b.symbol);

      if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
      if (aIndex != -1) return -1; // a is priority, goes first
      if (bIndex != -1) return 1; // b is priority, goes first

      return 0; // Keep volume order for non-priority items
    });

    return list;
  }

  // Account State
  double get totalBalanceUsdt => _execManager.totalEstimatedBalanceUsdt;

  double _dailyStartBalance = 0.0;
  double get dailyPnL => totalBalanceUsdt - _dailyStartBalance;

  Future<void> loadDailyStartBalance() async {
    // For a fresh session/demo, we want to show 0 PnL initially
    _dailyStartBalance = totalBalanceUsdt;
    notifyListeners();
  }

  Future<void> resetDailyTracking() async {
    _dailyStartBalance = totalBalanceUsdt;
    notifyListeners();
  }

  // UI State
  String riskStatus = "SAFE";
  Color riskColor = Colors.green;
  double currentDrawdown = 0.0;
  double dailyLoss = 0.0;

  String activeStrategyName = "None";
  String nextScanTime = "--";
  String lastSignalAction = "WAIT";
  Color lastSignalColor = Colors.grey;

  Timer? _refreshTimer;
  StreamSubscription? _logSubscription;
  StreamSubscription? _watchlistSubscription;
  StreamSubscription? _execSubscription;

  void setEngine(StrategyEngine engine) {
    _strategyEngine = engine;
    _subscribeToLogs();
    notifyListeners();
  }

  void _subscribeToData() {
    // Watchlist. Each ticker carries its own symbol, so this is the only
    // source that can price every open position correctly — the candle stream
    // below only covers whichever market the chart is on.
    _watchlistSubscription = _marketRepo.watchlistStream.listen((map) {
      _watchlistMap = map;
      for (final ticker in map.values) {
        if (ticker.closePrice > 0) {
          _execManager.updateUnrealizedPnlForSymbol(
              ticker.symbol, ticker.closePrice);
        }
      }
      notifyListeners();
    });

    // Execution Updates (Balances)
    _execManager.addListener(_onExecUpdate);

    // Live candles for the charted symbol — higher frequency than the
    // watchlist poll, so the market being watched updates smoothly.
    //
    // This used to call updateUnrealizedPnl(candle.close), which applies one
    // price to *every* position, every resting limit order and every
    // stop-loss regardless of market. A BTC tick would therefore mark an ETH
    // position at BTC's price, and could trigger that position's stop or fill
    // an unrelated sell limit — a sell limit at 2000 fills the moment any
    // symbol prints above 2000. Candles carry no symbol, so the repository's
    // currentSymbol supplies it.
    _priceUpdatesSubscription = _marketRepo.updatesStream.listen((candle) {
      _execManager.updateUnrealizedPnlForSymbol(
          _marketRepo.currentSymbol, candle.close);
    });
  }

  void _onExecUpdate() {
    notifyListeners();
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final oldRiskStatus = riskStatus;
      final oldDrawdown = currentDrawdown;
      final oldScanTime = nextScanTime;
      final oldStrat = activeStrategyName;

      _updateRiskMetrics();
      _updateScanTimer();

      if (oldRiskStatus != riskStatus ||
          oldDrawdown != currentDrawdown ||
          oldScanTime != nextScanTime ||
          oldStrat != activeStrategyName) {
        notifyListeners();
      }
    });
  }

  void _updateRiskMetrics() {
    final status = _riskManager.getStatus();
    dailyLoss = status['currentDailyLoss'] ?? 0.0;

    final usedRisk = status['aggregateRisk'] ?? 0.0;

    // Fix Task 27: Use actual daily start balance instead of hardcoded 5000.0
    double maxRisk = status['maxAggregateRisk'] ?? _dailyStartBalance;
    if (maxRisk <= 0) maxRisk = totalBalanceUsdt > 0 ? totalBalanceUsdt : 1.0;

    currentDrawdown = (usedRisk / maxRisk).clamp(0.0, 1.0);

    if (status['isEmergencyStopActive'] == true) {
      riskStatus = "LOCKED";
      riskColor = Colors.red;
    } else if (dailyLoss > (status['maxDailyLoss'] * 0.8)) {
      riskStatus = "WARNING";
      riskColor = Colors.orange;
    } else {
      riskStatus = "SYSTEM SAFE";
      riskColor = const Color(0xFF00FFC2); // Neon Green
    }
  }

  void _updateScanTimer() {
    final now = DateTime.now();
    final secondsRemaining = 60 - now.second;
    nextScanTime = "${secondsRemaining}s";

    // Also update strategy name reference if engine available
    if (_strategyEngine?.activeStrategyId != null) {
      final strat =
          _strategyEngine!.getStrategy(_strategyEngine!.activeStrategyId!);
      activeStrategyName = strat?.name ?? "Unknown";
    }
  }

  void _subscribeToLogs() {
    _logSubscription?.cancel();
    _logSubscription = _strategyEngine?.allLogs.listen((log) {
      if (log.action != "NONE") {
        lastSignalAction = log.action;
        lastSignalColor = log.action == "BUY" ? Colors.green : Colors.red;
        notifyListeners();
      }
    });
  }

  /// Helper to get ticker for a specific symbol
  MiniTicker? getTicker(String symbol) {
    return _watchlistMap[symbol.toUpperCase()] ??
        _watchlistMap[symbol.toLowerCase()];
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _logSubscription?.cancel();
    _watchlistSubscription?.cancel();
    _execSubscription?.cancel();
    _priceUpdatesSubscription?.cancel();
    _execManager.removeListener(_onExecUpdate);
    super.dispose();
  }
}
