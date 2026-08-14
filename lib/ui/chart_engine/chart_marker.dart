/// A trade to overlay on the chart: a filled buy or sell at a price and time.
///
/// Kept intentionally minimal and dependency-free so the chart engine stays
/// decoupled from the trading/backtest models — callers map their own order or
/// backtest types onto this.
class ChartMarker {
  /// Epoch milliseconds of the fill (mapped to the nearest candle).
  final int timeMs;

  /// Fill price — where the triangle anchors on the price axis.
  final double price;

  /// Buy (green, below the bar) vs sell (red, above the bar).
  final bool isBuy;

  const ChartMarker({
    required this.timeMs,
    required this.price,
    required this.isBuy,
  });
}
