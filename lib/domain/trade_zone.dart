enum ZoneDirection { long, short }

class TradeZone {
  final double minPrice;
  final double maxPrice;
  final int startIndex;
  final int endIndex;
  final String symbol;
  final ZoneDirection direction;

  bool isTriggered;

  final String id;
  // Visual feedback
  bool isFlashing = false;

  TradeZone({
    required this.id,
    required this.minPrice,
    required this.maxPrice,
    required this.startIndex,
    required this.endIndex,
    required this.symbol,
    required this.direction,
    this.isTriggered = false,
  });

  // Helper to check intersect
  bool contains(double price, int index) {
    if (price < minPrice || price > maxPrice) return false;
    if (index < startIndex || index > endIndex) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'symbol': symbol,
      'direction': direction.index,
      'isTriggered': isTriggered,
    };
  }

  factory TradeZone.fromJson(Map<String, dynamic> json) {
    return TradeZone(
      id: json['id'] ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(), // Fallback if missing
      minPrice: (json['minPrice'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      startIndex: json['startIndex'],
      endIndex: json['endIndex'],
      symbol: json['symbol'] ?? 'BTCUSDT',
      direction: ZoneDirection.values[json['direction'] ?? 0],
      isTriggered: json['isTriggered'] ?? false,
    );
  }
}
