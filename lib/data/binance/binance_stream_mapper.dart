import '../../domain/candle_model.dart';
import '../../domain/mini_ticker.dart';

class BinanceStreamMapper {
  /// Maps raw JSON string to a Candle object.
  /// Throws FormatException if invalid.
  static Candle? mapKlineToCandle(dynamic jsonMap) {
    // 1. Validate structure
    if (jsonMap['e'] != 'kline') return null;

    final k = jsonMap['k'];
    if (k == null) return null;

    // 2. Extract Data (Fast parsing)
    // Binance sends strings for prices to preserve precision, we parse to double.
    return Candle(
      time: k['t'] as int, // Open time
      open: double.parse(k['o']),
      high: double.parse(k['h']),
      low: double.parse(k['l']),
      close: double.parse(k['c']),
      volume: double.parse(k['v']),
    );
  }

  static List<Candle> mapSnapshot(List<dynamic> list) {
    // Handling snapshot data (usually different format [t, o, h, l, c, v, ...])
    return list
        .map((e) => Candle(
              time: e[0] as int,
              open: double.parse(e[1]),
              high: double.parse(e[2]),
              low: double.parse(e[3]),
              close: double.parse(e[4]),
              volume: double.parse(e[5]),
            ))
        .toList();
  }

  /// Maps a list of raw MiniTicker objects to domain models.
  static List<MiniTicker> mapMiniTickerList(List<dynamic> list) {
    return list.map((e) => mapMiniTicker(e)).whereType<MiniTicker>().toList();
  }

  static MiniTicker? mapMiniTicker(dynamic jsonMap) {
    // e: 24hrMiniTicker
    if (jsonMap['e'] != '24hrMiniTicker') return null;

    return MiniTicker(
      symbol: jsonMap['s'],
      closePrice: double.parse(jsonMap['c']),
      openPrice: double.parse(jsonMap['o']),
      highPrice: double.parse(jsonMap['h']),
      lowPrice: double.parse(jsonMap['l']),
      volume: double.parse(jsonMap['v']),
      quoteVolume: double.parse(jsonMap['q']),
    );
  }
}
