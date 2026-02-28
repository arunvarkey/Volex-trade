import 'dart:math';

enum DataFeedType { historical, synthetic, scenario }

abstract class SandboxDataFeed {
  DataFeedType get type;
  Future<List<double>> getPriceStream();
}

class SyntheticDataFeed implements SandboxDataFeed {
  @override
  final DataFeedType type = DataFeedType.synthetic;

  final int length;
  final double startPrice;
  final double volatility; // 0.0 to 1.0 (e.g. 0.02 for 2%)

  SyntheticDataFeed({
    this.length = 1000,
    this.startPrice = 100.0,
    this.volatility = 0.02,
  });

  @override
  Future<List<double>> getPriceStream() async {
    final random = Random(42); // Deterministic seed
    List<double> prices = [startPrice];

    for (int i = 0; i < length; i++) {
      double changePercent = (random.nextDouble() - 0.5) * 2 * volatility;
      double newPrice = prices.last * (1 + changePercent);
      prices.add(newPrice);
    }
    return prices;
  }
}

class HistoricalDataFeed implements SandboxDataFeed {
  @override
  final DataFeedType type = DataFeedType.historical;

  final String symbol;

  HistoricalDataFeed({required this.symbol});

  @override
  Future<List<double>> getPriceStream() async {
    // Mock Historical Data
    return List.generate(100, (index) => 50000.0 + (index * 10));
  }
}
