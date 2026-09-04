import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

/// Every market paper trade used to open at an entry price of zero.
///
/// placeMarketOrder validated against the price the user saw, then called the
/// exchange without passing it. PaperExchangeClient prices its fill from
/// `_lastPrice`, and the one method that sets that value — updatePrice() —
/// was never called from anywhere, so it sat at 0.0 for the life of the
/// process. The fill came back at 0, the position opened at 0, and unrealized
/// P&L became (mark price - 0) x quantity: the whole notional shown as pure
/// profit on every single trade.
///
/// The root cause is fixed by handing the simulator the price. This guards the
/// backstop, so a fill price that is not a real price can never again become a
/// position's entry.
void main() {
  test('a genuine fill price is used as-is', () {
    expect(
      ExecutionManager.resolveFillPrice(reported: 50123.45, validated: 50000),
      50123.45,
    );
  });

  test('slippage away from the validated price is preserved, not overridden', () {
    // The simulator deliberately fills slightly adverse to the mark. That is a
    // real fill and must survive — this guard is for absent prices, not for
    // prices it merely disagrees with.
    expect(
      ExecutionManager.resolveFillPrice(reported: 50050, validated: 50000),
      50050,
    );
    expect(
      ExecutionManager.resolveFillPrice(reported: 49950, validated: 50000),
      49950,
    );
  });

  test('a zero fill falls back to the validated price', () {
    // This is the exact bug: _lastPrice never set, so the fill came back at 0.
    expect(
      ExecutionManager.resolveFillPrice(reported: 0, validated: 50000),
      50000,
    );
  });

  test('a negative fill falls back rather than inverting the position', () {
    expect(
      ExecutionManager.resolveFillPrice(reported: -1, validated: 50000),
      50000,
    );
  });

  test('non-finite fills fall back instead of poisoning every later sum', () {
    // A NaN entry price makes every P&L total that touches the position NaN,
    // and nothing downstream recovers from that.
    expect(
      ExecutionManager.resolveFillPrice(reported: double.nan, validated: 50000),
      50000,
    );
    expect(
      ExecutionManager.resolveFillPrice(
          reported: double.infinity, validated: 50000),
      50000,
    );
  });

  test('the result is always a usable price', () {
    for (final reported in [0.0, -5.0, double.nan, double.infinity, 42.0]) {
      final price =
          ExecutionManager.resolveFillPrice(reported: reported, validated: 100);
      expect(price, greaterThan(0));
      expect(price.isFinite, isTrue);
    }
  });
}
