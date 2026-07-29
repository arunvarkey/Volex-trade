import 'dart:math';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/symbol_info.dart';
import 'package:volex_terminal/data/binance/binance_exchange_service.dart';
import 'package:volex_terminal/core/app_logger.dart';

class HistoricalRepository {
  final BinanceExchangeService? _exchange; // Injectable, nullable if offline

  HistoricalRepository({BinanceExchangeService? exchange})
      : _exchange = exchange;

  /// Fetch history. If [useRealData] is true and exchange is available, fetches from Binance.
  /// Otherwise falls back to Mock Data.
  Future<List<Candle>> fetchHistory(
      {required String symbol,
      required String interval,
      bool useRealData = false,
      int limit = 1000}) async {
    if (_exchange != null) {
      try {
        AppLogger.info(
            "HISTORY: Fetching $limit candles for $symbol from Binance...");
        final symbolInfo = SymbolRegistry.supportedSymbols.firstWhere(
          (s) => s.symbol == symbol,
          orElse: () => SymbolRegistry.defaultSymbol,
        );
        final data =
            await _exchange.getKlines(symbolInfo, interval, limit: limit);
        AppLogger.info("HISTORY: Received ${data.length} candles.");
        if (data.isNotEmpty) return data;
        AppLogger.warning(
            "HISTORY: Empty real data for $symbol; using synthetic candles.");
      } catch (e) {
        AppLogger.error(
            "HISTORY: Failed to fetch real data: $e. Using synthetic candles.");
      }
    }

    // Synthetic fallback so the simulator (scanner, charts, offline preview)
    // always has plausible data instead of an empty screen.
    return _generateSyntheticCandles(symbol, interval, limit);
  }

  /// Deterministic, plausible random-walk candles per symbol so the same
  /// symbol renders a stable series across scans.
  List<Candle> _generateSyntheticCandles(
      String symbol, String interval, int limit) {
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

  double _basePriceFor(String symbol) {
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
    };
    return prices[symbol] ?? 100.0;
  }

  int _intervalMs(String interval) {
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

  /// Fetch history for multiple symbols in parallel.
  Future<Map<String, List<Candle>>> fetchHistoryBatch({
    required List<String> symbols,
    required String interval,
    bool useRealData = false,
    int limit = 1000,
  }) async {
    final futures = <Future<List<Candle>>>[];
    for (final symbol in symbols) {
      futures.add(fetchHistory(
        symbol: symbol,
        interval: interval,
        useRealData: useRealData,
        limit: limit,
      ));
    }

    final results = await Future.wait(futures);
    final map = <String, List<Candle>>{};
    for (int i = 0; i < symbols.length; i++) {
      map[symbols[i]] = results[i];
    }
    return map;
  }
}
