// lib/features/simulator/ai_strategy/services/templates/rsi_mean_reversion_template.dart
import 'package:flutter/material.dart';
import '../../models/strategy_template.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import '../../models/template_parameter.dart';
import '../../../../subscriptions/models/subscription_tier.dart';

class RSIMeanReversionTemplate extends StrategyTemplate {
  @override
  String get id => 'rsi_mean_reversion';

  @override
  String get name => 'RSI Mean Reversion';

  @override
  String get description =>
      'Buy when RSI indicates oversold conditions, sell when overbought. '
      'Best for ranging markets.';

  @override
  String get category => 'Mean Reversion';

  @override
  IconData get icon => Icons.show_chart;

  @override
  SubscriptionTier get requiredTier => SubscriptionTier.free;

  @override
  List<TemplateParameter> get parameters => [
        NumericParameter(
          id: 'rsi_period',
          label: 'RSI Period',
          description: 'Number of candles for RSI calculation (14 is standard)',
          defaultValue: 14,
          min: 7,
          max: 21,
        ),
        NumericParameter(
          id: 'oversold_threshold',
          label: 'Oversold Level',
          description: 'Buy when RSI drops below this level',
          defaultValue: 30,
          min: 20,
          max: 35,
        ),
        NumericParameter(
          id: 'overbought_threshold',
          label: 'Overbought Level',
          description: 'Sell when RSI rises above this level',
          defaultValue: 70,
          min: 65,
          max: 80,
        ),
        NumericParameter(
          id: 'stop_loss_pct',
          label: 'Stop Loss %',
          description: 'Exit if price drops this % below entry',
          defaultValue: 3.0,
          min: 1.0,
          max: 10.0,
          decimals: 1,
        ),
        NumericParameter(
          id: 'take_profit_pct',
          label: 'Take Profit %',
          description: 'Exit if price rises this % above entry',
          defaultValue: 6.0,
          min: 2.0,
          max: 20.0,
          decimals: 1,
        ),
      ];

  @override
  GeneratedStrategy instantiate(Map<String, dynamic> values) {
    final rsiPeriod = values['rsi_period'] ?? 14;
    final oversold = values['oversold_threshold'] ?? 30;
    final overbought = values['overbought_threshold'] ?? 70;
    final stopLoss = values['stop_loss_pct'] ?? 3.0;
    final takeProfit = values['take_profit_pct'] ?? 6.0;

    return GeneratedStrategy(
      templateId: id,
      name: values['name'] ?? 'My $name Strategy',
      description: description,
      symbol: values['symbol'] ?? 'BTCUSDT',
      timeframe: values['timeframe'] ?? '1h',
      entryConditions: [
        StrategyCondition(
          indicator: 'RSI',
          comparator: '<',
          value: (oversold as num).toDouble(),
          params: {'period': rsiPeriod},
        ),
      ],
      exitConditions: [
        StrategyCondition(
          indicator: 'RSI',
          comparator: '>',
          value: (overbought as num).toDouble(),
          params: {'period': rsiPeriod},
        ),
      ],
      riskParams: RiskParameters(
        stopLossPercent: (stopLoss as num).toDouble(),
        takeProfitPercent: (takeProfit as num).toDouble(),
        positionSizePercent: 2.0,
      ),
      parameters: {
        'rsi_period': rsiPeriod,
        'oversold_threshold': oversold,
        'overbought_threshold': overbought,
        'stop_loss_pct': stopLoss,
        'take_profit_pct': takeProfit,
      },
      educationalExplanation:
          'RSI Mean Reversion identifies overextended prices that are likely to pull back to the mean.',
      confidenceScore: 0.7,
    );
  }
}
