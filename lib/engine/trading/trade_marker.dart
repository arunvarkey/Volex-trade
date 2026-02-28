// Represents a historical trade execution for visualization
class TradeMarker {
  final DateTime timestamp;
  final double price;
  final bool isBuy; // true = Buy, false = Sell
  final String? label; // e.g. "Bot #1"

  const TradeMarker({
    required this.timestamp,
    required this.price,
    required this.isBuy,
    this.label,
  });
}
