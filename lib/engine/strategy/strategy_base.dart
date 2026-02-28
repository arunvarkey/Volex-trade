import 'package:volex_terminal/engine/strategy/strategy_recommendation.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/engine/parameters/parameter_models.dart';
import 'package:volex_terminal/engine/execution/i_execution_service.dart';
import 'package:volex_terminal/core/app_logger.dart';

class StrategyLog {
  final DateTime timestamp;
  final String strategyId;
  final String strategyName;
  final String action;
  final String message;
  final String? symbol;

  StrategyLog({
    required this.timestamp,
    required this.strategyId,
    required this.strategyName,
    required this.action,
    required this.message,
    this.symbol,
  });
}

enum ValidationStatus {
  experimental,
  failed,
  verified,
}

abstract class Strategy {
  String get id;
  String get name;
  String get description;

  bool isEnabled = false;

  List<StrategyParameterSchema> get parameters;
  Map<String, dynamic> get currentParameterValues;

  /// Current validation status of the strategy
  ValidationStatus get validationStatus => ValidationStatus.experimental;

  /// Human readable validation message or warnings
  String get validationMessage => "Ready for backtest.";

  Strategy cloneWith(Map<String, dynamic> newValues);

  /// Real-time tick processing
  Future<void> onTick(
      Candle candle, IExecutionService execution, ChartController controller);

  /// Point-in-time analysis of historical data
  Future<List<StrategyRecommendation>> analyze(
      String symbol, List<Candle> history) async {
    return []; // Override in subclasses
  }

  Function(StrategyLog)? onLog;

  void log(String message, [String action = "INFO"]) {
    final sLog = StrategyLog(
      timestamp: DateTime.now(),
      strategyId: id,
      strategyName: name,
      action: action,
      message: message,
    );
    onLog?.call(sLog);
    AppLogger.info("STRATEGY [$id] [$action]: $message");
  }

  void dispose() {
    onLog = null;
  }
}
