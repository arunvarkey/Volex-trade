import 'package:equatable/equatable.dart';

enum StrategyCategory {
  trendFollowing,
  meanReversion,
  breakout,
  arbitrage,
  scalping,
  aiExperimental
}

enum MarketplaceTier { free, basic, premium, exclusive }

class StrategyListing extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String description;
  final StrategyCategory category;
  final double monthlyPrice; // In Volex Credits or USD
  final MarketplaceTier tier;

  // Performance Metrics (Snapshot)
  final double totalReturn;
  final double winRate;
  final double maxDrawdown;
  final int subscriberCount;
  final double rating; // 0.0 to 5.0
  final bool verified; // "Verified by Volex" badge

  final DateTime createdAt;
  final DateTime lastUpdated;

  const StrategyListing({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.category,
    required this.monthlyPrice,
    required this.tier,
    required this.totalReturn,
    required this.winRate,
    required this.maxDrawdown,
    this.subscriberCount = 0,
    this.rating = 0.0,
    this.verified = false,
    required this.createdAt,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        title,
        category,
        monthlyPrice,
        tier,
        totalReturn,
        subscriberCount,
        rating,
        verified
      ];

  // Helper to fake robust data for UI testing
  static StrategyListing mock({
    String id = "strat_001",
    String title = "Golden Cross Alpha",
    StrategyCategory category = StrategyCategory.trendFollowing,
  }) {
    return StrategyListing(
      id: id,
      authorId: "auth_001",
      authorName: "Quantum Trader",
      title: title,
      description:
          "Uses SMA 50/200 crossover with RSI confirmation. Low drawdown, steady growth.",
      category: category,
      monthlyPrice: 29.99,
      tier: MarketplaceTier.basic,
      totalReturn: 145.2,
      winRate: 0.62,
      maxDrawdown: -12.5,
      subscriberCount: 842,
      rating: 4.8,
      verified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
    );
  }
}
