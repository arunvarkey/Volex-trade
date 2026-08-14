import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/data/historical_repository.dart';

/// Verifies the synthetic-candle fallback that keeps the markets scanner and
/// charts populated when no exchange is configured (the "No coins found" fix).
void main() {
  final repo = HistoricalRepository(); // null exchange -> synthetic fallback

  test('fetchHistory returns the requested number of synthetic candles',
      () async {
    final candles =
        await repo.fetchHistory(symbol: 'BTCUSDT', interval: '1h', limit: 50);
    expect(candles.length, 50);
  });

  test('synthetic candles have valid OHLC relationships', () async {
    final candles =
        await repo.fetchHistory(symbol: 'ETHUSDT', interval: '1m', limit: 40);
    expect(candles, isNotEmpty);
    for (final c in candles) {
      expect(c.close, greaterThan(0));
      expect(c.high, greaterThanOrEqualTo(c.open));
      expect(c.high, greaterThanOrEqualTo(c.close));
      expect(c.low, lessThanOrEqualTo(c.open));
      expect(c.low, lessThanOrEqualTo(c.close));
      expect(c.volume, greaterThanOrEqualTo(0));
    }
  });

  test('is deterministic per symbol so the list is stable across scans',
      () async {
    final a =
        await repo.fetchHistory(symbol: 'SOLUSDT', interval: '1h', limit: 20);
    final b =
        await repo.fetchHistory(symbol: 'SOLUSDT', interval: '1h', limit: 20);
    expect(a.map((c) => c.close).toList(), b.map((c) => c.close).toList());
  });

  test('fetchHistoryBatch returns data for every requested symbol', () async {
    final batch = await repo.fetchHistoryBatch(
      symbols: ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'],
      interval: '1m',
      limit: 30,
    );
    expect(batch.keys, containsAll(['BTCUSDT', 'ETHUSDT', 'SOLUSDT']));
    for (final v in batch.values) {
      expect(v.length, 30);
    }
  });
}
