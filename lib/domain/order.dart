import 'package:equatable/equatable.dart';

/// Compatibility layer for Legacy Support
enum OrderSide { buy, sell }

/// Order Types
enum OrderType {
  market,
  limit,
  stopLoss,
  takeProfit,
  zoneTriggered,
}

/// Order Status
enum OrderStatus {
  pending,
  open,
  filled,
  cancelled,
  rejected, // Added for Binance mapping
  failed,
  partiallyFilled,
  closed,
}

/// Order Direction (Side)
/// We include long/short for legacy compatibility
enum OrderDirection {
  buy,
  sell,
  long,
  short,
}

/// Order Model
class Order extends Equatable {
  final String id;
  final String symbol;
  final OrderType type;
  final OrderSide side;
  final double quantity;
  final double price;
  final OrderStatus status;
  final DateTime timestamp;

  // Optional / Execution fields
  final String? strategyId;
  final String? exchangeOrderId;
  final double? filledQuantity;
  final double? filledPrice;
  final DateTime? filledAt;
  final String? failureReason;
  final double? stopPrice;
  final double? takeProfitPrice;
  final double? stopLossPrice;

  // P&L & Metadata fields
  final double? _entryPrice;
  final double? exitPrice;
  final double? realizedPnl;
  final double? unrealizedPnl;
  final DateTime? closedAt;
  final String? sourceZoneId;
  final String? regimeTag;
  final bool isLive;

  Order({
    required this.id,
    this.symbol = 'BTCUSDT',
    required this.type,
    OrderSide? side,
    required this.quantity,
    required this.price,
    this.status = OrderStatus.pending,
    DateTime? timestamp,
    this.strategyId,
    this.exchangeOrderId,
    this.filledQuantity,
    this.filledPrice,
    this.filledAt,
    this.failureReason,
    this.stopPrice,
    this.takeProfitPrice,
    this.stopLossPrice,
    double? entryPrice,
    this.exitPrice,
    this.realizedPnl,
    this.unrealizedPnl,
    this.closedAt,
    this.sourceZoneId,
    this.regimeTag,
    this.isLive = false,
    OrderDirection? direction, // Legacy support
  })  : _entryPrice = entryPrice,
        side = side ??
            (direction == OrderDirection.short
                ? OrderSide.sell
                : OrderSide.buy),
        timestamp = timestamp ?? DateTime.now();

  // Compatibility Getters
  double get entryPrice => _entryPrice ?? price;
  OrderDirection get direction =>
      side == OrderSide.buy ? OrderDirection.long : OrderDirection.short;

  bool get isOpen =>
      status == OrderStatus.open || status == OrderStatus.pending;
  bool get isFilled => status == OrderStatus.filled;
  bool get isCompleted =>
      status == OrderStatus.filled || status == OrderStatus.closed;
  bool get isBuy => side == OrderSide.buy;
  bool get isSell => side == OrderSide.sell;

  Order copyWith({
    String? id,
    String? symbol,
    OrderType? type,
    OrderSide? side,
    double? quantity,
    double? price,
    OrderStatus? status,
    DateTime? timestamp,
    String? strategyId,
    String? exchangeOrderId,
    double? filledQuantity,
    double? filledPrice,
    DateTime? filledAt,
    String? failureReason,
    double? stopPrice,
    double? takeProfitPrice,
    double? stopLossPrice,
    double? entryPrice,
    double? exitPrice,
    double? realizedPnl,
    double? unrealizedPnl,
    DateTime? closedAt,
    String? sourceZoneId,
    String? regimeTag,
    bool? isLive,
  }) {
    return Order(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      side: side ?? this.side,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      strategyId: strategyId ?? this.strategyId,
      exchangeOrderId: exchangeOrderId ?? this.exchangeOrderId,
      filledQuantity: filledQuantity ?? this.filledQuantity,
      filledPrice: filledPrice ?? this.filledPrice,
      filledAt: filledAt ?? this.filledAt,
      failureReason: failureReason ?? this.failureReason,
      stopPrice: stopPrice ?? this.stopPrice,
      takeProfitPrice: takeProfitPrice ?? this.takeProfitPrice,
      stopLossPrice: stopLossPrice ?? this.stopLossPrice,
      entryPrice: entryPrice ?? _entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
      closedAt: closedAt ?? this.closedAt,
      sourceZoneId: sourceZoneId ?? this.sourceZoneId,
      regimeTag: regimeTag ?? this.regimeTag,
      isLive: isLive ?? this.isLive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.name,
      'side': side.name,
      'quantity': quantity,
      'price': price,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'strategyId': strategyId,
      'exchangeOrderId': exchangeOrderId,
      'filledQuantity': filledQuantity,
      'filledPrice': filledPrice,
      'filledAt': filledAt?.toIso8601String(),
      'failureReason': failureReason,
      'stopPrice': stopPrice,
      'takeProfitPrice': takeProfitPrice,
      'stopLossPrice': stopLossPrice,
      'entryPrice': _entryPrice,
      'exitPrice': exitPrice,
      'realizedPnl': realizedPnl,
      'unrealizedPnl': unrealizedPnl,
      'closedAt': closedAt?.toIso8601String(),
      'sourceZoneId': sourceZoneId,
      'regimeTag': regimeTag,
      'isLive': isLive,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      symbol: json['symbol'],
      type: OrderType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => OrderType.market),
      side: OrderSide.values.firstWhere((e) => e.name == json['side'],
          orElse: () => OrderSide.buy),
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      status: OrderStatus.values.firstWhere((e) => e.name == json['status'],
          orElse: () => OrderStatus.pending),
      timestamp: DateTime.parse(json['timestamp']),
      strategyId: json['strategyId'],
      exchangeOrderId: json['exchangeOrderId'],
      filledQuantity: (json['filledQuantity'] as num?)?.toDouble(),
      filledPrice: (json['filledPrice'] as num?)?.toDouble(),
      filledAt:
          json['filledAt'] != null ? DateTime.parse(json['filledAt']) : null,
      failureReason: json['failureReason'],
      stopPrice: (json['stopPrice'] as num?)?.toDouble(),
      takeProfitPrice: (json['takeProfitPrice'] as num?)?.toDouble(),
      stopLossPrice: (json['stopLossPrice'] as num?)?.toDouble(),
      entryPrice: (json['entryPrice'] as num?)?.toDouble(),
      exitPrice: (json['exitPrice'] as num?)?.toDouble(),
      realizedPnl: (json['realizedPnl'] as num?)?.toDouble(),
      unrealizedPnl: (json['unrealizedPnl'] as num?)?.toDouble(),
      closedAt:
          json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      sourceZoneId: json['sourceZoneId'],
      regimeTag: json['regimeTag'],
      isLive: json['isLive'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        symbol,
        type,
        side,
        quantity,
        price,
        status,
        timestamp,
        strategyId,
        exchangeOrderId,
        filledQuantity,
        filledPrice,
        filledAt,
        failureReason,
        stopPrice,
        takeProfitPrice,
        stopLossPrice,
        _entryPrice,
        exitPrice,
        realizedPnl,
        unrealizedPnl,
        closedAt,
        sourceZoneId,
        regimeTag,
        isLive,
      ];
}
