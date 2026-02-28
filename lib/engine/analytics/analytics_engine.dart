import 'dart:async';
import 'package:volex_terminal/domain/order.dart';
import '../persistence/persistence_service.dart';
import 'trade_stats.dart';
import '../../core/app_logger.dart';

class AnalyticsEngine {
  final StreamController<TradeStats> _statsController =
      StreamController<TradeStats>.broadcast();
  Stream<TradeStats> get statsStream => _statsController.stream;

  TradeStats _currentStats = TradeStats.empty();
  TradeStats get currentStats => _currentStats;

  final PersistenceService _persistence = PersistenceService();

  AnalyticsEngine() {
    _loadSnapshot();
  }

  void _loadSnapshot() {
    try {
      final raw = _persistence.getState<Map>('last_analytics_snapshot');
      if (raw != null) {
        _currentStats = TradeStats.fromJson(Map<String, dynamic>.from(raw));
        _statsController.add(_currentStats);
        AppLogger.info("ANALYTICS: Restored last snapshot from Hive.");
      }
    } catch (e) {
      AppLogger.error("ANALYTICS: Snapshot restore failed: $e");
    }
  }

  void recompute(List<Order> closedOrders) {
    if (closedOrders.isEmpty) {
      _currentStats = TradeStats.empty();
      _statsController.add(_currentStats);
      return;
    }

    // ... (rest of the recompute logic remains the same)
    final sortedOrders = List<Order>.from(closedOrders);
    sortedOrders.sort((a, b) =>
        (a.closedAt ?? DateTime(0)).compareTo(b.closedAt ?? DateTime(0)));

    int wins = 0;
    int losses = 0;
    int scratch = 0;
    double grossWin = 0;
    double grossLoss = 0;

    double runningEquity = 0;
    double peakEquity = 0;
    double maxDrawdown = 0;

    final equityCurve = <double>[0.0];

    for (final order in sortedOrders) {
      final pnl = order.realizedPnl ?? 0.0;
      runningEquity += pnl;
      equityCurve.add(runningEquity);

      if (runningEquity > peakEquity) peakEquity = runningEquity;
      final absDrawdown = peakEquity - runningEquity;
      if (absDrawdown > maxDrawdown) maxDrawdown = absDrawdown;

      if (pnl > 0) {
        wins++;
        grossWin += pnl;
      } else if (pnl < 0) {
        losses++;
        grossLoss += pnl.abs();
      } else {
        scratch++;
      }
    }

    final total = wins + losses + scratch;
    final winRate = total == 0 ? 0.0 : wins / total;
    final avgWin = wins == 0 ? 0.0 : grossWin / wins;
    final avgLoss = losses == 0 ? 0.0 : grossLoss / losses;
    final profitFactor = grossLoss == 0
        ? (grossWin > 0 ? double.infinity : 0.0)
        : grossWin / grossLoss;
    final lossRate = 1.0 - winRate;
    final expectancy = (winRate * avgWin) - (lossRate * avgLoss);

    _currentStats = TradeStats(
      totalTrades: total,
      winningTrades: wins,
      losingTrades: losses,
      winRate: winRate,
      profitFactor: profitFactor,
      expectancy: expectancy,
      maxDrawdown: maxDrawdown,
      avgWin: avgWin,
      avgLoss: avgLoss,
      grossProfit: grossWin,
      grossLoss: grossLoss,
      equityCurve: equityCurve,
    );

    _statsController.add(_currentStats);

    // Save Snapshot
    _persistence.saveState('last_analytics_snapshot', _currentStats.toJson());
  }

  void dispose() {
    _statsController.close();
  }
}
