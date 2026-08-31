import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/persistence/persistence_service.dart';

import '../../test_helper.dart';

/// The whole trade, end to end, checked against the money.
///
/// The other engine tests each pin one behaviour: that a fill gets a sane
/// price, that a short can open, that a fee is a percentage of notional, that
/// a position serialises. All of them can pass while the balance still ends up
/// wrong, because none of them follows a single trade from open to close and
/// asks whether the account moved by exactly the right amount. Every engine
/// bug fixed on this branch was of that shape — a value computed correctly in
/// one layer and dropped crossing into the next.
///
/// The invariant these tests hold to is:
///
///     final balance = starting balance − open fee − close fee + realized P&L
///
/// Expectations are derived from the *actual* fill prices rather than the mark
/// price passed in, because the paper exchange applies slippage. Asserting
/// against the mark would either be wrong or would force the test to encode
/// the slippage model, and then it would be testing its own copy of the maths
/// instead of the engine's.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const startingBalance = 100000.0;
  const symbol = 'BTCUSDT';

  late ExecutionManager manager;

  setUp(() async {
    // Placing a trade awards XP, which writes through SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
    manager = ExecutionManager();
  });

  /// The fill price the exchange actually gave, for the one order on [side].
  double fillOn(OrderSide side) {
    final order = manager.orders.firstWhere((o) => o.side == side);
    final fill = order.filledPrice ?? order.price;
    expect(fill, greaterThan(0),
        reason: 'a filled order with no price is the bug that opened '
            'positions at 0.00');
    return fill;
  }

  /// What the balance should be, computed from what actually happened.
  double expectedBalance({
    required OrderSide openSide,
    required OrderSide closeSide,
    required double quantity,
  }) {
    final openFee = ExecutionManager.feeFor(quantity, fillOn(openSide));
    final closeFee = ExecutionManager.feeFor(quantity, fillOn(closeSide));
    final realized = manager.positions
        .where((p) => !p.isOpen)
        .fold<double>(0.0, (sum, p) => sum + (p.realizedPnL ?? 0.0));
    return startingBalance - openFee - closeFee + realized;
  }

  group('a long round trip', () {
    test('leaves the balance exactly where the fills say it should', () async {
      await manager.placeMarketOrder(
        symbol: symbol,
        side: OrderSide.buy,
        quantity: 0.5,
        currentPrice: 50000.0,
      );
      expect(manager.openPositions, hasLength(1));

      await manager.closeOrder(manager.openPositions.single.id, 52000.0);
      expect(manager.openPositions, isEmpty);

      expect(
        manager.balance,
        closeTo(
          expectedBalance(
            openSide: OrderSide.buy,
            closeSide: OrderSide.sell,
            quantity: 0.5,
          ),
          0.01,
        ),
      );
    });

    test('credits a gain when price rose', () async {
      await manager.placeMarketOrder(
        symbol: symbol,
        side: OrderSide.buy,
        quantity: 0.5,
        currentPrice: 50000.0,
      );
      await manager.closeOrder(manager.openPositions.single.id, 52000.0);

      // A 2,000 move on half a coin is about 1,000, far larger than any fee
      // or slippage, so the direction of the balance is unambiguous.
      expect(manager.balance, greaterThan(startingBalance + 500));
    });
  });

  group('a short round trip', () {
    test('leaves the balance exactly where the fills say it should', () async {
      await manager.placeMarketOrder(
        symbol: symbol,
        side: OrderSide.sell,
        quantity: 0.5,
        currentPrice: 50000.0,
      );
      expect(manager.openPositions, hasLength(1),
          reason: 'shorts were impossible before the spot ledger was removed');

      await manager.closeOrder(manager.openPositions.single.id, 48000.0);
      expect(manager.openPositions, isEmpty);

      expect(
        manager.balance,
        closeTo(
          expectedBalance(
            openSide: OrderSide.sell,
            closeSide: OrderSide.buy,
            quantity: 0.5,
          ),
          0.01,
        ),
      );
    });

    test('credits a gain when price fell', () async {
      await manager.placeMarketOrder(
        symbol: symbol,
        side: OrderSide.sell,
        quantity: 0.5,
        currentPrice: 50000.0,
      );
      await manager.closeOrder(manager.openPositions.single.id, 48000.0);

      expect(manager.balance, greaterThan(startingBalance + 500),
          reason: 'a short that closes lower must pay, not charge');
    });
  });

  test('a round trip at the same price costs only the two fees', () async {
    await manager.placeMarketOrder(
      symbol: symbol,
      side: OrderSide.buy,
      quantity: 0.2,
      currentPrice: 50000.0,
    );
    await manager.closeOrder(manager.openPositions.single.id, 50000.0);

    // Slippage means this is not exactly two fees, but it must be small and
    // it must be a cost. A flat trade that made money would mean the
    // accounting had invented some.
    final cost = startingBalance - manager.balance;
    expect(cost, greaterThan(0),
        reason: 'trading for free, or at a profit on a flat market, means '
            'fees are being dropped somewhere');
    expect(cost, lessThan(startingBalance * 0.01),
        reason: 'a flat round trip should cost fees and slippage, not 1% of '
            'the account');
  });

  test('fees are actually deducted, not just calculated', () async {
    await manager.placeMarketOrder(
      symbol: symbol,
      side: OrderSide.buy,
      quantity: 1.0,
      currentPrice: 50000.0,
    );

    // One fill has happened and nothing is closed, so the only thing that can
    // have moved the balance is the fee.
    final charged = startingBalance - manager.balance;
    expect(charged, closeTo(ExecutionManager.feeFor(1.0, fillOn(OrderSide.buy)),
        0.01));
    expect(charged, greaterThan(0));
  });

  test('the ticket\'s stop and target end up on the position', () async {
    // A stop that is accepted by the ticket and then lost on the way to the
    // position is invisible until the day it fails to fire.
    await manager.placeMarketOrder(
      symbol: symbol,
      side: OrderSide.buy,
      quantity: 0.3,
      currentPrice: 50000.0,
      stopLoss: 49000.0,
      takeProfit: 53000.0,
    );

    final position = manager.openPositions.single;
    expect(position.stopLoss, 49000.0);
    expect(position.takeProfit, 53000.0);
  });

  group('after a restart', () {
    test('the balance and the open position are still there', () async {
      SharedPreferences.setMockInitialValues({});
      await setupServiceLocator();
      final prefs = await SharedPreferences.getInstance();
      final store = PersistenceService.inject(prefs: prefs);

      final before = ExecutionManager(persistence: store);
      await before.placeMarketOrder(
        symbol: symbol,
        side: OrderSide.buy,
        quantity: 0.4,
        currentPrice: 50000.0,
      );
      // _persist writes without awaiting, so let the write land.
      await Future<void>.delayed(Duration.zero);

      final savedBalance = before.balance;
      final savedEntry = before.openPositions.single.entryPrice;

      // A second manager over the same store is what a relaunch looks like.
      final after = ExecutionManager(persistence: store);
      expect(after.openPositions, isEmpty, reason: 'nothing restored yet');

      await after.restoreState();

      expect(after.openPositions, hasLength(1),
          reason: 'an open position that vanishes on relaunch is a position '
              'the user can no longer close');
      expect(after.openPositions.single.entryPrice, closeTo(savedEntry, 0.01));
      expect(after.balance, closeTo(savedBalance, 0.01));
    });

    test('a fresh install starts at the full balance, not zero', () async {
      SharedPreferences.setMockInitialValues({});
      await setupServiceLocator();
      final prefs = await SharedPreferences.getInstance();
      final store = PersistenceService.inject(prefs: prefs);

      final fresh = ExecutionManager(persistence: store);
      await fresh.restoreState();

      expect(fresh.balance, startingBalance,
          reason: 'restoring from an empty store must leave the defaults '
              'alone rather than zeroing the account');
      expect(fresh.openPositions, isEmpty);
    });
  });
}
