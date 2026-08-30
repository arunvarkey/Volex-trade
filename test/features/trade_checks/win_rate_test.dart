import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/trade_checks/services/trade_check_service.dart';

/// The AI Guardian's warning dialog used to print "Historical win rate: 5%"
/// from a constant baked into the pattern — an invented population statistic
/// shown as fact to someone in the middle of placing a trade. It now reports
/// the user's own rate over their own trades, so what that computation counts
/// (and refuses to count) is worth pinning down.
List<Map<String, dynamic>> trades(List<double?> pnls) =>
    [for (final p in pnls) <String, dynamic>{'pnl': p}];

void main() {
  test('no history yields no rate', () {
    final r = TradeCheckService.winRateFor([]);
    expect(r.rate, isNull);
    expect(r.sample, 0);
  });

  test('too few trades yields no rate rather than a noisy one', () {
    // Four straight wins is 100%, but off four trades that number would
    // mislead more than it informs.
    final r = TradeCheckService.winRateFor(trades([10, 20, 30, 40]));
    expect(r.rate, isNull);
    expect(r.sample, 4);
  });

  test('computes the rate once there is a usable sample', () {
    final r = TradeCheckService.winRateFor(trades([10, -5, 20, -8, 30]));
    expect(r.rate, closeTo(60, 1e-9));
    expect(r.sample, 5);
  });

  test('all losses reports 0, not null', () {
    final r = TradeCheckService.winRateFor(trades([-1, -2, -3, -4, -5]));
    expect(r.rate, 0);
    expect(r.sample, 5);
  });

  test('all wins reports 100', () {
    final r = TradeCheckService.winRateFor(trades([1, 2, 3, 4, 5]));
    expect(r.rate, 100);
  });

  test('breakeven trades count as losses, not wins', () {
    // A trade that closed flat did not win. Counting it as one would inflate
    // the figure shown back to the user.
    final r = TradeCheckService.winRateFor(trades([0, 0, 0, 0, 10]));
    expect(r.rate, closeTo(20, 1e-9));
  });

  test('trades with no recorded P&L are excluded from the sample', () {
    // Open positions have no P&L yet. Treating them as losses would drag the
    // rate down for someone who has simply not closed out.
    final r = TradeCheckService.winRateFor(
        trades([10, -5, 20, -8, 30, null, null]));
    expect(r.sample, 5, reason: 'the two unsettled trades are not counted');
    expect(r.rate, closeTo(60, 1e-9));
  });

  test('the sample never exceeds what the rate was measured over', () {
    // Quoting a rate against a bigger sample than produced it would be its
    // own small dishonesty, so the two always agree.
    final r = TradeCheckService.winRateFor(
        trades([1, null, 2, null, 3, null, -1, -2]));
    expect(r.sample, 5);
    expect(r.rate, closeTo(60, 1e-9));
  });
}
