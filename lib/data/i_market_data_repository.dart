import 'dart:async';
import '../domain/candle_model.dart';
import '../domain/mini_ticker.dart';
import 'data_status.dart';

abstract class IMarketDataRepository {
  Stream<Candle> get updatesStream;

  /// The symbol [updatesStream] is currently delivering, uppercased.
  ///
  /// Candles carry no symbol, so without this a listener cannot tell which
  /// market a tick belongs to — and pricing one market's position with
  /// another's tick is not a small error.
  String get currentSymbol;

  Stream<Map<String, MiniTicker>> get watchlistStream;
  Stream<DataStatus> get statusStream;
  Stream<bool> get connectionStatusStream;

  Future<void> initialize();
  void connectStream({String symbol = "btcusdt", String interval = "1m"});
  void switchStream(String symbol, String interval);
  void switchSymbol(String symbol);
  Future<List<Candle>> fetchHistory(
      {String symbol = "BTCUSDT", String interval = "1m", int limit = 500});
  Stream<List<Candle>> getHistoryStream(String symbol, String interval);
  Stream<Candle> getStreamForSymbol(String symbol);
  void dispose();
}
