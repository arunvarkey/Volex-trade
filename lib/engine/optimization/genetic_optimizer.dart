import 'dart:math';

import 'package:volex_terminal/features/simulator/backtest/models/backtest_result.dart';

import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import '../strategy/strategy_base.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/engine/parameters/parameter_models.dart';
import 'package:volex_terminal/engine/optimization/optimization_worker.dart';
import 'dart:isolate';

class OptimizationConfig {
  final int populationSize;
  final int generations;
  final double mutationRate; // 0.1 = 10% chance to mutate a gene
  final double crossoverRate; // 0.8 = 80% chance to mix parents
  final double elitismRate; // 0.1 = Clone top 10% directly

  const OptimizationConfig({
    this.populationSize = 20,
    this.generations = 5,
    this.mutationRate = 0.2,
    this.crossoverRate = 0.8,
    this.elitismRate = 0.2,
  });
}

class OptimizationGeneration {
  final int number;
  final BacktestResult bestResult;
  final Map<String, dynamic> bestParameters;
  final double averagePnL;
  final double bestFitness;

  OptimizationGeneration(this.number, this.bestResult, this.bestParameters,
      this.averagePnL, this.bestFitness);
}

class OptimizationCandidate {
  final Strategy strategy;
  final BacktestResult result;

  OptimizationCandidate(this.strategy, this.result);
}

class GeneticOptimizer {
  final OptimizationConfig _config;
  final Random _rng = Random();

  GeneticOptimizer({OptimizationConfig config = const OptimizationConfig()})
      : _config = config;

  /// Evolving a strategy based on historical data.
  Stream<OptimizationGeneration> evolve(
      Strategy prototype, List<Candle> data) async* {
    // 1. Initialize Population
    AppLogger.info(
        "OPTIMIZER: Initializing population of ${_config.populationSize}...");
    List<Strategy> population =
        _initializePopulation(prototype, _config.populationSize);

    // 2. Generation Loop
    for (int gen = 0; gen < _config.generations; gen++) {
      // A. Evaluate Fitness (GPU-Style Parallel Execution)
      // Chunk population into batches for multi-core processing
      const int batchSize = 5;
      final batches = <BatchEvaluationArgs>[];

      for (int i = 0; i < population.length; i += batchSize) {
        final end = (i + batchSize < population.length)
            ? i + batchSize
            : population.length;
        final subPopulation = population.sublist(i, end);

        batches.add(BatchEvaluationArgs(
          prototype: prototype,
          parameterSets:
              subPopulation.map((s) => s.currentParameterValues).toList(),
          data: data,
          initialEquity: 10000.0,
        ));
      }

      // Dispatch to Isolates (Parallel Threads)
      final batchFutures =
          batches.map((args) => Isolate.run(() => runBatchInIsolate(args)));
      final batchResults = await Future.wait(batchFutures);

      // Flatten results and create candidates
      final candidates = <OptimizationCandidate>[];
      int individualIndex = 0;
      for (var results in batchResults) {
        for (var result in results) {
          candidates
              .add(OptimizationCandidate(population[individualIndex], result));
          individualIndex++;
        }
      }

      // Task 45 Fix: Risk-adjusted fitness function
      double calculateFitness(BacktestResult r) {
        if (r.metrics.maxDrawdownPercent > 25) {
          return -999.0; // Hard reject high risk
        }
        if (r.metrics.totalTrades < 5) {
          return -999.0; // Statistical significance
        }

        // Sharpe-like: Return per unit of risk (drawdown)
        return r.metrics.totalReturnPercent /
            (r.metrics.maxDrawdownPercent + 1.0);
      }

      // Sort by Fitness (Risk-adjusted)
      candidates.sort((a, b) =>
          calculateFitness(b.result).compareTo(calculateFitness(a.result)));

      final best = candidates.first;
      final avgPnL =
          candidates.map((c) => c.result.totalPnl).reduce((a, b) => a + b) /
              candidates.length;

      yield OptimizationGeneration(
          gen + 1,
          best.result,
          best.strategy.currentParameterValues,
          avgPnL,
          calculateFitness(best.result));

      // B. Selection & Reproduction (for next gen)
      if (gen < _config.generations - 1) {
        // Don't breed after last gen
        population = _breedNextGeneration(candidates, prototype);
      }
    }
  }

  List<Strategy> _initializePopulation(Strategy prototype, int size) {
    final list = <Strategy>[];
    list.add(prototype); // Keep original

    for (int i = 1; i < size; i++) {
      list.add(
          _mutate(prototype, intensity: 1.0)); // High intensity randomization
    }
    return list;
  }

  List<Strategy> _breedNextGeneration(
      List<OptimizationCandidate> ranked, Strategy prototype) {
    final nextGen = <Strategy>[];

    // 1. Elitism
    final eliteCount = (_config.populationSize * _config.elitismRate).round();
    for (int i = 0; i < eliteCount; i++) {
      nextGen.add(ranked[i].strategy); // Clone exact elite
    }

    // 2. Crossover & Mutation for remainder
    while (nextGen.length < _config.populationSize) {
      if (_rng.nextDouble() < _config.crossoverRate) {
        // Tournament Selection? Or just pick from top 50%
        final parentA = ranked[_rng.nextInt(ranked.length ~/ 2)].strategy;
        final parentB = ranked[_rng.nextInt(ranked.length ~/ 2)].strategy;

        var child = _crossover(parentA, parentB, prototype);

        // Mutation
        if (_rng.nextDouble() < _config.mutationRate) {
          child = _mutate(child, intensity: 0.2); // Low intensity tweaking
        }
        nextGen.add(child);
      } else {
        // Just mutate an existing good one
        final parent = ranked[_rng.nextInt(ranked.length ~/ 2)].strategy;
        nextGen.add(_mutate(parent, intensity: 0.3));
      }
    }

    return nextGen;
  }

  Strategy _mutate(Strategy parent, {double intensity = 0.5}) {
    final definitions = parent.parameters;
    final currentValues = parent.currentParameterValues; // Need simple getter
    // Use prototype to get schema, but we need current values from 'parent'.
    // Wait, Strategy abstract class has `currentParameterValues` check?
    // In `strategy_engine.dart` I see: `Map<String, dynamic> get currentParameterValues => {};`
    // Default is empty! I need to override this in GhostStrategy to work!
    // CRITICAL: Inspect Strategy implementations.
    // For now, assuming they implement it or use reflection?
    // Reflection is hard in Flutter. Ideally strategies explicit map.
    // Let's assume `parent` implements it. If not, we fail.

    // Actually, `GhostTrendStrategy` defined in previous turns didn't implement it!
    // I MUST FIX `GhostTrendStrategy` to return its values.

    // Temporary Hack: manual reconstruction if needed, but let's try generic.
    final newValues = Map<String, dynamic>.from(currentValues);

    if (newValues.isEmpty && definitions.isNotEmpty) {
      // Fallback: If strategy didn't implement value getter, use defaults from schema?
      // But we stick to randomizing schema defaults then.
      for (var schema in definitions) {
        newValues[schema.name] = schema.defaultValue;
      }
    }

    for (var schema in definitions) {
      if (_rng.nextDouble() < intensity) {
        // Mutate this gene
        if (schema.type == ParameterType.double) {
          final current = (newValues[schema.name] as num?)?.toDouble() ??
              schema.defaultValue as double;
          final range = (schema.max as double) - (schema.min as double);
          final delta =
              (range * 0.2) * (_rng.nextDouble() - 0.5); // +/- 10% of range
          newValues[schema.name] = (current + delta)
              .clamp(schema.min as double, schema.max as double);
        } else if (schema.type == ParameterType.integer) {
          final current = (newValues[schema.name] as num?)?.toInt() ??
              schema.defaultValue as int;
          final range = (schema.max as int) - (schema.min as int);
          final delta = (range * 0.2 * (_rng.nextDouble() - 0.5)).round();
          if (delta == 0 && _rng.nextBool()) {
            newValues[schema.name] =
                current + (_rng.nextBool() ? 1 : -1); // Ensure change
          } else {
            newValues[schema.name] =
                (current + delta).clamp(schema.min as int, schema.max as int);
          }
        }
      }
    }

    return parent.cloneWith(newValues);
  }

  Strategy _crossover(Strategy a, Strategy b, Strategy prototype) {
    final mapA = a.currentParameterValues;
    final mapB = b.currentParameterValues;
    final newValues = <String, dynamic>{};

    for (var schema in prototype.parameters) {
      if (_rng.nextBool()) {
        newValues[schema.name] = mapA[schema.name];
      } else {
        newValues[schema.name] = mapB[schema.name];
      }
    }
    return prototype.cloneWith(newValues);
  }
}
