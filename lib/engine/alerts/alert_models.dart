import 'package:uuid/uuid.dart';

/// Alert condition type
enum AlertCondition {
  above,
  below;

  String get label {
    switch (this) {
      case AlertCondition.above:
        return 'Above';
      case AlertCondition.below:
        return 'Below';
    }
  }

  bool evaluate(double currentPrice, double targetPrice) {
    switch (this) {
      case AlertCondition.above:
        return currentPrice >= targetPrice;
      case AlertCondition.below:
        return currentPrice <= targetPrice;
    }
  }
}

/// Price alert model
class PriceAlert {
  final String id;
  final String symbol;
  final double targetPrice;
  final AlertCondition condition;
  final DateTime createdAt;
  final bool isActive;
  final bool hasTriggered;
  final String? note;
  final DateTime? triggeredAt;

  PriceAlert({
    String? id,
    required this.symbol,
    required this.targetPrice,
    required this.condition,
    DateTime? createdAt,
    this.isActive = true,
    this.hasTriggered = false,
    this.note,
    this.triggeredAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Copy with modifications
  PriceAlert copyWith({
    String? symbol,
    double? targetPrice,
    AlertCondition? condition,
    bool? isActive,
    bool? hasTriggered,
    String? note,
    DateTime? triggeredAt,
  }) {
    return PriceAlert(
      id: id,
      symbol: symbol ?? this.symbol,
      targetPrice: targetPrice ?? this.targetPrice,
      condition: condition ?? this.condition,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      hasTriggered: hasTriggered ?? this.hasTriggered,
      note: note ?? this.note,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'targetPrice': targetPrice,
      'condition': condition.name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'hasTriggered': hasTriggered,
      'note': note,
      'triggeredAt': triggeredAt?.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      targetPrice: (json['targetPrice'] as num).toDouble(),
      condition: AlertCondition.values.firstWhere(
        (c) => c.name == json['condition'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      hasTriggered: json['hasTriggered'] as bool,
      note: json['note'] as String?,
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.parse(json['triggeredAt'] as String)
          : null,
    );
  }

  /// Human-readable description
  String get description {
    final direction = condition == AlertCondition.above ? '↑' : '↓';
    return '$symbol $direction \$${targetPrice.toStringAsFixed(2)}';
  }

  /// Check if alert should still be evaluated
  bool get shouldEvaluate => isActive && !hasTriggered;

  @override
  String toString() => 'PriceAlert($description, active: $isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceAlert && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Alert trigger event (for logging/history)
class AlertTriggerEvent {
  final String alertId;
  final String symbol;
  final double targetPrice;
  final double actualPrice;
  final AlertCondition condition;
  final DateTime timestamp;

  AlertTriggerEvent({
    required this.alertId,
    required this.symbol,
    required this.targetPrice,
    required this.actualPrice,
    required this.condition,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'symbol': symbol,
      'targetPrice': targetPrice,
      'actualPrice': actualPrice,
      'condition': condition.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AlertTriggerEvent.fromJson(Map<String, dynamic> json) {
    return AlertTriggerEvent(
      alertId: json['alertId'] as String,
      symbol: json['symbol'] as String,
      targetPrice: (json['targetPrice'] as num).toDouble(),
      actualPrice: (json['actualPrice'] as num).toDouble(),
      condition: AlertCondition.values.firstWhere(
        (c) => c.name == json['condition'],
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String get message =>
      '$symbol hit ${condition.label.toLowerCase()} \$${targetPrice.toStringAsFixed(2)} '
      '(actual: \$${actualPrice.toStringAsFixed(2)})';
}
