import 'package:uuid/uuid.dart';

enum AlertType {
  crossesAbove,
  crossesBelow,
}

class PriceAlert {
  final String id;
  final String symbol;
  final double targetPrice;
  final AlertType type;
  bool isActive;
  final DateTime createdAt;
  DateTime? triggeredAt;

  PriceAlert({
    String? id,
    required this.symbol,
    required this.targetPrice,
    required this.type,
    this.isActive = true,
    DateTime? createdAt,
    this.triggeredAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool check(double currentPrice) {
    if (!isActive) return false;

    if (type == AlertType.crossesAbove && currentPrice >= targetPrice) {
      triggeredAt = DateTime.now();
      isActive = false; // One-time alert for now
      return true;
    }

    if (type == AlertType.crossesBelow && currentPrice <= targetPrice) {
      triggeredAt = DateTime.now();
      isActive = false;
      return true;
    }

    return false;
  }
}
