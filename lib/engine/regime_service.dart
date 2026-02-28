import '../domain/candle_model.dart';

enum TrendRegime { trend, chop }

enum VolatilityRegime { high, low }

class MarketRegime {
  final TrendRegime trend;
  final VolatilityRegime volatility;
  final double adx; // Mock/Simplified ADX-like value
  final double atrRatio;

  MarketRegime({
    required this.trend,
    required this.volatility,
    required this.adx,
    required this.atrRatio,
  });

  String get tag =>
      "${trend.name.toUpperCase()}_${volatility.name.toUpperCase()}";

  @override
  String toString() => tag;
}

class RegimeService {
  /// Detects the current market regime based on a window of candles
  MarketRegime detect(List<Candle> candles) {
    if (candles.length < 20) {
      return MarketRegime(
        trend: TrendRegime.chop,
        volatility: VolatilityRegime.low,
        adx: 10,
        atrRatio: 1.0,
      );
    }

    final window =
        candles.length > 50 ? candles.sublist(candles.length - 50) : candles;

    // 1. Trend Detection (Simplified Efficiency Ratio / Ghost-like slope)
    double priceChange = (window.last.close - window.first.open).abs();
    double pathLength = 0;
    for (int i = 1; i < window.length; i++) {
      pathLength += (window[i].close - window[i - 1].close).abs();
    }

    // Efficiency Ratio (Kaufman)
    double er = pathLength == 0 ? 0 : priceChange / pathLength;
    TrendRegime trend = er > 0.3 ? TrendRegime.trend : TrendRegime.chop;

    // 2. Volatility Detection (ATR relative to recent average)
    List<double> ranges = window.map((c) => c.high - c.low).toList();
    double currentAtr =
        ranges.sublist(ranges.length - 14).reduce((a, b) => a + b) / 14;
    double baselineAtr = ranges.reduce((a, b) => a + b) / ranges.length;

    double atrRatio = baselineAtr == 0 ? 1.0 : currentAtr / baselineAtr;
    VolatilityRegime vol =
        atrRatio > 1.2 ? VolatilityRegime.high : VolatilityRegime.low;

    return MarketRegime(
      trend: trend,
      volatility: vol,
      adx: er * 100, // Normalized to 0-100 scale for UI
      atrRatio: atrRatio,
    );
  }
}
