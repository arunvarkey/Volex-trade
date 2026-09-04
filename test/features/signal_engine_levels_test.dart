import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/features/signals/services/signal_engine.dart';

/// When a strategy recommendation arrives without its own stop/target, the
/// signal engine fills them in. Those fallbacks used to be a flat
/// `entry * 0.98` and `entry * 1.05` whatever the direction, which is
/// backwards for a short — the "stop" sat below entry, where a short makes
/// money, and the "target" above it, where a short loses. Since the feed is
/// teaching material, an inverted setup teaches the wrong lesson.
///
/// The rule these pin down: a stop is always on the losing side of entry and
/// a target always on the winning side, whichever way the trade points.
void main() {
  const entry = 100.0;

  group('long', () {
    test('stop sits below entry', () {
      expect(SignalEngine.fallbackStop(OrderSide.buy, entry), lessThan(entry));
    });

    test('target sits above entry', () {
      expect(
          SignalEngine.fallbackTarget(OrderSide.buy, entry), greaterThan(entry));
    });
  });

  group('short', () {
    test('stop sits above entry', () {
      expect(
          SignalEngine.fallbackStop(OrderSide.sell, entry), greaterThan(entry));
    });

    test('target sits below entry', () {
      expect(
          SignalEngine.fallbackTarget(OrderSide.sell, entry), lessThan(entry));
    });
  });

  test('reward is larger than risk in both directions', () {
    for (final side in OrderSide.values) {
      final risk = (SignalEngine.fallbackStop(side, entry) - entry).abs();
      final reward = (SignalEngine.fallbackTarget(side, entry) - entry).abs();
      expect(reward, greaterThan(risk),
          reason: 'a $side signal should not offer worse than 1:1');
    }
  });

  test('the two directions are mirror images of each other', () {
    final longRisk =
        entry - SignalEngine.fallbackStop(OrderSide.buy, entry);
    final shortRisk =
        SignalEngine.fallbackStop(OrderSide.sell, entry) - entry;
    expect(longRisk, closeTo(shortRisk, 1e-9));

    final longReward =
        SignalEngine.fallbackTarget(OrderSide.buy, entry) - entry;
    final shortReward =
        entry - SignalEngine.fallbackTarget(OrderSide.sell, entry);
    expect(longReward, closeTo(shortReward, 1e-9));
  });

  test('levels scale with the entry price', () {
    // Guards against anyone swapping the percentages for fixed dollar offsets,
    // which would be meaningless across BTC and a sub-dollar asset.
    final low = SignalEngine.fallbackStop(OrderSide.buy, 1.0);
    final high = SignalEngine.fallbackStop(OrderSide.buy, 50000.0);
    expect(1.0 - low, closeTo(0.02, 1e-9));
    expect(50000.0 - high, closeTo(1000.0, 1e-6));
  });
}
