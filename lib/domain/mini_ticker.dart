/// Lightweight model for 24hr rolling window ticker data.
/// Used for the Watchlist to show massive amounts of data efficiently.
class MiniTicker {
  final String symbol;
  final double closePrice; // "c"
  final double openPrice; // "o"
  final double highPrice; // "h"
  final double lowPrice; // "l"
  final double volume; // "v"
  final double quoteVolume; // "q"

  const MiniTicker({
    required this.symbol,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
  });

  /// 24hr Price Change Percentage
  double get changePercent {
    if (openPrice == 0) return 0.0;
    return ((closePrice - openPrice) / openPrice) * 100;
  }

  /// 24hr Price Change Absolute
  double get changeAmount => closePrice - openPrice;

  @override
  String toString() =>
      'MiniTicker($symbol: $closePrice | ${changePercent.toStringAsFixed(2)}%)';
}
