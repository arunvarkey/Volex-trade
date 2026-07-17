import 'package:flutter/material.dart';

/// Broad grouping for event markets, used for filtering and colour-coding.
enum MarketCategory { crypto, macro, politics, tech, culture }

extension MarketCategoryX on MarketCategory {
  String get label {
    switch (this) {
      case MarketCategory.crypto:
        return 'Crypto';
      case MarketCategory.macro:
        return 'Macro';
      case MarketCategory.politics:
        return 'Politics';
      case MarketCategory.tech:
        return 'Tech';
      case MarketCategory.culture:
        return 'Culture';
    }
  }

  String get emoji {
    switch (this) {
      case MarketCategory.crypto:
        return '₿';
      case MarketCategory.macro:
        return '🏛️';
      case MarketCategory.politics:
        return '🗳️';
      case MarketCategory.tech:
        return '💻';
      case MarketCategory.culture:
        return '🎬';
    }
  }
}

/// Which side of a Yes/No event contract a position is on.
enum ContractSide { yes, no }

/// A Kalshi-style event market: a real-world question resolved Yes or No.
///
/// [yesPrice] is expressed in cents (1–99), which doubles as the market's
/// implied probability of "Yes" (e.g. 63 => 63% and costs 63¢ per contract,
/// paying out 100¢ if it resolves Yes). The "No" side costs `100 - yesPrice`.
class EventMarket {
  final String id;
  final String question;
  final String context;
  final MarketCategory category;
  final int yesPrice; // 1..99, cents == implied probability %
  final int change24h; // percentage-point move in yesPrice over 24h
  final double volume; // simulated traded volume (virtual $)
  final String closesLabel; // human-readable close, e.g. "Dec 31, 2026"

  const EventMarket({
    required this.id,
    required this.question,
    required this.context,
    required this.category,
    required this.yesPrice,
    required this.change24h,
    required this.volume,
    required this.closesLabel,
  });

  int get noPrice => 100 - yesPrice;

  /// Cost in cents to buy one contract on [side].
  int priceFor(ContractSide side) =>
      side == ContractSide.yes ? yesPrice : noPrice;
}

/// A "mention" in the buzz feed — a notable figure or headline moving sentiment
/// on a linked market. Bold, headline-driven, deliberately of-the-moment.
class MentionBuzz {
  final String id;
  final String author;
  final String avatarEmoji;
  final String quote;
  final bool bullish; // true = pushes "Yes" up, false = pushes it down
  final int mentions; // trending mention count
  final String timeAgo;
  final String? marketId; // linked event market, if any

  const MentionBuzz({
    required this.id,
    required this.author,
    required this.avatarEmoji,
    required this.quote,
    required this.bullish,
    required this.mentions,
    required this.timeAgo,
    this.marketId,
  });
}

/// A simulated position a user holds on an event market.
class PredictionPosition {
  final String marketId;
  final ContractSide side;
  final int contracts;
  final int avgPriceCents; // average entry price in cents

  const PredictionPosition({
    required this.marketId,
    required this.side,
    required this.contracts,
    required this.avgPriceCents,
  });

  /// What the user paid, in virtual dollars.
  double get costBasis => contracts * avgPriceCents / 100.0;

  /// Current value given the market's live price, in virtual dollars.
  double currentValue(EventMarket market) =>
      contracts * market.priceFor(side) / 100.0;

  /// Profit/loss in virtual dollars against [market]'s current price.
  double pnl(EventMarket market) => currentValue(market) - costBasis;

  PredictionPosition copyWith({int? contracts, int? avgPriceCents}) {
    return PredictionPosition(
      marketId: marketId,
      side: side,
      contracts: contracts ?? this.contracts,
      avgPriceCents: avgPriceCents ?? this.avgPriceCents,
    );
  }

  /// Stable key for storage: one position per market+side.
  String get key => '$marketId::${side.name}';

  Map<String, dynamic> toJson() => {
        'marketId': marketId,
        'side': side.name,
        'contracts': contracts,
        'avgPriceCents': avgPriceCents,
      };

  static PredictionPosition? fromJson(Map<String, dynamic> json) {
    final marketId = json['marketId'];
    final sideName = json['side'];
    final contracts = json['contracts'];
    final avg = json['avgPriceCents'];
    if (marketId is! String ||
        sideName is! String ||
        contracts is! int ||
        avg is! int) {
      return null;
    }
    final side = ContractSide.values.firstWhere(
      (s) => s.name == sideName,
      orElse: () => ContractSide.yes,
    );
    return PredictionPosition(
      marketId: marketId,
      side: side,
      contracts: contracts,
      avgPriceCents: avg,
    );
  }
}
