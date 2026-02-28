import 'dart:collection';
import 'package:volex_terminal/domain/order.dart';

/// Advanced Simulator for Backtesting
/// Models Slippage, Fees, and Latency.
class ExecutionSimulator {
  final double slippagePercent; // e.g. 0.001 (0.1%)
  final double feeRate; // e.g. 0.00075 (0.075%)
  final int latencyMs; // e.g. 200ms

  // State
  final List<Order> _closedOrders = [];
  final List<Order> _pendingOrders = []; // Filled but waiting for latency

  // Latency Queue: Orders that are "in flight" to the exchange
  final Queue<_PendingAction> _latencyQueue = Queue();

  double realizedPnl = 0.0;
  double totalFeesPaid = 0.0;

  ExecutionSimulator({
    this.slippagePercent = 0.0,
    this.feeRate = 0.0,
    this.latencyMs = 0,
  });

  List<Order> get orders => [..._closedOrders, ..._pendingOrders];

  // Called by Runner on every candle tick to process delayed actions
  void tick(DateTime currentTime, double currentPrice) {
    while (_latencyQueue.isNotEmpty &&
        _latencyQueue.first.executeAt.isBefore(currentTime)) {
      final action = _latencyQueue.removeFirst();
      _executeAction(action, currentPrice);
    }
  }

  void placeOrder(Order order) {
    // Schedule Fill
    final executeAt = order.timestamp.add(Duration(milliseconds: latencyMs));

    if (latencyMs == 0) {
      _executeAction(
        _PendingAction(
          type: _ActionType.place,
          order: order,
          executeAt: order.timestamp,
        ),
        order.price,
      );
      return;
    }

    _latencyQueue.add(_PendingAction(
      type: _ActionType.place,
      order: order,
      executeAt: executeAt,
    ));
  }

  void cancelOrder(String orderId) {
    _pendingOrders.removeWhere((o) => o.id == orderId);
  }

  void _executeAction(_PendingAction action, double currentPrice) {
    if (action.type == _ActionType.place) {
      _fillOrder(action.order, currentPrice);
    }
  }

  void _fillOrder(Order order, double marketPrice) {
    // 2. Slippage Calculation
    double executionPrice = marketPrice;
    if (order.direction == OrderDirection.long) {
      executionPrice = marketPrice * (1 + slippagePercent);
    } else {
      executionPrice = marketPrice * (1 - slippagePercent);
    }

    // 3. Fee
    double tradeValue = executionPrice * order.quantity;
    double fee = tradeValue * feeRate;
    totalFeesPaid += fee;

    // 4. Fill
    final filledOrder = order.copyWith(
      status: OrderStatus.filled,
      entryPrice: executionPrice,
      isLive: false,
    );

    _pendingOrders.add(filledOrder);
  }

  void closeAllOrders([double? currentPrice]) {
    final price = currentPrice ?? 0.0;
    // Flush pending
    final toClose = [..._pendingOrders];
    _pendingOrders.clear();
    for (var order in toClose) {
      _closeOrderInstance(order, price, DateTime.now());
    }
  }

  void closeOrder(String orderId, [double? currentPrice]) {
    final index = _pendingOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _closeOrderInstance(
          _pendingOrders[index], currentPrice ?? 0.0, DateTime.now());
      _pendingOrders.removeAt(index);
    }
  }

  void inject(Order order) {
    _pendingOrders.add(order);
  }

  void closeAt(double price, DateTime time) {
    _latencyQueue.clear();

    // Close filled
    // Iterate copy/reversed to avoid index issues if we clear list
    final toClose = [..._pendingOrders];
    _pendingOrders.clear(); // We move 'em to closed

    for (var order in toClose) {
      _closeOrderInstance(order, price, time);
    }
  }

  // Re-impl to take specific order instance
  void _closeOrderInstance(Order order, double exitPriceRaw, DateTime time) {
    // Slippage on Exit
    double exitPrice = exitPriceRaw;
    if (order.direction == OrderDirection.long) {
      exitPrice = exitPriceRaw * (1 - slippagePercent);
    } else {
      exitPrice = exitPriceRaw * (1 + slippagePercent);
    }

    // Fees on Exit
    double tradeValue = exitPrice * order.quantity;
    double fee = tradeValue * feeRate;
    totalFeesPaid += fee;

    // PnL (Gross)
    final grossPnl = (order.direction == OrderDirection.long
            ? exitPrice - order.entryPrice
            : order.entryPrice - exitPrice) *
        order.quantity;

    final closedOrder = order.copyWith(
      exitPrice: exitPrice,
      realizedPnl: grossPnl,
      status: OrderStatus.closed,
      closedAt: time,
    );

    _closedOrders.add(closedOrder);
    realizedPnl += grossPnl;
  }

  double get netResult => realizedPnl - totalFeesPaid;
}

enum _ActionType { place }

class _PendingAction {
  final _ActionType type;
  final Order order;
  final DateTime executeAt;

  _PendingAction(
      {required this.type, required this.order, required this.executeAt});
}
