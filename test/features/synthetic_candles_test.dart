import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/core/synthetic_candles.dart';
import 'package:volex_terminal/data/historical_repository.dart';

/// Guards the offline/failed-fetch fallback that fixes the "All Markets is
/// empty" bug: with no exchange (or an exchange that returns nothing) the
/// simulator must still get plausible, well-formed candles instead of a blank
/// screen.
void main() {
  group('SyntheticCandles.generate', () {
    test('returns exactly the requested number of candles', () {
      expect(SyntheticCandles.generate('BTCUSDT', '1h', 200).length, 200);
      expect(SyntheticCandles.generate('ETHUSDT', '5m', 50).length, 50);
      expect(SyntheticCandles.generate('UNKNOWN', '1d', 1).length, 1);
    });

    test('every candle is well-formed OHLC with positive prices', () {
      final candles = SyntheticCandles.generate('SOLUSDT', '15m', 300);
      for (final c in candles) {
        expect(c.open, greaterThan(0), reason: 'open positive');
        expect(c.close, greaterThan(0), reason: 'close positive');
        expect(c.high, greaterThanOrEqualTo(c.open), reason: 'high >= open');
        expect(c.high, greaterThanOrEqualTo(c.close), reason: 'high >= close');
        expect(c.low, lessThanOrEqualTo(c.open), reason: 'low <= open');
        expect(c.low, lessThanOrEqualTo(c.close), reason: 'low <= close');
        expect(c.volume, greaterThan(0), reason: 'volume positive');
      }
    });

    test('candles are in ascending chronological order', () {
      final candles = SyntheticCandles.generate('BTCUSDT', '1h', 100);
      for (var i = 1; i < candles.length; i++) {
        expect(candles[i].time, greaterThan(candles[i - 1].time));
      }
    });

    test('is deterministic for the same symbol + interval', () {
      final a = SyntheticCandles.generate('BTCUSDT', '1h', 100);
      final b = SyntheticCandles.generate('BTCUSDT', '1h', 100);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].open, b[i].open);
        expect(a[i].close, b[i].close);
      }
    });

    test('different symbols produce different series', () {
      final btc = SyntheticCandles.generate('BTCUSDT', '1h', 20);
      final eth = SyntheticCandles.generate('ETHUSDT', '1h', 20);
      // Base prices differ, so the opening prices cannot all match.
      final allEqual = List.generate(20, (i) => btc[i].open == eth[i].open)
          .every((x) => x);
      expect(allEqual, isFalse);
    });
  });

  group('HistoricalRepository fallback', () {
    test('with no exchange, fetchHistory still returns data (never empty)',
        () async {
      final repo = HistoricalRepository(); // exchange == null
      final candles =
          await repo.fetchHistory(symbol: 'BTCUSDT', interval: '1h', limit: 150);
      expect(candles, isNotEmpty);
      expect(candles.length, 150);
    });

    test('batch fetch yields data for every requested symbol', () async {
      final repo = HistoricalRepository();
      final result = await repo.fetchHistoryBatch(
        symbols: const ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'],
        interval: '1h',
        limit: 60,
      );
      expect(result.keys, containsAll(['BTCUSDT', 'ETHUSDT', 'SOLUSDT']));
      for (final entry in result.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} has candles');
      }
    });
  });
}
