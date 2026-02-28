import 'dart:async';

import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';
import 'package:volex_terminal/engine/optimization/genetic_optimizer.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';

class OptimizationJob {
  final Strategy prototype;
  final List<Candle> data;
  final GeneticOptimizer _optimizer;

  // State
  int currentGeneration = 0;
  int totalGenerations = 0;
  BacktestResult? bestResultSoFar;
  bool isRunning = false;

  final StreamController<OptimizationGeneration> _progressController =
      StreamController.broadcast();
  Stream<OptimizationGeneration> get progress => _progressController.stream;

  OptimizationJob({
    required this.prototype,
    required this.data,
    OptimizationConfig config = const OptimizationConfig(),
  })  : _optimizer = GeneticOptimizer(config: config),
        totalGenerations = config.generations;

  Future<void> start() async {
    if (isRunning) return;
    isRunning = true;

    try {
      await for (final gen in _optimizer.evolve(prototype, data)) {
        currentGeneration = gen.number;
        bestResultSoFar = gen.bestResult;
        _progressController.add(gen);
      }
    } finally {
      isRunning = false;
      // Don't close stream immediately if we want to read final state?
      // But typically we close it.
      // _progressController.close();
    }
  }
}
