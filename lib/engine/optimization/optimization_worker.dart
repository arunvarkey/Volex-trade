import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';
import 'package:volex_terminal/features/simulator/backtest/backtest_engine.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/engine/strategy/strategy_base.dart';

/// The result of an isolate-based evaluation batch.
class BatchEvaluationResult {
  final List<BacktestResult> results;
  BatchEvaluationResult(this.results);
}

/// The arguments passed to the evaluation isolate.
class BatchEvaluationArgs {
  final Strategy prototype;
  final List<Map<String, dynamic>> parameterSets;
  final List<Candle> data;
  final double initialEquity;

  BatchEvaluationArgs({
    required this.prototype,
    required this.parameterSets,
    required this.data,
    this.initialEquity = 10000.0,
  });
}

// Corrected version for Isolate.run compatibility
Future<List<BacktestResult>> runBatchInIsolate(BatchEvaluationArgs args) async {
  final results = <BacktestResult>[];

  for (final params in args.parameterSets) {
    // Optimization handles legacy Strategy objects, ensuring clean casting/cloning
    final strategyBase = args.prototype.cloneWith(params);

    // Convert to GeneratedStrategy if needed, or assume prototype is compatible
    // For now, GlobalBacktestEngine expects GeneratedStrategy.
    // We need to ensure Strategy is GeneratedStrategy or cast/map it.

    // Convert to GeneratedStrategy for local engine execution
    // TEMPORARY ADAPTER: This bridges the legacy Strategy object to the new data model
    final genStrategy = GeneratedStrategy(
      name: strategyBase.name,
      description: strategyBase.description,
      symbol: 'BTCUSDT', // Default, should be passed in args
      timeframe: '1h',
      parameters: strategyBase.currentParameterValues,
      // Map legacy strategy names to template IDs if possible
      templateId: inferTemplateId(strategyBase.name),
      // Provide dummy defaults for required fields handled by logic override
      entryConditions: const [],
      exitConditions: const [],
      riskParams: const RiskParameters(
          stopLossPercent: 2.0,
          takeProfitPercent: 4.0,
          positionSizePercent: 10.0),
      educationalExplanation: 'Optimized Strategy',
      confidenceScore: 0.0,
    );

    final result = await BacktestEngine.runBacktest(
      BacktestIsolateParams(
        candles: args.data,
        strategy: genStrategy,
        initialEquity: args.initialEquity,
      ),
    );
    results.add(result);
  }

  return results;
}

String? inferTemplateId(String name) {
  final n = name.toLowerCase();
  if (n.contains('rsi')) return 'rsi_mean_reversion';
  if (n.contains('ma') || n.contains('moving')) return 'ma_crossover';
  if (n.contains('breakout') || n.contains('bollinger')) return 'breakout';
  return 'rsi_mean_reversion'; // Fallback
}
