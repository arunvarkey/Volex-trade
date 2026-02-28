import 'package:volex_terminal/domain/order.dart'; // For OrderSide

class TradeSignal {
  final DateTime timestamp;
  final double price;
  final OrderSide side; // Buy/Sell
  final String strategyName;
  final String? description;

  TradeSignal({
    required this.timestamp,
    required this.price,
    required this.side,
    required this.strategyName,
    this.description,
  });
}
