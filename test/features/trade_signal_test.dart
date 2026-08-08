import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/features/signals/models/trade_signal.dart';
import 'package:volex_terminal/domain/order.dart';

TradeSignal _make({bool actionable = true}) => TradeSignal(
      id: 's1',
      symbol: 'BTCUSDT',
      side: OrderSide.buy,
      entryPrice: 100,
      stopLoss: 98,
      takeProfit: 105,
      reasoning: 'reason',
      confidence: 80,
      strategyName: 'RSI',
      timestamp: DateTime(2024, 1, 1),
      expiresAt: DateTime(2024, 1, 1, 0, 5),
      isActionable: actionable,
    );

void main() {
  test('isActionable defaults to true', () {
    final s = TradeSignal(
      id: 's',
      symbol: 'BTCUSDT',
      side: OrderSide.sell,
      entryPrice: 1,
      stopLoss: 1,
      takeProfit: 1,
      reasoning: 'r',
      confidence: 1,
      strategyName: 'x',
      timestamp: DateTime(2024),
      expiresAt: DateTime(2024, 1, 2),
    );
    expect(s.isActionable, isTrue);
  });

  test('isActionable survives a JSON round-trip', () {
    final restored = TradeSignal.fromJson(_make(actionable: false).toJson());
    expect(restored.isActionable, isFalse);
    expect(restored.symbol, 'BTCUSDT');
    expect(restored.side, OrderSide.buy);
  });

  test('legacy JSON without is_actionable defaults to actionable', () {
    final json = _make(actionable: false).toJson()..remove('is_actionable');
    final restored = TradeSignal.fromJson(json);
    expect(restored.isActionable, isTrue);
  });
}
