import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/symbol_info.dart';
import 'package:volex_terminal/data/binance/binance_exchange_service.dart';
import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/core/synthetic_candles.dart';

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
    return SyntheticCandles.generate(symbol, interval, limit);
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
