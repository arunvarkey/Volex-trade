// lib/features/simulator/strategy_builder/services/templates/ma_crossover_template.dart
import 'package:flutter/material.dart';
import '../../models/strategy_template.dart';
import 'package:volex_terminal/features/simulator/strategy_builder/models/generated_strategy.dart';
import '../../models/template_parameter.dart';
import '../../../../subscriptions/models/subscription_tier.dart';

class MACrossoverTemplate extends StrategyTemplate {
  @override
  String get id => 'ma_crossover';

  @override
  String get name => 'MA Crossover';

  @override
  String get description =>
      'Buy when fast MA crosses above slow MA, sell when crosses below. '
      'Classic trend-following strategy.';

  @override
  String get category => 'Trend Following';

  @override
  IconData get icon => Icons.trending_up;

  @override
  SubscriptionTier get requiredTier => SubscriptionTier.explorerPremium;

  @override
  List<TemplateParameter> get parameters => [
        NumericParameter(
          id: 'fast_ma_period',
          label: 'Fast MA Period',
          description: 'Shorter moving average period',
          defaultValue: 9,
          min: 5,
          max: 20,
        ),
        NumericParameter(
          id: 'slow_ma_period',
          label: 'Slow MA Period',
          description: 'Longer moving average period',
          defaultValue: 21,
          min: 15,
          max: 50,
        ),
        DropdownParameter(
          id: 'ma_type',
          label: 'MA Type',
          description: 'Type of moving average',
          defaultValue: 'EMA',
          options: ['SMA', 'EMA'],
        ),
        NumericParameter(
          id: 'stop_loss_pct',
          label: 'Stop Loss %',
          defaultValue: 4.0,
          min: 1.0,
          max: 10.0,
          decimals: 1,
        ),
        NumericParameter(
          id: 'take_profit_pct',
          label: 'Take Profit %',
          defaultValue: 8.0,
          min: 2.0,
          max: 20.0,
          decimals: 1,
        ),
      ];

  @override
  GeneratedStrategy instantiate(Map<String, dynamic> values) {
    final fastPeriod = values['fast_ma_period'] ?? 9;
    final slowPeriod = values['slow_ma_period'] ?? 21;
    final maType = values['ma_type'] ?? 'EMA';
    final stopLoss = values['stop_loss_pct'] ?? 4.0;
    final takeProfit = values['take_profit_pct'] ?? 8.0;

    return GeneratedStrategy(
      templateId: id,
      name: values['name'] ?? 'My $name Strategy',
      description: description,
      symbol: values['symbol'] ?? 'BTCUSDT',
      timeframe: values['timeframe'] ?? '1h',
      entryConditions: [
        StrategyCondition(
          indicator: maType,
          comparator: 'crosses above',
          value: slowPeriod.toDouble(),
          params: {'period': fastPeriod},
        ),
      ],
      exitConditions: [
        StrategyCondition(
          indicator: maType,
          comparator: 'crosses below',
          value: slowPeriod.toDouble(),
          params: {'period': fastPeriod},
        ),
      ],
      riskParams: RiskParameters(
        stopLossPercent: (stopLoss as num).toDouble(),
        takeProfitPercent: (takeProfit as num).toDouble(),
        positionSizePercent: 2.0,
      ),
      parameters: {
        'fast_ma_period': fastPeriod,
        'slow_ma_period': slowPeriod,
        'ma_type': maType,
        'stop_loss_pct': stopLoss,
        'take_profit_pct': takeProfit,
      },
      educationalExplanation:
          'MA Crossover captures trend changes by comparing a fast and slow moving average.',
      confidenceScore: 0.8,
    );
  }
}
