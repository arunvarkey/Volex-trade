import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/simulator/backtest/metrics_calculator.dart';
import 'package:volex_terminal/features/simulator/backtest/models/trade_marker.dart';

/// Locks in the risk-adjusted metrics a financial analyst relies on. These are
/// pure functions of the equity curve, so they're cheap and deterministic to
/// test — and easy to break silently, which is exactly why they're guarded.
void main() {
  // At least one closed trade so the calculator doesn't early-return zeros.
  final trades = <TradeMarker>[
    TradeMarker(
        timestamp: DateTime(2024, 1, 1), price: 100, type: TradeType.entry),
    TradeMarker(
        timestamp: DateTime(2024, 1, 2),
        price: 110,
        type: TradeType.exit,
        pnl: 10,
        pnlPercent: 10),
  ];

  // A net-rising curve with a couple of mild dips (so drawdown > 0).
  final risingCurve = <double>[10000, 10100, 10050, 10200, 10150, 10400];

  test('Sharpe is annualized by periodsPerYear (timeframe-aware)', () {
    final daily = MetricsCalculator.calculate(
      trades: trades,
      equityCurve: risingCurve,
      initialEquity: 10000,
      periodsPerYear: 252,
    );
    final hourly = MetricsCalculator.calculate(
      trades: trades,
      equityCurve: risingCurve,
      initialEquity: 10000,
      periodsPerYear: 8760,
    );

    expect(daily.sharpeRatio.isFinite, isTrue);
    expect(hourly.sharpeRatio.isFinite, isTrue);
    // Same returns, larger bars-per-year → larger annualized |Sharpe|.
    expect(hourly.sharpeRatio.abs(), greaterThan(daily.sharpeRatio.abs()));
  });

  test('Sortino and Calmar are finite and positive on a profitable curve', () {
    final m = MetricsCalculator.calculate(
      trades: trades,
      equityCurve: risingCurve,
      initialEquity: 10000,
      periodsPerYear: 8760,
    );

    expect(m.sharpeRatio, greaterThan(0));
    expect(m.sortinoRatio.isFinite, isTrue);
    expect(m.sortinoRatio, greaterThan(0));
    expect(m.calmarRatio.isFinite, isTrue);
    expect(m.calmarRatio, greaterThan(0)); // positive CAGR / positive drawdown
    expect(m.maxDrawdownPercent, greaterThan(0)); // the curve had dips
  });

  test('flat equity yields zero ratios with no divide-by-zero', () {
    const flat = <double>[10000, 10000, 10000, 10000];
    final m = MetricsCalculator.calculate(
      trades: trades,
      equityCurve: flat,
      initialEquity: 10000,
      periodsPerYear: 8760,
    );

    expect(m.sharpeRatio, 0);
    expect(m.sortinoRatio, 0);
    expect(m.calmarRatio, 0); // no drawdown → guarded to 0
    expect(m.maxDrawdownPercent, 0);
  });
}
