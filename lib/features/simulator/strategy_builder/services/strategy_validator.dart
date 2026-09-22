// lib/features/simulator/strategy_builder/services/strategy_validator.dart
import '../models/validation_error.dart';
import 'package:volex_terminal/features/simulator/strategy_builder/models/generated_strategy.dart';

class StrategyValidator {
  static const int maxIndicators = 3;
  static const double maxStopLossPercent = 10.0;
  static const double maxTakeProfitPercent = 20.0;
  static const double maxPositionSizePercent = 5.0;
  static const double minPositionSizePercent = 0.5;

  static final allowedTimeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];
  static final allowedSymbols = [
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'ADAUSDT',
    'SOLUSDT',
    'DOGEUSDT',
    'XRPUSDT',
    'DOTUSDT',
    'MATICUSDT',
    'AVAXUSDT',
  ];

  ValidationResult validate(GeneratedStrategy strategy) {
    final errors = <ValidationError>[];

    // Symbol validation
    if (!allowedSymbols.contains(strategy.symbol)) {
      errors.add(ValidationError(
        field: 'symbol',
        code: 'invalid_symbol',
        message: 'Symbol must be one of: ${allowedSymbols.join(", ")}',
      ));
    }

    // Timeframe validation
    if (!allowedTimeframes.contains(strategy.timeframe)) {
      errors.add(ValidationError(
        field: 'timeframe',
        code: 'invalid_timeframe',
        message: 'Timeframe must be one of: ${allowedTimeframes.join(", ")}',
      ));
    }

    // Risk parameters validation
    if (strategy.riskParams.stopLossPercent > maxStopLossPercent) {
      errors.add(ValidationError(
        field: 'stopLoss',
        code: 'stop_loss_too_high',
        message: 'Stop loss cannot exceed $maxStopLossPercent%',
      ));
    }

    if (strategy.riskParams.stopLossPercent <= 0) {
      errors.add(ValidationError(
        field: 'stopLoss',
        code: 'stop_loss_required',
        message: 'Stop loss must be greater than 0%',
      ));
    }

    if (strategy.riskParams.takeProfitPercent > maxTakeProfitPercent) {
      errors.add(ValidationError(
        field: 'takeProfit',
        code: 'take_profit_too_high',
        message: 'Take profit cannot exceed $maxTakeProfitPercent%',
      ));
    }

    if (strategy.riskParams.takeProfitPercent <= 0) {
      errors.add(ValidationError(
        field: 'takeProfit',
        code: 'take_profit_required',
        message: 'Take profit must be greater than 0%',
      ));
    }

    if (strategy.riskParams.positionSizePercent > maxPositionSizePercent) {
      errors.add(ValidationError(
        field: 'positionSize',
        code: 'position_size_too_high',
        message: 'Position size cannot exceed $maxPositionSizePercent%',
      ));
    }

    if (strategy.riskParams.positionSizePercent < minPositionSizePercent) {
      errors.add(ValidationError(
        field: 'positionSize',
        code: 'position_size_too_low',
        message: 'Position size must be at least $minPositionSizePercent%',
      ));
    }

    // Rules validation
    if (strategy.entryConditions.isEmpty) {
      errors.add(ValidationError(
        field: 'rules',
        code: 'no_rules',
        message: 'Strategy must have at least one entry condition',
      ));
    }

    // Risk/reward ratio check
    if (strategy.riskParams.takeProfitPercent <
        strategy.riskParams.stopLossPercent * 1.5) {
      errors.add(ValidationError(
        field: 'risk',
        code: 'poor_risk_reward',
        message:
            'Take profit should be at least 1.5x stop loss for healthy risk/reward ratio',
      ));
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}
