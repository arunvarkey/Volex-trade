import 'dart:math';
import 'chart_models.dart';

class MockAnalyticsData {
  static List<EquityPoint> generateEquityPoints(int count) {
    final Random random = Random();
    double currentEquity = 10000.0;
    List<EquityPoint> points = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      double change = (random.nextDouble() - 0.48) * 200;
      currentEquity += change;
      double drawdown = random.nextDouble() * 0.08;

      MarketRegime regime = MarketRegime.bull;
      if (i > count * 0.2) regime = MarketRegime.sideways;
      if (i > count * 0.5) regime = MarketRegime.bear;
      if (i > count * 0.8) regime = MarketRegime.volatile;

      TradeMarker? marker;
      if (i > 0 && i % 25 == 0) {
        marker = TradeMarker(
          type: i % 50 == 0 ? TradeMarkerType.buy : TradeMarkerType.sell,
          label: i % 50 == 0 ? "BUY" : "SELL",
        );
      }

      points.add(EquityPoint(
        timestamp: now.subtract(Duration(hours: count - i)),
        equity: currentEquity,
        drawdown: drawdown,
        regime: regime,
        marker: marker,
      ));
    }
    return points;
  }

  static AnalyticsData generateFullAnalyticsData(int count) {
    final curve = generateEquityPoints(count);
    DateTime now = DateTime.now();

    final regimes = [
      MarketRegimeSegment(
        regime: MarketRegime.bull,
        start: now.subtract(Duration(hours: count)),
        end: now.subtract(Duration(hours: (count * 0.8).toInt())),
        label: "ACCUMULATION",
      ),
      MarketRegimeSegment(
        regime: MarketRegime.volatile,
        start: now.subtract(Duration(hours: (count * 0.2).toInt())),
        end: now,
        label: "DISTRIBUTION",
      ),
    ];

    List<VolatilityData> volatility = [];
    for (int i = 0; i < count; i++) {
      final point = curve[i];
      volatility.add(VolatilityData(
        timestamp: point.timestamp,
        upper: point.equity * 1.05,
        lower: point.equity * 0.95,
      ));
    }

    return AnalyticsData(
      equityCurve: curve,
      regimes: regimes,
      volatilityBands: volatility,
      enabledIndicators: {ChartIndicatorType.ma, ChartIndicatorType.bollinger},
    );
  }

  static List<PricePoint> generatePricePoints(int count) {
    final Random random = Random();
    double currentPrice = 42000.0;
    List<PricePoint> points = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      currentPrice += (random.nextDouble() - 0.5) * 50;
      points.add(PricePoint(
        timestamp: now.subtract(Duration(minutes: (count - i) * 15)),
        price: currentPrice,
      ));
    }
    return points;
  }

  static TradeDistribution get mockTradeDistribution => const TradeDistribution(
        longWins: 42,
        longLosses: 25,
        shortWins: 38,
        shortLosses: 30,
        byHour: {
          8: 5,
          9: 12,
          10: 15,
          11: 8,
          14: 10,
          15: 18,
          16: 22,
          17: 15,
        },
      );
}
