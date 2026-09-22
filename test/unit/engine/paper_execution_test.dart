import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import '../../test_helper.dart';

/// Closing is asynchronous — the paper exchange takes 100-300ms — but the
/// position stays open until the offsetting order returns. Anything that
/// re-checks inside that window sees an open position and asks again, and two
/// offsetting orders do not close a position twice: the second opens an equal
/// position the other way round, leaving the user holding the opposite trade.
///
/// Protective exits run on every price update and prices arrive from two
/// sources, so this race is reachable without anyone touching the screen. A
/// double-tap on Close is the same thing by hand.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExecutionManager manager;

  setUp(() async {
    // Placing a trade awards XP, which persists through SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
    manager = ExecutionManager();
  });

  Future<void> openLong() => manager.placeMarketOrder(
        symbol: 'BTCUSDT',
        side: OrderSide.buy,
        quantity: 1.0,
        currentPrice: 50000.0,
      );

  test('a market order opens a position at the price it was given', () async {
    await openLong();

    expect(manager.openPositions.length, 1);

    // The fill is allowed to differ from the mark — the simulator applies
    // slippage — but it must be somewhere near it. It used to come back as
    // 0.0, because the price never reached the exchange at all.
    final entry = manager.openPositions.single.entryPrice;
    expect(entry, greaterThan(49000));
    expect(entry, lessThan(51000));
  });

  test('closing twice at once closes once', () async {
    await openLong();
    final id = manager.openPositions.single.id;

    // Both calls are issued before either completes — the real race.
    await Future.wait([
      manager.closeOrder(id, 50500.0),
      manager.closeOrder(id, 50500.0),
    ]);

    expect(manager.openPositions, isEmpty,
        reason: 'the second close would have opened an opposite position');
    expect(manager.orders.length, 2,
        reason: 'one order to open, one to close — not two closes');
  });

  test('closing an already-closed position is a no-op', () async {
    await openLong();
    final id = manager.openPositions.single.id;

    await manager.closeOrder(id, 50500.0);
    expect(manager.openPositions, isEmpty);

    // Late protective-exit check arriving after a manual close.
    await manager.closeOrder(id, 50500.0);

    expect(manager.openPositions, isEmpty);
    expect(manager.orders.length, 2);
  });

  group('short positions', () {
    // The paper exchange kept a spot ledger with a 'BTC' balance starting at
    // zero and refused any sell it could not cover, so opening a short threw
    // "Insufficient virtual BTC" every time — in an app that teaches shorting
    // and emits sell signals. ExecutionManager is the ledger; the exchange
    // only models latency and slippage.
    Future<void> openShort() => manager.placeMarketOrder(
          symbol: 'BTCUSDT',
          side: OrderSide.sell,
          quantity: 1.0,
          currentPrice: 50000.0,
        );

    test('a short can be opened without holding the asset', () async {
      await openShort();

      expect(manager.openPositions.length, 1);
      expect(manager.openPositions.single.side, OrderSide.sell);
    });

    test('a short can be closed again', () async {
      await openShort();
      final id = manager.openPositions.single.id;

      await manager.closeOrder(id, 49500.0);

      expect(manager.openPositions, isEmpty);
    });

    test('a profitable short is credited, not debited', () async {
      // Short at 50000, cover lower: that is a gain. Getting the sign wrong
      // here would teach the direction backwards.
      final before = manager.balance;
      await openShort();
      await manager.closeOrder(manager.openPositions.single.id, 45000.0);

      expect(manager.balance, greaterThan(before));
    });

    test('a losing short is debited', () async {
      final before = manager.balance;
      await openShort();
      await manager.closeOrder(manager.openPositions.single.id, 55000.0);

      expect(manager.balance, lessThan(before));
    });
  });

  test('the guard is released, so a position can be closed after a retry',
      () async {
    await openLong();
    final id = manager.openPositions.single.id;

    await manager.closeOrder(id, 50500.0);
    expect(manager.openPositions, isEmpty);

    // A fresh position with a new id closes normally — the guard is keyed per
    // position and was not left latched by the previous close.
    await openLong();
    final second = manager.openPositions.single.id;
    expect(second, isNot(id));

    await manager.closeOrder(second, 50500.0);
    expect(manager.openPositions, isEmpty);
  });
}
