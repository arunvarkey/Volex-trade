import 'order.dart';
import '../core/financial_math.dart';

class Position {
  final String id;
  final String symbol;
  final OrderSide side;
  double quantity;
  double entryPrice;
  final DateTime openedAt;
  bool isOpen;
  DateTime? closedAt;
  double? realizedPnL;
  double? unrealizedPnl;
  double? stopLoss;
  double? takeProfit;
  String? strategyId;

  Position({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.entryPrice,
    required this.openedAt,
    this.isOpen = true,
    this.unrealizedPnl,
    this.stopLoss,
    this.takeProfit,
    this.strategyId,
  });

  factory Position.empty() {
    return Position(
      id: '',
      symbol: '',
      side: OrderSide.buy,
      quantity: 0,
      entryPrice: 0,
      openedAt: DateTime.now(),
      isOpen: false,
    );
  }

  void close(double exitPrice) {
    isOpen = false;
    closedAt = DateTime.now();

    final pnlCents = FinancialMath.calculatePnL(
      quantity: quantity,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      isLong: side == OrderSide.buy,
    );
    realizedPnL = FinancialMath.centsToDollars(pnlCents);
  }

  void addToPosition(double qty, double price) {
    final totalCost = (quantity * entryPrice) + (qty * price);
    quantity += qty;
    entryPrice = totalCost / quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side.index,
      'quantity': quantity,
      'entryPrice': entryPrice,
      'openedAt': openedAt.toIso8601String(),
      'isOpen': isOpen,
      'closedAt': closedAt?.toIso8601String(),
      'realizedPnL': realizedPnL,
      'unrealizedPnl': unrealizedPnl,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'strategyId': strategyId,
    };
  }

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'],
      symbol: json['symbol'],
      side: OrderSide.values[json['side']],
      // Read numbers as num before narrowing: JSON gives back an int for a
      // whole number, and assigning that straight to a double field throws.
      // This runs on the boot path now that positions are restored, so it
      // must not be able to take the app down.
      quantity: (json['quantity'] as num).toDouble(),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      openedAt: DateTime.parse(json['openedAt']),
      isOpen: json['isOpen'] ?? true,
    )
      ..closedAt =
          json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null
      // toJson writes 'realizedPnL' with a capital L; this read the lowercase
      // spelling, so a position's realized P&L came back null on every
      // round-trip. Nothing persisted positions until now, which is the only
      // reason it never showed up.
      ..realizedPnL = (json['realizedPnL'] as num?)?.toDouble()
      ..unrealizedPnl = (json['unrealizedPnl'] as num?)?.toDouble()
      ..stopLoss = (json['stopLoss'] as num?)?.toDouble()
      ..takeProfit = (json['takeProfit'] as num?)?.toDouble()
      ..strategyId = json['strategyId'];
  }
}
