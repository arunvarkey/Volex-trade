import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/domain/price_alert.dart';

void main() {
  group('PriceAlert Logic', () {
    test('Crosses Above Trigger', () {
      final alert = PriceAlert(
        symbol: 'BTC',
        targetPrice: 50000,
        type: AlertType.crossesAbove,
      );

      // 1. Initial State
      expect(alert.isActive, isTrue);

      // 2. Below Target - Should NOT trigger
      expect(alert.check(49000), isFalse);
      expect(alert.isActive, isTrue);

      // 3. At Target - Should Trigger
      expect(alert.check(50000), isTrue);
      expect(alert.isActive, isFalse); // One-time alert is now inactive
    });

    test('Crosses Below Trigger', () {
      final alert = PriceAlert(
        symbol: 'ETH',
        targetPrice: 3000,
        type: AlertType.crossesBelow,
      );

      // 1. Above Target
      expect(alert.check(3100), isFalse);

      // 2. Crosses Below
      expect(alert.check(2999), isTrue);
      expect(alert.isActive, isFalse);
    });

    test('Inactive Alert Ignored', () {
      final alert = PriceAlert(
          symbol: 'SOL', targetPrice: 100, type: AlertType.crossesAbove);
      alert.isActive = false;

      expect(alert.check(101), isFalse);
    });
  });
}
