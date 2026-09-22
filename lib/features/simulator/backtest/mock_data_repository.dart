import 'package:volex_terminal/data/i_market_data_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/mini_ticker.dart';
import 'package:volex_terminal/data/data_status.dart';
import 'dart:async';

class MockDataRepository implements IMarketDataRepository {
  @override
  String get currentSymbol => 'BTCUSDT';

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Candle>> fetchHistory(
      {String symbol = "BTCUSDT",
      String interval = "1m",
      int limit = 500}) async {
    return [];
  }

  @override
  void connectStream({String symbol = "btcusdt", String interval = "1m"}) {}

  @override
  void switchStream(String symbol, String interval) {}

  @override
  void switchSymbol(String symbol) {}

  @override
  Stream<List<Candle>> getHistoryStream(String symbol, String interval) =>
      const Stream.empty();

  @override
  Stream<Candle> getStreamForSymbol(String symbol) => const Stream.empty();

  @override
  Stream<Candle> get updatesStream => const Stream.empty();

  @override
  Stream<bool> get connectionStatusStream => const Stream.empty();

  @override
  Stream<Map<String, MiniTicker>> get watchlistStream => const Stream.empty();

  @override
  Stream<DataStatus> get statusStream => const Stream.empty();

  @override
  void dispose() {}
}
