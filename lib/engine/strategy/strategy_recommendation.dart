import 'package:volex_terminal/domain/order.dart';

class StrategyRecommendation {
  final String strategyName;
  final String symbol;
  final OrderSide side;
  final double entryPrice;
  final double? stopLoss;
  final double? takeProfit;
  final double suggestedQuantity;
  final double confidence;
  final String? reasoning;
  final bool shouldTrade;

  StrategyRecommendation({
    required this.strategyName,
    required this.symbol,
    required this.side,
    required this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    this.suggestedQuantity = 0.0,
    required this.confidence,
    this.reasoning,
    this.shouldTrade = false,
  });
}
