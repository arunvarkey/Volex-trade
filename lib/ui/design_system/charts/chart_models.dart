enum MarketRegime { bull, bear, sideways, volatile, trending }

class MarketRegimeSegment {
  final MarketRegime regime;
  final DateTime start;
  final DateTime end;
  final String? label;

  MarketRegimeSegment({
    required this.regime,
    required this.start,
    required this.end,
    this.label,
  });
}

class VolatilityData {
  final DateTime timestamp;
  final double upper;
  final double lower;

  VolatilityData(
      {required this.timestamp, required this.upper, required this.lower});
}

enum ChartIndicatorType { ma, vwap, bollinger, rsi, volume }

enum TradeMarkerType { buy, sell, exit }

class TradeMarker {
  final TradeMarkerType type;
  final String label;

  TradeMarker({required this.type, required this.label});
}

class EquityPoint {
  final DateTime timestamp;
  final double equity;
  final double drawdown; // 0.0 to 1.0
  final MarketRegime? regime;
  final TradeMarker? marker;

  const EquityPoint({
    required this.timestamp,
    required this.equity,
    this.drawdown = 0.0,
    this.regime,
    this.marker,
  });
}

class AnalyticsData {
  final List<EquityPoint> equityCurve;
  final List<MarketRegimeSegment> regimes;
  final List<VolatilityData>? volatilityBands;
  final Set<ChartIndicatorType> enabledIndicators;

  AnalyticsData({
    required this.equityCurve,
    this.regimes = const [],
    this.volatilityBands,
    this.enabledIndicators = const {},
  });

  double get maxDrawdown {
    if (equityCurve.isEmpty) return 0;
    double maxEquity = 0;
    double maxDD = 0;
    for (var p in equityCurve) {
      if (p.equity > maxEquity) maxEquity = p.equity;
      double dd = maxEquity - p.equity;
      if (dd > maxDD) maxDD = dd;
    }
    return maxDD;
  }
}

class PricePoint {
  final DateTime timestamp;
  final double price;

  PricePoint({required this.timestamp, required this.price});
}

class TradeDistribution {
  final int longWins;
  final int longLosses;
  final int shortWins;
  final int shortLosses;
  final Map<int, int> byHour; // Hour 0-23 -> Count

  const TradeDistribution({
    this.longWins = 0,
    this.longLosses = 0,
    this.shortWins = 0,
    this.shortLosses = 0,
    this.byHour = const {},
  });

  int get totalTrades => longWins + longLosses + shortWins + shortLosses;
  int get totalWins => longWins + shortWins;
  int get totalLosses => longLosses + shortLosses;
}
