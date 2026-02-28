import 'strategy_base.dart';
import '../parameters/parameter_models.dart';

import '../../domain/candle_model.dart';
import '../../engine/execution_manager.dart';
import '../../engine/chart_controller.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:uuid/uuid.dart';
import '../utils/technical_analysis.dart';
import 'strategy_recommendation.dart';

class GhostTrendStrategy extends Strategy {
  @override
  String get id => 'ghost_trend_v1';

  @override
  String get name => 'Ghost Trend (Genetic)';

  @override
  String get description =>
      'High-frequency trend following strategy optimized via genetic algorithms.';

  @override
  ValidationStatus get validationStatus => ValidationStatus.failed;

  @override
  String get validationMessage =>
      "⚠️ FAILED VALIDATION (Jan 2024). Max Drawdown > 700%. Do NOT use on Live Capital.";

  // Parameters
  final double slopeThreshold;
  final double stopLossPercent; // e.g. 0.02 (2%)
  final double takeProfitPercent; // e.g. 0.04 (4%)

  DateTime? _lastActionTime;
  final Duration _cooldown = const Duration(minutes: 5);

  final Uuid _uuid = const Uuid();

  GhostTrendStrategy({
    this.slopeThreshold = 0.5,
    this.stopLossPercent = 0.02,
    this.takeProfitPercent = 0.04,
  });

  @override
  List<StrategyParameterSchema> get parameters => [
        const StrategyParameterSchema(
            name: 'slopeThreshold',
            type: ParameterType.double,
            defaultValue: 0.5,
            min: 0.1,
            max: 2.0,
            description: 'Slope Threshold',
            isTraderEditable: true),
        const StrategyParameterSchema(
            name: 'stopLossPercent',
            type: ParameterType.double,
            defaultValue: 0.02,
            min: 0.005,
            max: 0.10,
            description: 'Stop Loss %',
            isTraderEditable: true),
        const StrategyParameterSchema(
            name: 'takeProfitPercent',
            type: ParameterType.double,
            defaultValue: 0.04,
            min: 0.01,
            max: 0.20,
            description: 'Take Profit %',
            isTraderEditable: true),
      ];

  @override
  Map<String, dynamic> get currentParameterValues => {
        'slopeThreshold': slopeThreshold,
        'stopLossPercent': stopLossPercent,
        'takeProfitPercent': takeProfitPercent,
      };

  @override
  Strategy cloneWith(Map<String, dynamic> newValues) {
    return GhostTrendStrategy(
      slopeThreshold:
          (newValues['slopeThreshold'] as num?)?.toDouble() ?? slopeThreshold,
      stopLossPercent:
          (newValues['stopLossPercent'] as num?)?.toDouble() ?? stopLossPercent,
      takeProfitPercent: (newValues['takeProfitPercent'] as num?)?.toDouble() ??
          takeProfitPercent,
    );
  }

  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {
    final ghost = controller.ghost;
    if (ghost == null) return;

    // 1. Check Exits (SL/TP) on existing positions
    // Note: In backtest, we might need intra-candle check (Low/High).
    // The ExecutionService usually handles orders, but strategy manages logic.
    // We iterate backwards to safely modify if needed (though we just issue close).
    for (final order in execution.orders) {
      if (order.isOpen && order.strategyId == "STRATEGY_GHOST") {
        _checkExit(order, candle, execution);
      }
    }

    // Cooldown check
    if (_lastActionTime != null &&
        candle.date.difference(_lastActionTime!) < _cooldown) {
      return;
    }

    // Only enter if NO open orders? Simpler for MVP
    final hasOpenPositions = execution.orders.any((o) => o.isOpen);
    if (hasOpenPositions) return;

    final slope = ghost.slope;

    if (slope > slopeThreshold) {
      // Uptrend -> LONG
      log("Ghost slope $slope > $slopeThreshold. Entering LONG.", "BUY");
      _execute(execution, candle, OrderDirection.long);
      _lastActionTime = candle.date;
    } else if (slope < -slopeThreshold) {
      // Downtrend -> SHORT
      log("Ghost slope $slope < -$slopeThreshold. Entering SHORT.", "SELL");
      _execute(execution, candle, OrderDirection.short);
      _lastActionTime = candle.date;
    }
  }

  void _checkExit(Order order, Candle candle, IExecutionService execution) {
    // Use Low/High for intra-candle worst/best case
    bool hitStop = false;
    bool hitTp = false;
    double exitPrice = candle.close;

    if (order.direction == OrderDirection.long) {
      // Long: Stop if Low < Entry * (1-SL)
      final slPrice = order.entryPrice * (1 - stopLossPercent);
      final tpPrice = order.entryPrice * (1 + takeProfitPercent);

      if (candle.low <= slPrice) {
        hitStop = true;
        exitPrice = slPrice;
      } else if (candle.high >= tpPrice) {
        hitTp = true;
        exitPrice = tpPrice;
      }
    } else {
      // Short: Stop if High > Entry * (1+SL)
      final slPrice = order.entryPrice * (1 + stopLossPercent);
      final tpPrice = order.entryPrice * (1 - takeProfitPercent);

      if (candle.high >= slPrice) {
        hitStop = true;
        exitPrice = slPrice;
      } else if (candle.low <= tpPrice) {
        hitTp = true;
        exitPrice = tpPrice;
      }
    }

    if (hitStop) {
      log("Stop Loss hit. Closing.", "SL");
      execution.closeAllOrders(
          exitPrice); // Simplification: Close all. Ideally close specific.
    } else if (hitTp) {
      log("Take Profit hit. Closing.", "TP");
      execution.closeAllOrders(exitPrice);
    }
  }

  @override
  Future<List<StrategyRecommendation>> analyze(
      String symbol, List<Candle> history) async {
    final recommendations = <StrategyRecommendation>[];
    if (history.length < 50) return []; // Warmup

    // Use a window for analysis to detect crossover
    // EMA Cross 20/50
    final slowEma = TechnicalAnalysis.calculateEMA(history, 50);
    final fastEma = TechnicalAnalysis.calculateEMA(history, 20);

    // To detect crossover, we'd ideally need the previous candle's EMAs too
    final prevHistory = history.sublist(0, history.length - 1);
    final prevSlowEma = TechnicalAnalysis.calculateEMA(prevHistory, 50);
    final prevFastEma = TechnicalAnalysis.calculateEMA(prevHistory, 20);

    bool crossUp = prevFastEma <= prevSlowEma && fastEma > slowEma;
    bool crossDown = prevFastEma >= prevSlowEma && fastEma < slowEma;

    if (crossUp) {
      recommendations.add(StrategyRecommendation(
        strategyName: name,
        symbol: symbol,
        side: OrderSide.buy,
        entryPrice: history.last.close,
        stopLoss: history.last.close * (1 - stopLossPercent),
        takeProfit: history.last.close * (1 + takeProfitPercent),
        reasoning: "Bullish EMA Crossover (20 > 50)",
        confidence: 0.8,
        shouldTrade: true,
      ));
    } else if (crossDown) {
      recommendations.add(StrategyRecommendation(
        strategyName: name,
        symbol: symbol,
        side: OrderSide.sell,
        entryPrice: history.last.close,
        stopLoss: history.last.close * (1 + stopLossPercent),
        takeProfit: history.last.close * (1 - takeProfitPercent),
        reasoning: "Bearish EMA Crossover (20 < 50)",
        confidence: 0.8,
        shouldTrade: true,
      ));
    }

    return recommendations;
  }

  void _execute(
      IExecutionService execution, Candle candle, OrderDirection direction) {
    final order = Order(
      id: _uuid.v4(),
      timestamp: candle.date,
      type: OrderType.market,
      direction: direction,
      entryPrice: candle.close,
      quantity: 1.0, // Default MVP
      price: candle.close,
      status: OrderStatus.filled,
      sourceZoneId: "STRATEGY_GHOST",
      strategyId: "STRATEGY_GHOST", // Tag for lookup
    );
    execution.placeOrder(order);
  }
}

class PnlProtectionStrategy extends Strategy {
  @override
  String get id => 'pnl_protection_v1';

  @override
  String get name => "PnL Safeguard";

  @override
  String get description =>
      'Safety layer that monitors drawdown and protects realized profits.';

  final double stopLoss;
  final double takeProfit;

  PnlProtectionStrategy({
    this.stopLoss = -50.0,
    this.takeProfit = 100.0,
  });

  @override
  List<StrategyParameterSchema> get parameters => [
        const StrategyParameterSchema(
            name: 'stopLoss',
            type: ParameterType.double,
            defaultValue: -50.0,
            min: -500.0,
            max: -10.0,
            description: 'Stop Loss',
            isTraderEditable: true),
        const StrategyParameterSchema(
            name: 'takeProfit',
            type: ParameterType.double,
            defaultValue: 100.0,
            min: 10.0,
            max: 1000.0,
            description: 'Take Profit',
            isTraderEditable: true),
      ];

  @override
  Map<String, dynamic> get currentParameterValues => {
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
      };

  @override
  Strategy cloneWith(Map<String, dynamic> newValues) {
    return PnlProtectionStrategy(
      stopLoss: (newValues['stopLoss'] as num?)?.toDouble() ?? stopLoss,
      takeProfit: (newValues['takeProfit'] as num?)?.toDouble() ?? takeProfit,
    );
  }

  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {
    // 1. Calculate Global PnL (Open Orders Only)
    double totalUnrealized = 0;
    bool hasOpen = false;

    for (final o in execution.orders) {
      if (o.isOpen) {
        totalUnrealized += (o.unrealizedPnl ?? 0);
        hasOpen = true;
      }
    }

    if (!hasOpen) return;

    if (totalUnrealized < stopLoss) {
      log("PnL $totalUnrealized hit Stop Loss ($stopLoss). Closing All.",
          "PANIC CLOSE");
      execution.closeAllOrders(candle.close);
    } else if (totalUnrealized > takeProfit) {
      log("PnL $totalUnrealized hit Take Profit ($takeProfit). Closing All.",
          "TAKE PROFIT");
      execution.closeAllOrders(candle.close);
    }
  }
}

class BollingerRSIStrategy extends Strategy {
  @override
  String get id => 'mean_reversion_v2';

  @override
  String get name => 'Bollinger + RSI Mean Reversion';

  @override
  String get description =>
      'Classic mean reversion strategy using Bollinger Bands for volatility and RSI for momentum.';

  @override
  ValidationStatus get validationStatus => ValidationStatus.failed;
  @override
  String get validationMessage =>
      "⚠️ FAILED VALIDATION (Jan 2024). Consistently unprofitable. Use for Research Only.";

  // Parameters
  final int period;
  final double stdDev;
  final int rsiPeriod;
  final double rsiOverbought;
  final double rsiOversold;
  final double stopLossPercent; // 0.02

  final Uuid _uuid = const Uuid();
  DateTime? _lastActionTime;

  BollingerRSIStrategy({
    this.period = 20,
    this.stdDev = 2.0,
    this.rsiPeriod = 14,
    this.rsiOverbought = 70.0,
    this.rsiOversold = 30.0,
    this.stopLossPercent = 0.02,
  });

  @override
  List<StrategyParameterSchema> get parameters =>
      []; // Skip UI schema for MVP test

  @override
  Map<String, dynamic> get currentParameterValues => {};

  @override
  Strategy cloneWith(Map<String, dynamic> newValues) => BollingerRSIStrategy();

  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {
    // 0. Check Stops (Safety First)
    for (final order in execution.orders) {
      if (order.isOpen && order.strategyId == "STRATEGY_MR") {
        _checkExits(order, candle, execution);
      }
    }

    // 1. Data Requirements
    final history = controller.allCandles;
    if (history.length < 50) return; // Warmup

    // 2. Compute Indicators
    final bb =
        TechnicalAnalysis.calculateBollingerBands(history, period, stdDev);
    final rsi = TechnicalAnalysis.calculateRSI(history, rsiPeriod);

    // Cooldown
    if (_lastActionTime != null &&
        candle.date.difference(_lastActionTime!) < const Duration(minutes: 5)) {
      return;
    }

    final hasOpen = execution.orders.any((o) => o.isOpen);
    if (hasOpen) return;

    // 3. Logic: Contra-Trend
    if (candle.close < bb.lower && rsi < rsiOversold) {
      log("Buy Signal: Close \${candle.close} < Lower \${bb.lower.toStringAsFixed(2)}, RSI \${rsi.toStringAsFixed(1)}",
          "BUY");
      _execute(execution, candle, OrderDirection.long);
      _lastActionTime = candle.date;
    } else if (candle.close > bb.upper && rsi > rsiOverbought) {
      log("Sell Signal: Close \${candle.close} > Upper \${bb.upper.toStringAsFixed(2)}, RSI \${rsi.toStringAsFixed(1)}",
          "SELL");
      _execute(execution, candle, OrderDirection.short);
      _lastActionTime = candle.date;
    }
  }

  void _execute(
      IExecutionService execution, Candle candle, OrderDirection direction) {
    final order = Order(
      id: _uuid.v4(),
      timestamp: candle.date,
      type: OrderType.market,
      direction: direction,
      entryPrice: candle.close,
      quantity: 1.0, // Default MVP
      price: candle.close,
      status: OrderStatus.filled,
      sourceZoneId: "STRATEGY_MR",
      strategyId: "STRATEGY_MR",
    );
    execution.placeOrder(order);
  }

  @override
  Future<List<StrategyRecommendation>> analyze(
      String symbol, List<Candle> history) async {
    final recommendations = <StrategyRecommendation>[];
    if (history.length < period + 1) return [];

    final bb =
        TechnicalAnalysis.calculateBollingerBands(history, period, stdDev);
    final rsi = TechnicalAnalysis.calculateRSI(history, rsiPeriod);
    final candle = history.last;

    if (candle.close < bb.lower && rsi < rsiOversold) {
      recommendations.add(StrategyRecommendation(
        strategyName: name,
        symbol: symbol,
        side: OrderSide.buy,
        entryPrice: candle.close,
        stopLoss: candle.close * (1 - stopLossPercent),
        takeProfit: candle.close * (1 + stopLossPercent * 2), // 2:1 RR
        reasoning: "Mean Reversion: Price below BB Lower + RSI Oversold",
        confidence: 0.7,
        shouldTrade: true,
      ));
    } else if (candle.close > bb.upper && rsi > rsiOverbought) {
      recommendations.add(StrategyRecommendation(
        strategyName: name,
        symbol: symbol,
        side: OrderSide.sell,
        entryPrice: candle.close,
        stopLoss: candle.close * (1 + stopLossPercent),
        takeProfit: candle.close * (1 - stopLossPercent * 2),
        reasoning: "Mean Reversion: Price above BB Upper + RSI Overbought",
        confidence: 0.7,
        shouldTrade: true,
      ));
    }

    return recommendations;
  }

  void _checkExits(Order order, Candle candle, IExecutionService exec) {
    // Simple Stop Loss
    double exitPrice = candle.close;
    bool close = false;

    if (order.direction == OrderDirection.long) {
      if (candle.low < order.entryPrice * (1 - stopLossPercent)) {
        close = true;
        exitPrice = order.entryPrice * (1 - stopLossPercent);
      }
    } else {
      if (candle.high > order.entryPrice * (1 + stopLossPercent)) {
        close = true;
        exitPrice = order.entryPrice * (1 + stopLossPercent);
      }
    }

    if (close) {
      exec.closeAllOrders(exitPrice);
    }
  }
}

class ArbitrageStrategy extends Strategy {
  @override
  String get id => 'arbitrage_v1';
  @override
  String get name => 'Cross-Exchange Arbitrage';

  @override
  String get description =>
      'Exploits price discrepancies between different markets or exchanges.';

  @override
  List<StrategyParameterSchema> get parameters => [];
  @override
  Map<String, dynamic> get currentParameterValues => {};
  @override
  Strategy cloneWith(Map<String, dynamic> newValues) => ArbitrageStrategy();
  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {}
}

class ScalperStrategy extends Strategy {
  @override
  String get id => 'scalper_v1';
  @override
  String get name => 'Micro-Scalper v2';

  @override
  String get description =>
      'Ultra-fast execution targeting small price inefficiencies in high-volume assets.';
  @override
  List<StrategyParameterSchema> get parameters => [];
  @override
  Map<String, dynamic> get currentParameterValues => {};
  @override
  Strategy cloneWith(Map<String, dynamic> newValues) => ScalperStrategy();
  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {}
}

class MarketMakerStrategy extends Strategy {
  @override
  String get id => 'market_maker_v1';
  @override
  String get name => 'Liquidity Maker';

  @override
  String get description =>
      'Provides liquidity to the order book by maintaining simultaneous bid and ask orders.';
  @override
  List<StrategyParameterSchema> get parameters => [];
  @override
  Map<String, dynamic> get currentParameterValues => {};
  @override
  Strategy cloneWith(Map<String, dynamic> newValues) => MarketMakerStrategy();
  @override
  Future<void> onTick(Candle candle, IExecutionService execution,
      ChartController controller) async {}
}
