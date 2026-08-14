import 'dart:math';
import 'package:volex_terminal/domain/candle_model.dart';

/// Deterministic, plausible random-walk candles per symbol.
///
/// Used as an offline/failed-fetch fallback so the simulator (charts, market
/// scanner, and the signal engine) always has data to work with instead of an
/// empty screen. The seed is derived from the symbol + interval, so the same
/// inputs render a stable series across calls.
class SyntheticCandles {
  const SyntheticCandles._();

  static List<Candle> generate(String symbol, String interval, int limit) {
    final base = _basePriceFor(symbol);
    final rng = Random(symbol.hashCode ^ interval.hashCode);
    final stepMs = _intervalMs(interval);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    double price = base * (0.96 + rng.nextDouble() * 0.08);

    final out = <Candle>[];
    for (int i = limit - 1; i >= 0; i--) {
      final t = nowMs - stepMs * i;
      final open = price;
      final change = (rng.nextDouble() - 0.5) * base * 0.006;
      var close = open + change;
      if (close <= 0) close = open;
      final high =
          (open > close ? open : close) + rng.nextDouble() * base * 0.003;
      final low =
          (open < close ? open : close) - rng.nextDouble() * base * 0.003;
      final vol = base * (2 + rng.nextDouble() * 8);
      out.add(Candle(
          time: t,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: vol));
      price = close;
    }
    return out;
  }

  static double _basePriceFor(String symbol) {
    const prices = {
      'BTCUSDT': 64000.0,
      'ETHUSDT': 3200.0,
      'SOLUSDT': 150.0,
      'BNBUSDT': 575.0,
      'XRPUSDT': 0.6,
      'DOGEUSDT': 0.12,
      'ADAUSDT': 0.45,
      'AVAXUSDT': 35.0,
      'LINKUSDT': 15.0,
      'MATICUSDT': 0.7,
      'DOTUSDT': 6.5,
      'TRXUSDT': 0.12,
      'LTCUSDT': 85.0,
      'ATOMUSDT': 8.0,
    };
    return prices[symbol.toUpperCase()] ?? 100.0;
  }

  static int _intervalMs(String interval) {
    switch (interval) {
      case '5m':
        return 5 * 60000;
      case '15m':
        return 15 * 60000;
      case '1h':
        return 60 * 60000;
      case '4h':
        return 4 * 60 * 60000;
      case '1d':
        return 24 * 60 * 60000;
      case '1m':
      default:
        return 60000;
    }
  }
}
