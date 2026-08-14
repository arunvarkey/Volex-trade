import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/domain/mini_ticker.dart';
import 'package:volex_terminal/ui/widgets/market_ticker/ticker_format.dart';

void main() {
  group('formatPrice', () {
    test('magnitude-aware precision', () {
      expect(formatPrice(68895.126), '68,895.13');
      expect(formatPrice(104.5), '104.50');
      expect(formatPrice(3.14159), '3.142');
      expect(formatPrice(0.123456), '0.12346');
    });
  });

  group('baseAsset', () {
    test('strips the USDT quote', () {
      expect(baseAsset('BTCUSDT'), 'BTC');
      expect(baseAsset('AVAXUSDT'), 'AVAX');
      expect(baseAsset('EURUSD'), 'EURUSD'); // non-USDT left untouched
    });
  });

  group('formatQuoteVolume', () {
    test('compacts large volumes', () {
      expect(formatQuoteVolume(1.23e9), '\$1.2B');
      expect(formatQuoteVolume(845e6), '\$845M');
      expect(formatQuoteVolume(12500), '\$13K');
      expect(formatQuoteVolume(950), '\$950');
    });
  });

  group('MiniTicker', () {
    test('24h change math', () {
      const t = MiniTicker(
        symbol: 'BTCUSDT',
        closePrice: 110,
        openPrice: 100,
        highPrice: 115,
        lowPrice: 95,
        volume: 10,
        quoteVolume: 1000,
      );
      expect(t.changePercent, closeTo(10.0, 1e-9));
      expect(t.changeAmount, closeTo(10.0, 1e-9));
    });

    test('zero open does not divide by zero', () {
      const t = MiniTicker(
        symbol: 'X',
        closePrice: 1,
        openPrice: 0,
        highPrice: 1,
        lowPrice: 0,
        volume: 0,
        quoteVolume: 0,
      );
      expect(t.changePercent, 0.0);
    });
  });
}
