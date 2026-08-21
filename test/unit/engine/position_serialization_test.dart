import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/position.dart';

/// Positions are now written to storage and read back on launch, so the
/// round-trip has to be exact. It was not: toJson writes 'realizedPnL' with a
/// capital L and fromJson read the lowercase spelling, so realized P&L came
/// back null every time. Nothing persisted positions before, which is the only
/// reason that never surfaced.
void main() {
  Position openLong() => Position(
        id: 'pos-1',
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        quantity: 0.5,
        entryPrice: 50000.0,
        openedAt: DateTime.parse('2026-01-02T03:04:05.000Z'),
        isOpen: true,
      );

  test('an open position survives the round-trip', () {
    final before = openLong()
      ..stopLoss = 49000.0
      ..takeProfit = 52000.0
      ..unrealizedPnl = 125.5
      ..strategyId = 'strat-7';

    final after = Position.fromJson(before.toJson());

    expect(after.id, before.id);
    expect(after.symbol, before.symbol);
    expect(after.side, before.side);
    expect(after.quantity, before.quantity);
    expect(after.entryPrice, before.entryPrice);
    expect(after.openedAt, before.openedAt);
    expect(after.isOpen, isTrue);
    expect(after.stopLoss, 49000.0);
    expect(after.takeProfit, 52000.0);
    expect(after.unrealizedPnl, 125.5);
    expect(after.strategyId, 'strat-7');
  });

  test('protective levels survive, so a restored stop still triggers', () {
    // If these came back null the position would be restored without its
    // stop, and the exit the user set would never fire after a restart.
    final after = Position.fromJson((openLong()
          ..stopLoss = 49000.0
          ..takeProfit = 52000.0)
        .toJson());

    expect(after.stopLoss, isNotNull);
    expect(after.takeProfit, isNotNull);
  });

  test('realized P&L survives the round-trip', () {
    final before = openLong()..realizedPnL = -240.75;

    final after = Position.fromJson(before.toJson());

    expect(after.realizedPnL, -240.75,
        reason: 'the key spelling must match between toJson and fromJson');
  });

  test('a closed position stays closed', () {
    final before = openLong()
      ..isOpen = false
      ..closedAt = DateTime.parse('2026-01-03T00:00:00.000Z')
      ..realizedPnL = 310.0;

    final after = Position.fromJson(before.toJson());

    expect(after.isOpen, isFalse);
    expect(after.closedAt, before.closedAt);
    expect(after.realizedPnL, 310.0);
  });

  test('a short round-trips as a short', () {
    final before = Position(
      id: 'pos-2',
      symbol: 'ETHUSDT',
      side: OrderSide.sell,
      quantity: 2.0,
      entryPrice: 3000.0,
      openedAt: DateTime.now(),
      isOpen: true,
    );

    expect(Position.fromJson(before.toJson()).side, OrderSide.sell);
  });

  test('whole-number values decode without a type error', () {
    // JSON gives back an int for a whole number, and assigning that straight
    // to a double field throws. This runs on the boot path, so it must not be
    // able to take the app down.
    final json = {
      'id': 'pos-3',
      'symbol': 'BTCUSDT',
      'side': OrderSide.buy.index,
      'quantity': 1,
      'entryPrice': 50000,
      'openedAt': DateTime.now().toIso8601String(),
      'isOpen': true,
      'stopLoss': 49000,
      'takeProfit': 52000,
      'realizedPnL': 100,
      'unrealizedPnl': 25,
    };

    final position = Position.fromJson(json);

    expect(position.quantity, 1.0);
    expect(position.entryPrice, 50000.0);
    expect(position.stopLoss, 49000.0);
    expect(position.realizedPnL, 100.0);
  });

  test('an order round-trips with its protective levels', () {
    final before = Order(
      id: 'ord-1',
      symbol: 'BTCUSDT',
      type: OrderType.limit,
      side: OrderSide.sell,
      quantity: 0.25,
      price: 51000.0,
      status: OrderStatus.open,
      stopLossPrice: 52000.0,
      takeProfitPrice: 48000.0,
    );

    final after = Order.fromJson(before.toJson());

    expect(after.id, before.id);
    expect(after.type, OrderType.limit);
    expect(after.side, OrderSide.sell);
    expect(after.status, OrderStatus.open);
    expect(after.stopLossPrice, 52000.0);
    expect(after.takeProfitPrice, 48000.0);
  });
}
