import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

/// Paper trading used to fill for free while the backtest engine charged
/// 0.075% in fees and 0.1% in slippage. The same strategy therefore looked
/// better traded by hand than it did in its own backtest, which teaches the
/// most expensive lesson a new trader can learn wrong: that costs do not
/// matter. Free execution especially flatters churning — the overtrading the
/// app's own guardian warns about.
void main() {
  test('the simulator charges the same rate the backtest models', () {
    // If someone retunes one of these, this test should make them think about
    // the other. A divergence here is the bug, not a detail.
    expect(ExecutionManager.takerFeeRate, 0.00075);
  });

  test('fee is a straight percentage of notional', () {
    expect(ExecutionManager.feeFor(1, 10000), closeTo(7.5, 1e-9));
    expect(ExecutionManager.feeFor(0.5, 10000), closeTo(3.75, 1e-9));
    expect(ExecutionManager.feeFor(2, 10000), closeTo(15.0, 1e-9));
  });

  test('fee scales with price as well as size', () {
    expect(ExecutionManager.feeFor(1, 100), closeTo(0.075, 1e-9));
    expect(ExecutionManager.feeFor(1, 100000), closeTo(75.0, 1e-9));
  });

  test('a zero-size or zero-price fill costs nothing', () {
    expect(ExecutionManager.feeFor(0, 10000), 0);
    expect(ExecutionManager.feeFor(1, 0), 0);
    expect(ExecutionManager.feeFor(0, 0), 0);
  });

  test('never returns a negative fee, whatever the inputs', () {
    // A fee is a cost. A negative one would credit the account on every fill.
    expect(ExecutionManager.feeFor(-1, 10000), greaterThanOrEqualTo(0));
    expect(ExecutionManager.feeFor(1, -10000), greaterThanOrEqualTo(0));
    expect(ExecutionManager.feeFor(-1, -10000), greaterThanOrEqualTo(0));
  });

  test('non-finite inputs cost nothing rather than poisoning the balance', () {
    // A NaN fee subtracted from the balance would make it NaN forever.
    expect(ExecutionManager.feeFor(double.nan, 10000), 0);
    expect(ExecutionManager.feeFor(double.infinity, 10000), 0);
    expect(ExecutionManager.feeFor(1, double.infinity), 0);
  });

  test('a round trip costs twice one fill', () {
    // Entry and exit are both fills; the ticket quotes the round trip on this
    // basis, so the arithmetic behind that claim is pinned here.
    final oneWay = ExecutionManager.feeFor(1, 10000);
    expect(oneWay * 2, closeTo(15.0, 1e-9));
  });
}
