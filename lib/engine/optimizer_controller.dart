import 'dart:async';
import '../domain/candle_model.dart';
import '../domain/symbol_info.dart';
import 'strategy/strategy_engine.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_request.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';
import 'package:volex_terminal/features/simulator/strategy_builder/models/generated_strategy.dart';
import '../core/service_locator.dart';

import 'parameters/parameter_models.dart';

class OptimizationResult {
  final Map<String, double> params;
  final BacktestResult result;

  OptimizationResult(this.params, this.result);
}

class OptimizerController {
  final BacktestEngine _engine = getIt<BacktestEngine>();

  /// Generates the Cartesian Product of all parameter steps
  List<Map<String, double>> _generateGrid(
      List<StrategyParameterSchema> params) {
    List<Map<String, double>> combinations = [{}];

    for (final param in params) {
      if ((param.type == ParameterType.integer ||
              param.type == ParameterType.double) &&
          param.min != null &&
          param.max != null) {
        List<Map<String, double>> nextCombinations = [];

        double step = param.type == ParameterType.integer
            ? 1.0
            : (param.max! - param.min!) / 10.0;
        if (step == 0) step = 1.0;

        // Expand current combinations with this parameter's steps
        for (double val = param.min!.toDouble();
            val <= param.max!.toDouble();
            val += step) {
          // Fix float precision issues (e.g. 0.300000004)
          final cleanVal = double.parse(val.toStringAsFixed(4));

          for (final combo in combinations) {
            final newCombo = Map<String, double>.from(combo);
            newCombo[param.name] = cleanVal;
            nextCombinations.add(newCombo);
          }
        }
        combinations = nextCombinations;
      }
    }

    return combinations;
  }

  /// Runs the grid search
  Stream<OptimizationResult> run({
    required Strategy strategy,
    required SymbolInfo symbol,
    required List<Candle> history,
  }) async* {
    // 1. Generate Grid
    final grid = _generateGrid(strategy.parameters);

    // Task 46 Fix: Cartesian Explosion Guard
    const maxCombinations = 500;
    if (grid.length > maxCombinations) {
      throw ArgumentError('Grid search would require ${grid.length} backtests. '
          'Maximum is $maxCombinations. Reduce parameter ranges or use genetic optimization.');
    }

    // 2. Iterate
    for (final params in grid) {
      // Clone strategy with these params
      final variant = strategy.cloneWith(params);

      // Convert to GeneratedStrategy for Engine
      final genStrategy = GeneratedStrategy(
        name: variant.name,
        description: variant.description,
        symbol: symbol.symbol,
        timeframe: '1h', // Default or need to pass
        parameters: variant.currentParameterValues,
        templateId: _inferTemplateId(variant.name),
        entryConditions: const [], // Engine handles standard templates internally via ID
        exitConditions: const [],
        riskParams: const RiskParameters(
            stopLossPercent: 2, takeProfitPercent: 4, positionSizePercent: 10),
        educationalExplanation: 'Optimization Variant',
        confidenceScore: 0,
      );

      final request = BacktestRequest(
        strategy: genStrategy,
        startDate: history.first.date,
        endDate: history.last.date,
        initialEquity: 10000,
      );

      // Run Backtest
      final result = await _engine.run(request);

      yield OptimizationResult(params, result);

      // Yield to event loop to keep UI responsive-ish
      await Future.delayed(Duration.zero);
    }
  }

  String _inferTemplateId(String name) {
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
