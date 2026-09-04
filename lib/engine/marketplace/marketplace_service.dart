import 'package:flutter/foundation.dart';
import '../../core/app_logger.dart';
import 'models/strategy_listing.dart';

/// Service handles the Strategy Marketplace.
///
/// Allows users to:
/// - Browse strategies ([getFeaturedStrategies], [searchStrategies])
/// - Subscribe to strategies ([subscribeToStrategy])
/// - Publish their own strategies ([publishStrategy])
///
/// Everything here is local to the device and free. There is no server, no
/// payment provider and no seeded catalogue — the listings are whatever the
/// user has published themselves.
class MarketplaceService extends ChangeNotifier {
  /// Published strategy listings.
  ///
  /// Intentionally starts EMPTY. This used to be seeded with invented
  /// strategies carrying invented performance ("+312.5% return", "98% win
  /// rate", "$99/month") presented as though they were real products for sale
  /// — indefensible in a tool whose whole promise is honest numbers. The
  /// marketplace now shows only strategies a user has actually published.
  final List<StrategyListing> _listings = [];

  final Set<String> _subscriptions = {}; // Set of Strategy IDs

  /// Get featured strategies for the home carousel
  Future<List<StrategyListing>> getFeaturedStrategies() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network
    return _listings;
  }

  /// Search strategies by query or category
  Future<List<StrategyListing>> searchStrategies({
    String? query,
    StrategyCategory? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _listings.where((s) {
      if (category != null && s.category != category) return false;
      if (query != null &&
          !s.title.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Add a strategy to the user's list.
  ///
  /// No money changes hands: there is no in-app purchase, no payment provider
  /// and no billing account behind this app. The delay here used to be
  /// commented "simulate payment processing", which — paired with a button
  /// reading "Subscribe ($X/mo)" — made a free local list-append look like a
  /// completed purchase. The UI now says what this is, and the fake delay is
  /// gone with it.
  Future<bool> subscribeToStrategy(String strategyId) async {
    AppLogger.info("MARKET: Adding $strategyId to the user's strategies...");
    _subscriptions.add(strategyId);
    notifyListeners();
    return true;
  }

  /// Check if user is subscribed
  bool isSubscribed(String strategyId) {
    return _subscriptions.contains(strategyId);
  }

  /// Publish a new strategy
  Future<void> publishStrategy(StrategyListing listing) async {
    AppLogger.info("MARKET: Publishing ${listing.title}...");
    await Future.delayed(const Duration(seconds: 2));
    _listings.add(listing);
    notifyListeners();
    AppLogger.info("MARKET: Published successfully.");
  }

  // A "signal simulation" used to live here: a 10-second periodic timer,
  // started unconditionally at app launch, that emitted TradeSignals at an
  // invented price (42000 + tick * 10) attributed to a subscribed strategy.
  // CopyTradingEngine listened to it and placed real paper orders — so a
  // user's balance could move on prices that never occurred, credited to a
  // strategy that never produced a signal. There is no signal source behind
  // it (the comment said "in reality, this would come from a websocket"), so
  // the timer, the stream and the copy-trading engine are gone rather than
  // feeding fabricated fills into the simulator. It also means the app no
  // longer runs a timer forever on every launch for nothing.
}

extension StrategyListingCopy on StrategyListing {
  StrategyListing copyWith({
    String? title,
    String? description,
    double? monthlyPrice,
    MarketplaceTier? tier,
    double? totalReturn,
    double? winRate,
    double? rating,
  }) {
    return StrategyListing(
      id: id,
      authorId: authorId,
      authorName: authorName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      tier: tier ?? this.tier,
      totalReturn: totalReturn ?? this.totalReturn,
      winRate: winRate ?? this.winRate,
      maxDrawdown: maxDrawdown,
      subscriberCount: subscriberCount,
      rating: rating ?? this.rating,
      verified: verified,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
    );
  }
}
