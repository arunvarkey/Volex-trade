import 'dart:async';
import '../domain/candle_model.dart';
import '../domain/symbol_info.dart';
import 'strategy/strategy_engine.dart';
import 'optimization/genetic_optimizer.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'regime_service.dart';

class TuningEvent {
  final DateTime timestamp;
  final String strategyId;
  final String regimeTag;
  final Map<String, double> oldParams;
  final Map<String, double> newParams;
  final double improvement;
  final bool accepted;
  final String reason;

  TuningEvent({
    required this.timestamp,
    required this.strategyId,
    required this.regimeTag,
    required this.oldParams,
    required this.newParams,
    required this.improvement,
    required this.accepted,
    required this.reason,
  });
}

class AutoTunerController {
  final RegimeService _regimeService = RegimeService();
  final StrategyEngine _strategyEngine;

  final List<TuningEvent> _history = [];
  List<TuningEvent> get history => List.unmodifiable(_history);

  bool _isTuning = false;
  bool get isTuning => _isTuning;

  MarketRegime? _currentRegime;
  MarketRegime? get currentRegime => _currentRegime;

  final StreamController<void> _updateController =
      StreamController<void>.broadcast();
  Stream<void> get updates => _updateController.stream;

  AutoTunerController(this._strategyEngine);

  /// Main entry point to check if tuning is needed
  Future<void> sync(SymbolInfo symbol, List<Candle> history) async {
    if (_isTuning || history.length < 100) return;

    // 1. Detect Regime
    final regime = _regimeService.detect(history);

    // If regime changed, trigger a tuning cycle notification
    if (_currentRegime?.tag != regime.tag) {
      _currentRegime = regime;
      _updateController.add(null);

      // In a real app, we'd throttle this heavily or trigger tuneStrategy directly:
      // await tuneStrategy(strategy: ..., symbol: symbol, history: history);
    }
  }

  // ...
  // Note: We instantiate GeneticOptimizer per run to allow config,
  // or we can make it a member if config is static.
  // Given the UI allows slider changes, we should pass config.

  /// Forces a tuning cycle for a specific strategy
  Future<void> tuneStrategy({
    required Strategy strategy,
    required SymbolInfo symbol,
    required List<Candle> history,
  }) async {
    if (_isTuning) return;
    _isTuning = true;
    _updateController.add(null);

    try {
      final regime = _regimeService.detect(history);
      _currentRegime = regime;

      // Use a limited window for tuning (last 500 candles ~ 8h on 1m)
      // optimization_worker expect at least 100
      final window = history.length > 500
          ? history.sublist(history.length - 500)
          : history;

      // Calculate baseline fitness FIRST before any optimization happens
      final currentFitness = await _evaluateCurrent(strategy, symbol, window);

      // Default config for auto-tuning
      const config = OptimizationConfig(
        populationSize: 15,
        generations: 5,
        mutationRate: 0.15,
      );
      final optimizer = GeneticOptimizer(config: config);

      final stream = optimizer.evolve(
        strategy,
        window,
      );

      OptimizationGeneration? finalUpdate;
      await for (final update in stream) {
        finalUpdate = update;
      }

      if (finalUpdate != null) {
        // Cast values to Match legacy expectation where possible or update logic
        final Map<String, double> newParams = finalUpdate.bestParameters
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        final BacktestResult bestResult = finalUpdate.bestResult;

        // Using totalReturnPercent as fitness proxy against baseline
        final improvement =
            bestResult.metrics.totalReturnPercent - currentFitness;

        bool accepted = false;
        String reason = "";

        // Capture BEFORE any engine update is applied
        final oldParams = _getStrategyParams(strategy);

        if (bestResult.metrics.totalTrades < 5) {
          reason =
              "REJECTED: Insufficient trade count (${bestResult.metrics.totalTrades})";
        } else if (improvement < 0.05) {
          reason = "REJECTED: Improvement too small ($improvement)";
        } else if (bestResult.metrics.maxDrawdownPercent > 20) {
          reason =
              "REJECTED: Drawdown too high (${bestResult.metrics.maxDrawdownPercent})";
        } else {
          accepted = true;
          reason = "ACCEPTED: Improvement $improvement";

          // Apply to Engine
          _strategyEngine.updateStrategyParams(strategy.id, newParams);
        }

        _history.insert(
            0,
            TuningEvent(
                timestamp: DateTime.now(),
                strategyId: strategy.id,
                regimeTag: regime.tag,
                oldParams:
                    oldParams, // Now capturing the correct pre-update values
                newParams: newParams,
                improvement: improvement,
                accepted: accepted,
                reason: reason));
      }
    } finally {
      _isTuning = false;
      _updateController.add(null);
    }
  }

  Future<double> _evaluateCurrent(
      Strategy strategy, SymbolInfo symbol, List<Candle> history) async {
    // Adapter for GlobalBacktestEngine
    final genStrategy = GeneratedStrategy(
      name: strategy.name,
      description: strategy.description,
      symbol: symbol.symbol,
      timeframe: '1h',
      parameters: strategy.currentParameterValues,
      templateId: _getTemplateId(strategy),
      entryConditions: const [],
      exitConditions: const [],
      riskParams: const RiskParameters(
          stopLossPercent: 2, takeProfitPercent: 4, positionSizePercent: 10),
      educationalExplanation: 'Baseline',
      confidenceScore: 0,
    );

    final syncResult = await BacktestEngine.runBacktest(BacktestIsolateParams(
      candles: history,
      strategy: genStrategy,
      initialEquity: 10000,
    ));

    return syncResult.metrics.totalReturnPercent;
  }

  Map<String, double> _getStrategyParams(Strategy s) {
    // TODO: implement Strategy.currentParameterValues properly to get LIVE values from StrategyEngine
    // This is tricky because we don't have a generic "get current values" in Strategy yet
    return s.currentParameterValues
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Dispose resources to prevent memory leaks
  void dispose() {
    _updateController.close();
  }

  String _getTemplateId(Strategy strategy) {
    // Attempt to extract templateId if the object has it, otherwise fallback
    try {
      if ((strategy as dynamic).templateId != null) {
        return (strategy as dynamic).templateId;
      }
    } catch (_) {}
    return inferTemplateId(strategy.name);
  }

  String inferTemplateId(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rsi')) {
      return 'rsi_mean_reversion';
    }
    if (lower.contains('mac') || lower.contains('moving average')) {
      return 'ma_crossover';
    }
    if (lower.contains('bollinger') || lower.contains('breakout')) {
      return 'breakout';
    }
    return 'custom';
  }
}
