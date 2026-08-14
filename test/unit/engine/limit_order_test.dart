import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
import '../../test_helper.dart';

void main() {
  late ExecutionManager manager;

  setUp(() {
    setupServiceLocator();
    manager = ExecutionManager();
  });

  group('Limit Order Execution (Task 38)', () {
    test('Limit order should NOT fill immediately when price is far from limit',
        () async {
      final result = await manager.placeLimitOrder(
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        quantity: 1.0,
        limitPrice: 90000.0,
      );

      expect(result.success, true);
      expect(result.order!.status, OrderStatus.open);
      expect(manager.orders.length, 1);

      // Update price to 95000 (still above 90000 buy limit)
      manager.updateUnrealizedPnl(95000.0);
      expect(manager.orders.first.status, OrderStatus.open);
    });

    test('Buy limit order should fill when price falls to limit', () async {
      await manager.placeLimitOrder(
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        quantity: 1.0,
        limitPrice: 90000.0,
      );

      // Price drops to 89000
      manager.updateUnrealizedPnl(89000.0);

      expect(manager.orders.first.status, OrderStatus.filled);
      expect(manager.orders.first.filledPrice, 89000.0);
      expect(manager.positions.length, 1);
    });

    test('Sell limit order should fill when price rises to limit', () async {
      await manager.placeLimitOrder(
        symbol: 'BTCUSDT',
        side: OrderSide.sell,
        quantity: 1.0,
        limitPrice: 100000.0,
      );

      // Price drops initially
      manager.updateUnrealizedPnl(95000.0);
      expect(manager.orders.first.status, OrderStatus.open);

      // Price rises to 101000
      manager.updateUnrealizedPnl(101000.0);

      expect(manager.orders.first.status, OrderStatus.filled);
      expect(manager.orders.first.filledPrice, 101000.0);
    });
  });

  group('Current Price Requirement (Task 39)', () {
    test('placeMarketOrder should throw when currentPrice is null', () {
      expect(
        () => manager.placeMarketOrder(
          symbol: 'BTCUSDT',
          side: OrderSide.buy,
          quantity: 1.0,
          currentPrice: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
