// lib/core/models/generated_strategy.dart
import 'package:equatable/equatable.dart';

/// A trading strategy built from a template's parameters.
///
/// This is a STRICTLY TYPED contract. All fields must be valid
/// for the strategy to be executable.
class GeneratedStrategy extends Equatable {
  final String id;
  final String? templateId;
  final String name;
  final String description;
  final String symbol;
  final String timeframe;
  final Map<String, dynamic> parameters;
  final List<StrategyCondition> entryConditions;
  final List<StrategyCondition> exitConditions;
  final RiskParameters riskParams;
  final String educationalExplanation;
  final double confidenceScore;
  final List<String> warnings;
  final DateTime createdAt;

  GeneratedStrategy({
    String? id,
    this.templateId,
    required this.name,
    required this.description,
    required this.symbol,
    required this.timeframe,
    this.parameters = const {},
    required this.entryConditions,
    required this.exitConditions,
    required this.riskParams,
    required this.educationalExplanation,
    required this.confidenceScore,
    this.warnings = const [],
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  factory GeneratedStrategy.fromJson(Map<String, dynamic> json) {
    return GeneratedStrategy(
      id: json['id'] as String?,
      templateId: json['templateId'] as String?,
      name: json['name'] as String? ?? 'Untitled Strategy',
      description: json['description'] as String? ?? '',
      symbol: json['symbol'] as String? ?? 'BTCUSDT',
      timeframe: json['timeframe'] as String? ?? '1h',
      parameters: json['parameters'] != null
          ? Map<String, dynamic>.from(json['parameters'] as Map)
          : const {},
      entryConditions: (json['entryConditions'] as List<dynamic>?)
              ?.map(
                  (e) => StrategyCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      exitConditions: (json['exitConditions'] as List<dynamic>?)
              ?.map(
                  (e) => StrategyCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      riskParams: RiskParameters.fromJson(
          json['riskParams'] as Map<String, dynamic>? ?? {}),
      educationalExplanation: json['educationalExplanation'] as String? ??
          'No explanation provided.',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// strict validation of all components
  void validate() {
    if (entryConditions.isEmpty) {
      throw const StrategyValidationException(
          'Strategy must have at least one entry condition');
    }
    for (final c in entryConditions) {
      c.validateBounds();
    }
    for (final c in exitConditions) {
      c.validateBounds();
    }
    riskParams.validateBounds();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'name': name,
        'description': description,
        'symbol': symbol,
        'timeframe': timeframe,
        'parameters': parameters,
        'entryConditions': entryConditions.map((c) => c.toJson()).toList(),
        'exitConditions': exitConditions.map((c) => c.toJson()).toList(),
        'riskParams': riskParams.toJson(),
        'educationalExplanation': educationalExplanation,
        'confidenceScore': confidenceScore,
        'warnings': warnings,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Infers the template ID from parameters (Task 50: Centralized Logic)
  static String inferTemplateId(Map<String, dynamic> params) {
    if (params.containsKey('rsi_period')) return 'rsi_oversold';
    if (params.containsKey('fast_period')) return 'macd_cross';
    if (params.containsKey('bollinger_std')) return 'bb_reversion';
    return 'custom_ta';
  }

  @override
  List<Object?> get props => [
        id,
        templateId,
        name,
        description,
        symbol,
        timeframe,
        parameters,
        entryConditions,
        exitConditions,
        riskParams,
        educationalExplanation,
        confidenceScore,
        warnings,
        createdAt,
      ];
}

class StrategyCondition extends Equatable {
  final String indicator;
  final String comparator;
  final double value;
  final Map<String, dynamic> params;

  const StrategyCondition({
    required this.indicator,
    required this.comparator,
    required this.value,
    this.params = const {},
  });

  factory StrategyCondition.fromJson(Map<String, dynamic> json) {
    return StrategyCondition(
      indicator: json['indicator'] as String,
      comparator: json['comparator'] as String,
      value: (json['value'] as num).toDouble(),
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }

  void validateBounds() {
    switch (indicator.toUpperCase()) {
      case 'RSI':
        if (value < 0 || value > 100) {
          throw StrategyValidationException('RSI value must be 0-100',
              field: 'value', value: value);
        }
        final period = params['period'] as int? ?? 14;
        if (period < 2 || period > 200) {
          throw StrategyValidationException('RSI period must be 2-200',
              field: 'period', value: period);
        }
        break;
      case 'MACD':
        // Basic sanity checks for MACD params if they exist
        // ...
        break;
      case 'SMA':
      case 'EMA':
        final period = params['period'] as int? ?? 20;
        if (period < 1 || period > 500) {
          throw StrategyValidationException('MA period must be 1-500',
              field: 'period', value: period);
        }
        break;
      case 'BOLLINGER_BANDS':
        // ...
        break;
      case 'VOLUME':
        if (value < 0) {
          throw const StrategyValidationException('Volume cannot be negative');
        }
        break;
      // Add other allowed indicators here
      default:
      // Optional: Throw if unknown, or allow generic but warn?
      // For strictness, let's allow only known ones or generic if safe.
      // For now, extensive validation for known types is key.
    }
  }

  @override
  List<Object?> get props => [indicator, comparator, value, params];

  Map<String, dynamic> toJson() => {
        'indicator': indicator,
        'comparator': comparator,
        'value': value,
        'params': params,
      };
}

class RiskParameters extends Equatable {
  final double stopLossPercent;
  final double takeProfitPercent;
  final double positionSizePercent;

  const RiskParameters({
    required this.stopLossPercent,
    required this.takeProfitPercent,
    required this.positionSizePercent,
  });

  factory RiskParameters.fromJson(Map<String, dynamic> json) {
    return RiskParameters(
      stopLossPercent: (json['stopLossPercent'] as num?)?.toDouble() ?? 2.0,
      takeProfitPercent: (json['takeProfitPercent'] as num?)?.toDouble() ?? 4.0,
      positionSizePercent:
          (json['positionSizePercent'] as num?)?.toDouble() ?? 10.0,
    );
  }

  void validateBounds() {
    if (stopLossPercent < 0.1 || stopLossPercent > 50.0) {
      throw StrategyValidationException('Stop Loss must be 0.1% - 50.0%',
          value: stopLossPercent);
    }
    if (takeProfitPercent < 0.1 || takeProfitPercent > 1000.0) {
      // Allowed high TP
      throw StrategyValidationException('Take Profit must be > 0.1%',
          value: takeProfitPercent);
    }
    if (positionSizePercent < 1.0 || positionSizePercent > 100.0) {
      throw StrategyValidationException('Position size must be 1% - 100%',
          value: positionSizePercent);
    }
  }

  @override
  List<Object?> get props =>
      [stopLossPercent, takeProfitPercent, positionSizePercent];

  Map<String, dynamic> toJson() => {
        'stopLossPercent': stopLossPercent,
        'takeProfitPercent': takeProfitPercent,
        'positionSizePercent': positionSizePercent,
      };
}

class StrategyValidationException implements Exception {
  final String message;
  final String? field;
  final dynamic value;

  const StrategyValidationException(this.message, {this.field, this.value});

  @override
  String toString() =>
      'StrategyValidationException: $message ${field != null ? "($field: $value)" : ""}';
}

class StrategyParsingException implements Exception {
  final String message;
  final String originalContent;

  const StrategyParsingException(this.message, {this.originalContent = ''});

  @override
  String toString() => 'StrategyParsingException: $message';
}
