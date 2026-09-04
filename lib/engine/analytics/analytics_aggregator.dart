import 'dart:math';
import 'package:volex_terminal/domain/order.dart';
import '../../ui/design_system/charts/chart_models.dart';
import '../persistence/order_storage_service.dart';
import 'analytics_models.dart';

class LiveAnalyticsData {
  final double totalPnl;
  final int totalTrades;
  final double winRate;
  final double profitFactor;
  final double sharpeRatio;
  final double maxDrawdown;
  final List<PricePoint> equityCurve;
  final TradeDistribution distribution;

  LiveAnalyticsData({
    required this.totalPnl,
    required this.totalTrades,
    required this.winRate,
    required this.profitFactor,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.equityCurve,
    required this.distribution,
  });

  static LiveAnalyticsData empty() => LiveAnalyticsData(
        totalPnl: 0,
        totalTrades: 0,
        winRate: 0,
        profitFactor: 0,
        sharpeRatio: 0,
        maxDrawdown: 0,
        equityCurve: [],
        distribution: const TradeDistribution(),
      );
}

class AnalyticsAggregator {
  static final AnalyticsAggregator _instance = AnalyticsAggregator._internal();
  factory AnalyticsAggregator() => _instance;
  AnalyticsAggregator._internal();

  /// Synchronously computes performance metrics from a list of orders.
  static LiveAnalyticsData compute(List<Order> orders,
      {double initialBalance = 10000.0}) {
    if (orders.isEmpty) return LiveAnalyticsData.empty();

    final closedTrades =
        orders.where((o) => o.status == OrderStatus.closed).toList();
    if (closedTrades.isEmpty) return LiveAnalyticsData.empty();

    double totalPnl = 0;
    int longWins = 0;
    int longLosses = 0;
    int shortWins = 0;
    int shortLosses = 0;
    double grossProfit = 0;
    double grossLoss = 0;

    final points = <PricePoint>[];
    double runningBalance = initialBalance;

    // Add starting point
    points.add(PricePoint(
        timestamp: DateTime.now().subtract(const Duration(hours: 24)),
        price: runningBalance));

    for (final order in closedTrades) {
      final pnl = order.realizedPnl ?? 0.0;
      totalPnl += pnl;

      final bool isLong = order.direction == OrderDirection.long;
      final bool isWin = pnl > 0;

      if (isWin) {
        if (isLong) {
          longWins++;
        } else {
          shortWins++;
        }
        grossProfit += pnl;
      } else {
        if (isLong) {
          longLosses++;
        } else {
          shortLosses++;
        }
        grossLoss += pnl.abs();
      }

      runningBalance += pnl;
      points.add(PricePoint(
          timestamp: order.closedAt ?? DateTime.now(), price: runningBalance));
    }

    final totalTrades = closedTrades.length;
    final totalWins = longWins + shortWins;
    final winRate = totalWins / totalTrades;
    final profitFactor = grossLoss == 0
        ? (grossProfit > 0 ? 99.0 : 0.0)
        : (grossProfit / grossLoss);

    final sharpe = _calculateSharpe(closedTrades);

    return LiveAnalyticsData(
      totalPnl: totalPnl,
      totalTrades: totalTrades,
      winRate: winRate,
      profitFactor: profitFactor,
      sharpeRatio: sharpe,
      maxDrawdown: 0,
      equityCurve: points,
      distribution: TradeDistribution(
        longWins: longWins,
        longLosses: longLosses,
        shortWins: shortWins,
        shortLosses: shortLosses,
      ),
    );
  }

  static double _calculateSharpe(List<Order> orders) {
    if (orders.length < 2) return 0.0;
    final pnls = orders.map((o) => o.realizedPnl ?? 0.0).toList();
    final avg = pnls.reduce((a, b) => a + b) / pnls.length;
    final variance =
        pnls.map((p) => pow(p - avg, 2)).reduce((a, b) => a + b) / pnls.length;
    final stdDev = sqrt(variance);
    if (stdDev == 0) return 0.0;
    return (avg / stdDev) * sqrt(252);
  }

  /// Real per-strategy metrics, computed from that strategy's stored orders.
  ///
  /// This sat alongside getSubscriberAnalytics() and getRevenueAnalytics(),
  /// which returned invented figures — 124 subscribers, $1,240.50 monthly and
  /// $15,400 lifetime revenue, $450.25 "pending payout" — to the creator
  /// dashboard. There is no payments backend and no subscriber, so those two
  /// methods and the dashboard that displayed them are gone rather than
  /// showing anyone money they have not earned.
  Future<StrategyPerformanceMetrics> getPerformanceMetrics(
      String strategyId) async {
    final storage = OrderStorageService();
    final allOrders = await storage.getAllOrders();
    final strategyOrders =
        allOrders.where((o) => o.strategyId == strategyId).toList();
    final data = compute(strategyOrders);

    return StrategyPerformanceMetrics(
      tradesExecuted: data.totalTrades,
      wins: data.distribution.longWins + data.distribution.shortWins,
      losses: data.distribution.longLosses + data.distribution.shortLosses,
      avgReturn: data.totalTrades > 0 ? data.totalPnl / data.totalTrades : 0.0,
      maxDrawdown: data.maxDrawdown,
      sharpeEstimate: data.sharpeRatio,
    );
  }
}
