// lib/engine/backtest/models/backtest_request.dart
import 'package:volex_terminal/features/simulator/strategy_builder/models/generated_strategy.dart';

class BacktestRequest {
  final GeneratedStrategy? strategy;
  final dynamic runtimeStrategy; // Type: Strategy?
  final DateTime startDate;
  final DateTime endDate;
  final double initialEquity;

  BacktestRequest({
    this.strategy,
    this.runtimeStrategy,
    required this.startDate,
    required this.endDate,
    this.initialEquity = 10000.0,
  });

  int get durationDays => endDate.difference(startDate).inDays;
}
