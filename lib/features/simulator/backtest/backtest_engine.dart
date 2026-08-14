// lib/engine/backtest/global_backtest_engine.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/domain/order.dart' as dom;
import 'package:volex_terminal/features/academy/services/xp_service.dart';
import 'models/backtest_request.dart';
import 'models/backtest_result.dart';
import 'models/trade_marker.dart';
import 'execution_simulator.dart';
import 'metrics_calculator.dart';
import 'indicator_library.dart';
import 'simulated_execution_service.dart';
// Strategy is generic/dynamic in request for now to avoid circular dependency hell with strategy_base vs engine

class BacktestEngine extends ChangeNotifier {
  final MarketDataRepository _marketDataRepo;
  final List<BacktestResult> _history = [];

  List<BacktestResult> get history => List.unmodifiable(_history);

  BacktestEngine(this._marketDataRepo);

  Future<BacktestResult> run(BacktestRequest request,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final symbol = request.strategy?.symbol ??
          request.runtimeStrategy?.symbol ??
          'BTCUSDT';
      final timeframe = request.strategy?.timeframe ??
          request.runtimeStrategy?.timeframe ??
          '1h';

      final candles = await _marketDataRepo.fetchHistory(
        symbol: symbol,
        interval: timeframe,
      );

      if (candles.length < 100) {
        return BacktestResult.error(
            'Insufficient data for backtest (min 100 candles)');
      }

      // No isolates on web: run the backtest inline on the main thread.
      if (kIsWeb) {
        final result = await runBacktest(BacktestIsolateParams(
          candles: candles,
          strategy: request.strategy,
          runtimeStrategy: request.runtimeStrategy,
          initialEquity: request.initialEquity,
        )).timeout(
          timeout,
          onTimeout: () => BacktestResult.error(
              'Backtest timed out after ${timeout.inSeconds} seconds.'),
        );
        _record(result);
        return result;
      }

      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateEntry,
        _BacktestJob(
          sendPort: receivePort.sendPort,
          params: BacktestIsolateParams(
            candles: candles,
            strategy: request.strategy,
            runtimeStrategy: request.runtimeStrategy,
            initialEquity: request.initialEquity,
          ),
        ),
      );

      // Timeout logic
      final result = await receivePort.first.timeout(
        timeout,
        onTimeout: () {
          isolate.kill(priority: Isolate.immediate);
          return BacktestResult.error(
              'Backtest timed out after ${timeout.inSeconds} seconds. This usually means there\'s an infinite loop in your code. Check your entry/exit conditions.');
        },
      ) as BacktestResult;

      _record(result); // Add to history (+ XP on success)
      return result;
    } catch (e) {
      return BacktestResult.error('Backtest Engine Error: $e');
    }
  }

  /// Records a finished result and, when it succeeded, awards XP for running a
  /// backtest. Repeatable action, so it uses [XpService.addXp] (not once-only).
  void _record(BacktestResult result) {
    _history.insert(0, result);
    if (result.isSuccess) {
      XpService.instance.addXp(XpService.backtestXp);
    }
    notifyListeners();
  }

  static void _isolateEntry(_BacktestJob job) async {
    final result = await runBacktest(job.params);
    job.sendPort.send(result);
  }

  static Future<BacktestResult> runBacktest(
      BacktestIsolateParams params) async {
    if (params.candles.length < 100) {
      return BacktestResult.error(
          'Insufficient data for backtest (min 100 candles)');
    }

    if (params.strategy != null) {
      return _runGeneratedStrategyBacktest(params);
    } else if (params.runtimeStrategy != null) {
      return _runRuntimeStrategyBacktest(params);
    }
    return BacktestResult.error("No strategy provided.");
  }

  /// Bars per year, derived from the spacing between candle timestamps, used
  /// to annualize the Sharpe ratio. Robust across timeframes and independent
  /// of any strategy metadata. Crypto trades 24/7 (365-day year).
  static int _barsPerYear(List<Candle> candles) {
    if (candles.length < 2) return 8760; // fall back to hourly
    final ms = candles[1].time - candles[0].time;
    if (ms <= 0) return 8760;
    const yearMs = 365 * 24 * 60 * 60 * 1000;
    return (yearMs / ms).round().clamp(52, 525600);
  }

  static Future<BacktestResult> _runRuntimeStrategyBacktest(
      BacktestIsolateParams params) async {
    final simulator = ExecutionSimulator(
      slippagePercent: 0.001,
      feeRate: 0.00075,
    );
    final controller = BacktestChartController();
    final equityCurve = <double>[params.initialEquity];
    double currentEquity = params.initialEquity;
    final strategy = params.runtimeStrategy!;

    final startIdx = params.candles.length > 50 ? 50 : 0;

    for (int i = startIdx; i < params.candles.length; i++) {
      final candle = params.candles[i];

      // 1. Tick Simulator
      simulator.tick(candle.date, candle.open);

      // 2. Tick Strategy (Async)
      try {
        await strategy.onTick(candle, simulator, controller);
      } catch (e) {
        // Log error but continue? or fail?
        // For now, let's log internally if we could, or just ignore for robustness
      }

      // 3. Update Equity
      double floatingPnl = 0;
      for (final order in simulator.orders) {
        if (order.status == dom.OrderStatus.filled) {
          floatingPnl += (order.direction == dom.OrderDirection.long)
              ? (candle.close - order.entryPrice) * order.quantity
              : (order.entryPrice - candle.close) * order.quantity;
        }
      }
      currentEquity = params.initialEquity + simulator.netResult + floatingPnl;
      equityCurve.add(currentEquity);
    }

    // Close all at end
    if (params.candles.isNotEmpty) {
      simulator.closeAllOrders(params.candles.last.close);
      currentEquity = params.initialEquity + simulator.netResult;
      equityCurve.add(currentEquity);
    }

    final markers = <TradeMarker>[];
    for (final order in simulator.orders) {
      if (order.status == dom.OrderStatus.filled) {
        markers.add(TradeMarker(
          timestamp: order.timestamp,
          price: order.entryPrice,
          type: TradeType.entry,
          reason: 'Signal Entry',
        ));
      } else if (order.status == dom.OrderStatus.closed) {
        markers.add(TradeMarker(
          timestamp: order.closedAt ?? order.timestamp,
          price: order.exitPrice ?? 0,
          type: TradeType.exit,
          pnl: order.realizedPnl,
          pnlPercent: order.entryPrice != 0
              ? (order.realizedPnl! / (order.entryPrice * order.quantity)) * 100
              : 0,
          reason: 'Signal Exit',
        ));
      }
    }

    final metrics = MetricsCalculator.calculate(
      trades: markers,
      equityCurve: equityCurve,
      initialEquity: params.initialEquity,
      periodsPerYear: _barsPerYear(params.candles),
    );

    return BacktestResult(
      candles: params.candles,
      trades: markers,
      equityCurve: equityCurve,
      metrics: metrics,
      initialEquity: params.initialEquity,
      finalEquity: currentEquity,
      strategy: params.strategy ?? params.runtimeStrategy,
    );
  }

  static BacktestResult _runGeneratedStrategyBacktest(
      BacktestIsolateParams params) {
    final simulator = ExecutionSimulator(
      slippagePercent: 0.001, // 0.1%
      feeRate: 0.00075, // 0.075%
    );

    final equityCurve = <double>[params.initialEquity];
    double currentEquity = params.initialEquity;
    final strategy = params.strategy!;

    // Warm-up
    final startIdx = params.candles.length > 50 ? 50 : 0;

    for (int i = startIdx; i < params.candles.length; i++) {
      final candle = params.candles[i];

      // 1. Tick simulator
      simulator.tick(candle.date, candle.open);

      // 2. Calculate Indicators (Task 40: decision uses candle[i-1].close)
      // Decision at candle[i].open is based on data up to candle[i-1].
      final indicators = _calculateIndicators(params.candles, strategy, i - 1);

      // 3. Check Exit Signals & SL/TP
      _handlePositionManagement(simulator, strategy, indicators, candle);

      // 4. Check Entry Signals
      _handleEntryLogic(
          simulator, strategy, indicators, candle, params.initialEquity);

      // 5. Update Equity Curve
      double floatingPnl = 0;
      for (final order in simulator.orders) {
        if (order.status == dom.OrderStatus.filled) {
          floatingPnl += (order.direction == dom.OrderDirection.long)
              ? (candle.close - order.entryPrice) * order.quantity
              : (order.entryPrice - candle.close) * order.quantity;
        }
      }
      currentEquity = params.initialEquity + simulator.netResult + floatingPnl;
      equityCurve.add(currentEquity);
    }

    // Force Close at end
    if (params.candles.isNotEmpty) {
      simulator.closeAllOrders(params.candles.last.close);
      currentEquity = params.initialEquity + simulator.netResult;
      equityCurve.add(currentEquity);
    }

    // Map simulator orders to TradeMarkers
    final markers = <TradeMarker>[];
    for (final order in simulator.orders) {
      if (order.status == dom.OrderStatus.filled) {
        markers.add(TradeMarker(
          timestamp: order.timestamp,
          price: order.entryPrice,
          type: TradeType.entry,
          reason: 'Signal Entry',
        ));
      } else if (order.status == dom.OrderStatus.closed) {
        markers.add(TradeMarker(
          timestamp: order.closedAt ?? order.timestamp,
          price: order.exitPrice ?? 0,
          type: TradeType.exit,
          pnl: order.realizedPnl,
          pnlPercent: order.entryPrice != 0
              ? (order.realizedPnl! / (order.entryPrice * order.quantity)) * 100
              : 0,
          reason: 'Signal Exit',
        ));
      }
    }

    final metrics = MetricsCalculator.calculate(
      trades: markers,
      equityCurve: equityCurve,
      initialEquity: params.initialEquity,
      periodsPerYear: _barsPerYear(params.candles),
    );

    return BacktestResult(
      candles: params.candles,
      trades: markers,
      equityCurve: equityCurve,
      metrics: metrics,
      initialEquity: params.initialEquity,
      finalEquity: currentEquity,
      strategy: params.strategy ?? params.runtimeStrategy,
    );
  }

  static Map<String, double> _calculateIndicators(
      List<Candle> candles, GeneratedStrategy strategy, int index) {
    final indicators = <String, double>{};

    switch (strategy.templateId) {
      case 'rsi_mean_reversion':
        final period = strategy.parameters['rsi_period'] as int? ?? 14;
        indicators['rsi'] =
            IndicatorLibrary.calculateRSI(candles, period, atIndex: index);
        break;
      case 'ma_crossover':
        final fast = strategy.parameters['fast_ma_period'] as int? ?? 9;
        final slow = strategy.parameters['slow_ma_period'] as int? ?? 21;
        final type = strategy.parameters['ma_type'] as String? ?? 'EMA';

        if (type == 'SMA') {
          indicators['fast_ma'] =
              IndicatorLibrary.calculateSMA(candles, fast, atIndex: index);
          indicators['slow_ma'] =
              IndicatorLibrary.calculateSMA(candles, slow, atIndex: index);
        } else {
          indicators['fast_ma'] =
              IndicatorLibrary.calculateEMA(candles, fast, atIndex: index);
          indicators['slow_ma'] =
              IndicatorLibrary.calculateEMA(candles, slow, atIndex: index);
        }
        break;
      case 'breakout':
        final period = strategy.parameters['bb_period'] as int? ?? 20;
        final stdDev =
            (strategy.parameters['bb_std_dev'] as num?)?.toDouble() ?? 2.0;
        final bb = IndicatorLibrary.calculateBollingerBands(
            candles, period, stdDev,
            atIndex: index);
        indicators['bb_upper'] = bb.upper;
        indicators['bb_lower'] = bb.lower;
        break;
      case 'macd_trend':
        final fast = strategy.parameters['fast_period'] as int? ?? 12;
        final slow = strategy.parameters['slow_period'] as int? ?? 26;
        final signal = strategy.parameters['signal_period'] as int? ?? 9;

        final macd = IndicatorLibrary.calculateMACD(
          candles,
          fastPeriod: fast,
          slowPeriod: slow,
          signalPeriod: signal,
          atIndex: index,
        );
        indicators['macd_line'] = macd.macdLine;
        indicators['macd_signal'] = macd.signalLine;
        indicators['macd_hist'] = macd.histogram;
        break;
    }

    return indicators;
  }

  static void _handlePositionManagement(
      ExecutionSimulator simulator,
      GeneratedStrategy strategy,
      Map<String, double> indicators,
      Candle candle) {
    final openOrders = simulator.orders
        .where((o) => o.status == dom.OrderStatus.filled)
        .toList();
    if (openOrders.isEmpty) return;

    for (final order in openOrders) {
      final pnlPercent =
          ((candle.close - order.entryPrice) / order.entryPrice) *
              100 *
              (order.direction == dom.OrderDirection.long ? 1 : -1);

      if (pnlPercent <= -strategy.riskParams.stopLossPercent ||
          pnlPercent >= strategy.riskParams.takeProfitPercent) {
        simulator.closeOrder(order.id, candle.close);
        continue;
      }

      bool shouldExit = false;
      switch (strategy.templateId) {
        case 'rsi_mean_reversion':
          final rsi = indicators['rsi'] ?? 50;
          final overbought =
              (strategy.parameters['overbought_threshold'] as num?)
                      ?.toDouble() ??
                  70;
          final oversold =
              (strategy.parameters['oversold_threshold'] as num?)?.toDouble() ??
                  30;
          if (order.direction == dom.OrderDirection.long && rsi > overbought) {
            shouldExit = true;
          }
          if (order.direction == dom.OrderDirection.short && rsi < oversold) {
            shouldExit = true;
          }
          break;
        case 'ma_crossover':
          final fast = indicators['fast_ma'] ?? 0;
          final slow = indicators['slow_ma'] ?? 0;
          if (order.direction == dom.OrderDirection.long && fast < slow) {
            shouldExit = true;
          }
          if (order.direction == dom.OrderDirection.short && fast > slow) {
            shouldExit = true;
          }
          break;
        case 'breakout':
          if (order.direction == dom.OrderDirection.short &&
              candle.close > indicators['bb_upper']!) {
            shouldExit = true;
          }
          break;
        case 'macd_trend':
          final macdLine = indicators['macd_line'] ?? 0;
          if (order.direction == dom.OrderDirection.long && macdLine < 0) {
            shouldExit = true; // Exit Long if Cross Below 0
          }
          if (order.direction == dom.OrderDirection.short && macdLine > 0) {
            shouldExit = true; // Exit Short if Cross Above 0
          }
          break;
      }

      if (shouldExit) {
        simulator.closeOrder(order.id, candle.close);
      }
    }
  }

  static void _handleEntryLogic(
      ExecutionSimulator simulator,
      GeneratedStrategy strategy,
      Map<String, double> indicators,
      Candle candle,
      double initialEquity) {
    if (simulator.orders.any((o) => o.status == dom.OrderStatus.filled)) {
      return;
    }

    dom.OrderDirection? signal;
    switch (strategy.templateId) {
      case 'rsi_mean_reversion':
        final rsi = indicators['rsi'] ?? 50;
        final oversold =
            (strategy.parameters['oversold_threshold'] as num?)?.toDouble() ??
                30;
        final overbought =
            (strategy.parameters['overbought_threshold'] as num?)?.toDouble() ??
                70;
        if (rsi < oversold) {
          signal = dom.OrderDirection.long;
        } else if (rsi > overbought) {
          signal = dom.OrderDirection.short;
        }
        break;
      case 'ma_crossover':
        final fast = indicators['fast_ma'] ?? 0;
        final slow = indicators['slow_ma'] ?? 0;
        if (fast > slow) {
          signal = dom.OrderDirection.long;
        } else if (fast < slow) {
          signal = dom.OrderDirection.short;
        }
        break;
      case 'breakout':
        final upper = indicators['bb_upper'] ?? double.infinity;
        final lower = indicators['bb_lower'] ?? -1;
        if (candle.close > upper) {
          signal = dom.OrderDirection.long;
        } else if (candle.close < lower) {
          signal = dom.OrderDirection.short;
        }
        break;
      case 'macd_trend':
        final macdLine = indicators['macd_line'] ?? 0;
        // Simple trend following:
        // MACD > 0 -> Bullish (Buy)
        // MACD < 0 -> Bearish (Sell)
        if (macdLine > 0) {
          signal = dom.OrderDirection.long;
        } else if (macdLine < 0) {
          signal = dom.OrderDirection.short;
        }
        break;
    }

    if (signal != null) {
      // Honest fill: we decided at this candle's OPEN (on data through i-1), so
      // we can only transact at the open — never the not-yet-known close.
      final entryPrice = candle.open;
      if (entryPrice <= 0) return;

      // Honest sizing: a real fraction of *current* equity (positionSizePercent),
      // not a fixed 1 unit. Since we only enter when flat, realized net result
      // is the whole equity delta so far.
      final equity = initialEquity + simulator.netResult;
      final sizeFraction =
          (strategy.riskParams.positionSizePercent / 100).clamp(0.01, 1.0);
      final qty = (equity * sizeFraction) / entryPrice;
      if (qty <= 0) return;

      simulator.placeOrder(dom.Order(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        symbol: strategy.symbol,
        type: dom.OrderType.market,
        direction: signal,
        quantity: qty,
        price: entryPrice,
        timestamp: candle.date,
      ));
    }
  }
}

class BacktestIsolateParams {
  final List<Candle> candles;
  final GeneratedStrategy? strategy;
  final dynamic runtimeStrategy; // Strategy?
  final double initialEquity;
  BacktestIsolateParams({
    required this.candles,
    this.strategy,
    this.runtimeStrategy,
    required this.initialEquity,
  });
}

class _BacktestJob {
  final SendPort sendPort;
  final BacktestIsolateParams params;

  _BacktestJob({required this.sendPort, required this.params});
}
