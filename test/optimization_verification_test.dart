// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/backtest/mock_data_repository.dart';
import 'package:volex_terminal/engine/optimization/genetic_optimizer.dart';
import 'package:volex_terminal/engine/strategy/built_in_strategies.dart';

void main() {
  test('Genetic Optimizer Verification', () async {
    // 1. Setup Data
    final repo = MockDataRepository();
    final candles = await repo.fetchHistory(limit: 3000);

    // 2. Setup Prototype (Ghost Trend)
    final prototype = GhostTrendStrategy(slopeThreshold: 0.5);

    // 3. Setup Optimizer (Small population for speed)
    const config = OptimizationConfig(
      populationSize: 10,
      generations: 3,
      mutationRate: 0.5, // High mutation to see changes
    );
    final optimizer = GeneticOptimizer(config: config);

    // 4. Run Evolution
    print("\n--- EVOLUTION START ---");
    final stopwatch = Stopwatch()..start();

    double initialPnL = -99999.0;
    double finalPnL = -99999.0;

    int genCount = 0;
    await for (final generation in optimizer.evolve(prototype, candles)) {
      genCount = generation.number;
      print(
          "Gen ${generation.number}: Best PnL \$${generation.bestResult.totalPnl.toStringAsFixed(2)} | Avg PnL \$${generation.averagePnL.toStringAsFixed(2)}");

      if (genCount == 1) initialPnL = generation.bestResult.totalPnl;
      finalPnL = generation.bestResult.totalPnl;

      // Verify result structure
      expect(
          generation.bestResult.metrics.totalTrades, greaterThanOrEqualTo(0));
    }
    stopwatch.stop();

    print("\n--- EVOLUTION COMPLETE in ${stopwatch.elapsedMilliseconds}ms ---");
    print("Improvement: $initialPnL -> $finalPnL");

    expect(genCount, equals(3));
    // We can't guarantee improvement on random walk data, but we can guarantee execution.
  });
}
