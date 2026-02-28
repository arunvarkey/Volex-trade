class StrategyPerformanceMetrics {
  final int tradesExecuted;
  final int wins;
  final int losses;
  final double avgReturn;
  final double maxDrawdown;
  final double volatility;
  final double sharpeEstimate; // Simplified

  double get winRate => tradesExecuted > 0 ? wins / tradesExecuted : 0.0;

  const StrategyPerformanceMetrics({
    this.tradesExecuted = 0,
    this.wins = 0,
    this.losses = 0,
    this.avgReturn = 0.0,
    this.maxDrawdown = 0.0,
    this.volatility = 0.0,
    this.sharpeEstimate = 0.0,
  });
}

class SubscriberAnalytics {
  final int activeSubscribers;
  final double churnRate; // Percentage 0-1
  final int newSubscribersLast30Days;
  final Map<String, int> tierDistribution; // 'basic' -> 10, 'pro' -> 5

  const SubscriberAnalytics({
    this.activeSubscribers = 0,
    this.churnRate = 0.0,
    this.newSubscribersLast30Days = 0,
    this.tierDistribution = const {},
  });
}

class RevenueAnalytics {
  final double monthlyRevenue;
  final double lifetimeRevenue;
  final double pendingPayouts;
  final Map<String, double> revenueByStrategy;

  const RevenueAnalytics({
    this.monthlyRevenue = 0.0,
    this.lifetimeRevenue = 0.0,
    this.pendingPayouts = 0.0,
    this.revenueByStrategy = const {},
  });
}

class VersionAdoptionMetrics {
  final String version;
  final int numberOfUsers;
  final int numberOfTrades;
  final double performanceDelta; // +0.05 means 5% better than prev

  const VersionAdoptionMetrics({
    required this.version,
    this.numberOfUsers = 0,
    this.numberOfTrades = 0,
    this.performanceDelta = 0.0,
  });
}
