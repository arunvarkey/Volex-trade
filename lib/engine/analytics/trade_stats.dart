class TradeStats {
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double profitFactor;
  final double expectancy;
  final double maxDrawdown;
  final double avgWin;
  final double avgLoss;
  final double grossProfit;
  final double grossLoss;
  final List<double> equityCurve;

  const TradeStats({
    this.totalTrades = 0,
    this.winningTrades = 0,
    this.losingTrades = 0,
    this.winRate = 0.0,
    this.profitFactor = 0.0,
    this.expectancy = 0.0,
    this.maxDrawdown = 0.0,
    this.avgWin = 0.0,
    this.avgLoss = 0.0,
    this.grossProfit = 0.0,
    this.grossLoss = 0.0,
    this.equityCurve = const [],
  });

  factory TradeStats.empty() {
    return const TradeStats();
  }

  Map<String, dynamic> toJson() => {
        'totalTrades': totalTrades,
        'winningTrades': winningTrades,
        'losingTrades': losingTrades,
        'winRate': winRate,
        'profitFactor': profitFactor,
        'expectancy': expectancy,
        'maxDrawdown': maxDrawdown,
        'avgWin': avgWin,
        'avgLoss': avgLoss,
        'grossProfit': grossProfit,
        'grossLoss': grossLoss,
        'equityCurve': equityCurve,
      };

  factory TradeStats.fromJson(Map<String, dynamic> json) => TradeStats(
        totalTrades: json['totalTrades'] ?? 0,
        winningTrades: json['winningTrades'] ?? 0,
        losingTrades: json['losingTrades'] ?? 0,
        winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
        profitFactor: (json['profitFactor'] as num?)?.toDouble() ?? 0.0,
        expectancy: (json['expectancy'] as num?)?.toDouble() ?? 0.0,
        maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0.0,
        avgWin: (json['avgWin'] as num?)?.toDouble() ?? 0.0,
        avgLoss: (json['avgLoss'] as num?)?.toDouble() ?? 0.0,
        grossProfit: (json['grossProfit'] as num?)?.toDouble() ?? 0.0,
        grossLoss: (json['grossLoss'] as num?)?.toDouble() ?? 0.0,
        equityCurve: (json['equityCurve'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
      );
}
