import 'package:flutter/material.dart';
import '../../models/strategy_template.dart';
import '../../models/template_parameter.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';

import '../../../../subscriptions/models/subscription_tier.dart';

class BreakoutTemplate extends StrategyTemplate {
  @override
  String get id => 'breakout';

  @override
  String get name => 'Bollinger Breakout';

  @override
  String get description =>
      'Buy when price breaks above upper Bollinger Band, sell when below lower band. '
      'Captures momentum moves.';

  @override
  String get category => 'Breakout';

  @override
  IconData get icon => Icons.rocket_launch;

  @override
  SubscriptionTier get requiredTier => SubscriptionTier.explorerPremium;

  @override
  List<TemplateParameter> get parameters => [
        NumericParameter(
          id: 'bb_period',
          label: 'BB Period',
          description: 'Bollinger Bands period',
          defaultValue: 20,
          min: 10,
          max: 30,
        ),
        NumericParameter(
          id: 'bb_std_dev',
          label: 'Standard Deviation',
          description: 'Number of standard deviations for bands',
          defaultValue: 2.0,
          min: 1.5,
          max: 3.0,
          decimals: 1,
        ),
        NumericParameter(
          id: 'stop_loss_pct',
          label: 'Stop Loss %',
          defaultValue: 5.0,
          min: 1.0,
          max: 10.0,
          decimals: 1,
        ),
        NumericParameter(
          id: 'take_profit_pct',
          label: 'Take Profit %',
          defaultValue: 10.0,
          min: 2.0,
          max: 20.0,
          decimals: 1,
        ),
      ];

  @override
  GeneratedStrategy instantiate(Map<String, dynamic> values) {
    final period = values['bb_period'] ?? 20;
    final stdDev = values['bb_std_dev'] ?? 2.0;
    final stopLoss = values['stop_loss_pct'] ?? 5.0;
    final takeProfit = values['take_profit_pct'] ?? 10.0;

    return GeneratedStrategy(
      templateId: id,
      name: values['name'] ?? 'My $name Strategy',
      description: description,
      symbol: values['symbol'] ?? 'BTCUSDT',
      timeframe: values['timeframe'] ?? '1h',
      entryConditions: [
        StrategyCondition(
          indicator: 'Bollinger Bands',
          comparator: 'breaks above',
          value: 0.0,
          params: {'period': period, 'stdDev': stdDev},
        ),
      ],
      exitConditions: [
        StrategyCondition(
          indicator: 'Bollinger Bands',
          comparator: 'breaks below',
          value: 0.0,
          params: {'period': period, 'stdDev': stdDev},
        ),
      ],
      riskParams: RiskParameters(
        stopLossPercent: (stopLoss as num).toDouble(),
        takeProfitPercent: (takeProfit as num).toDouble(),
        positionSizePercent: 2.0,
      ),
      parameters: {
        'bb_period': period,
        'bb_std_dev': stdDev,
        'stop_loss_pct': stopLoss,
        'take_profit_pct': takeProfit,
      },
      educationalExplanation:
          'Bollinger Breakout signals high-momentum moves when price pierces the outer bands.',
      confidenceScore: 0.75,
    );
  }
}
