import '../parameters/parameter_models.dart';

enum RiskProfile { low, medium, high, extreme }

enum StrategyTimeframe { scalping, dayTrading, swingTrading, position }

class StrategyMetadata {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final RiskProfile riskProfile;
  final StrategyTimeframe timeframe;
  final List<String> supportedSymbols;
  final List<StrategyParameterSchema> parameters;

  // Pricing
  final double monthlyPrice;
  final double yearlyPrice;

  bool get isPaid => monthlyPrice > 0 || yearlyPrice > 0;

  // Trust Score (New Day 28/30)
  final StrategyTrustScore trustScore;

  const StrategyMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.riskProfile,
    required this.timeframe,
    required this.supportedSymbols,
    required this.parameters,
    this.monthlyPrice = 0.0,
    this.yearlyPrice = 0.0,
    this.trustScore = const StrategyTrustScore.empty(),
  });

  StrategyMetadata copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    RiskProfile? riskProfile,
    StrategyTimeframe? timeframe,
    List<String>? supportedSymbols,
    List<StrategyParameterSchema>? parameters, // Fixed type
    double? monthlyPrice,
    double? yearlyPrice,
    StrategyTrustScore? trustScore,
  }) {
    return StrategyMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      riskProfile: riskProfile ?? this.riskProfile,
      timeframe: timeframe ?? this.timeframe,
      supportedSymbols: supportedSymbols ?? this.supportedSymbols,
      parameters: parameters ?? this.parameters,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}

class StrategyTrustScore {
  final int totalLiveTrades;
  final double winRate; // 0.0 to 1.0
  final int riskBlocks; // Negative signal
  final int killSwitchEvents; // Critical negative
  final double averageDailyPnL;

  const StrategyTrustScore({
    required this.totalLiveTrades,
    required this.winRate,
    required this.riskBlocks,
    required this.killSwitchEvents,
    required this.averageDailyPnL,
  });

  const StrategyTrustScore.empty()
      : totalLiveTrades = 0,
        winRate = 0.0,
        riskBlocks = 0,
        killSwitchEvents = 0,
        averageDailyPnL = 0.0;

  String get category {
    if (killSwitchEvents > 0) return "CAUTION";
    if (totalLiveTrades < 10) return "UNVERIFIED";
    if (riskBlocks > 5) return "CAUTION";
    return "TRUSTED";
  }
}
