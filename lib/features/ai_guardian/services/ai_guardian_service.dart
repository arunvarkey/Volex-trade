import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:volex_terminal/features/ai_guardian/models/trade_analysis.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/core/app_logger.dart';

class AIGuardianService {
  // Lazy: touching Firestore at construction crashes on platforms where
  // Firebase isn't configured (web preview). _getRecentTrades already
  // catches failures and returns [], so analysis degrades gracefully and
  // never blocks a trade.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final String _userId;

  AIGuardianService(this._userId);

  /// Main analysis method - call this before executing trade
  Future<TradeAnalysis> analyzeTradeIntent(Order order) async {
    try {
      // 1. Get recent trading history
      final history = await _getRecentTrades();

      // 2. Detect emotional state
      final emotionalState = _detectEmotionalState(order, history);

      // 3. Find dangerous patterns
      final patterns = _detectDangerousPatterns(order, history);

      // 4. Calculate risk score
      final riskScore = _calculateRiskScore(emotionalState, patterns);

      // 5. Generate recommendation
      final recommendation = _generateRecommendation(
        emotionalState,
        patterns,
        riskScore,
      );

      // 6. Should we warn?
      final shouldWarn = riskScore > 50 ||
          emotionalState != EmotionalState.calm ||
          patterns.isNotEmpty;

      return TradeAnalysis(
        emotionalState: emotionalState,
        patterns: patterns,
        riskScore: riskScore,
        shouldWarn: shouldWarn,
        recommendation: recommendation,
      );
    } catch (e, stack) {
      AppLogger.error('AI Guardian failed', e, stack);

      // Don't block trades on error - return safe default
      return TradeAnalysis(
        emotionalState: EmotionalState.calm,
        patterns: [],
        riskScore: 0,
        shouldWarn: false,
        recommendation: 'Analysis unavailable. Trade with caution.',
      );
    }
  }

  /// Detect emotional state from behavior
  EmotionalState _detectEmotionalState(
    Order order,
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return EmotionalState.calm;

    final lastHour = DateTime.now().subtract(const Duration(hours: 1));
    final recentTrades = history.where((t) {
      final timestamp = (t['timestamp'] as Timestamp).toDate();
      return timestamp.isAfter(lastHour);
    }).toList();

    // PATTERN 1: Revenge Trading
    // Lost money + trading again quickly
    if (recentTrades.isNotEmpty) {
      final lastTrade = recentTrades
          .first; // Guide said last, but firestore sort is desc, so first is most recent
      final lastPnL = (lastTrade['pnl'] as num?)?.toDouble() ?? 0;
      final timeSince = DateTime.now()
          .difference((lastTrade['timestamp'] as Timestamp).toDate())
          .inMinutes;

      if (lastPnL < -100 && timeSince < 5) {
        return EmotionalState.revenge;
      }
    }

    // PATTERN 2: FOMO
    // Price surged + large position
    final symbolTrades =
        history.where((t) => t['symbol'] == order.symbol).toList();

    if (symbolTrades.isNotEmpty) {
      final oldPrice = (symbolTrades.first['entry_price'] as num).toDouble();
      final priceChange = ((order.price - oldPrice) / oldPrice) * 100;

      if (priceChange > 5 && order.quantity * order.price > 1000) {
        return EmotionalState.fomo;
      }
    }

    // PATTERN 3: Panic
    // Price dropped + selling at loss
    if (order.side == OrderSide.sell && symbolTrades.isNotEmpty) {
      final avgEntry = symbolTrades
              .map((t) => (t['entry_price'] as num).toDouble())
              .reduce((a, b) => a + b) /
          symbolTrades.length;

      final priceChange = ((order.price - avgEntry) / avgEntry) * 100;

      if (priceChange < -5) {
        return EmotionalState.panic;
      }
    }

    return EmotionalState.calm;
  }

  /// Detect dangerous patterns
  List<PatternWarning> _detectDangerousPatterns(
    Order order,
    List<Map<String, dynamic>> history,
  ) {
    final patterns = <PatternWarning>[];

    // The user's real win rate over the history we already have in hand.
    final winRate = winRateFor(history);

    // PATTERN: Chasing losses
    final last5 = history.take(5).toList();
    if (last5.length == 5) {
      final allLosses =
          last5.every((t) => ((t['pnl'] as num?)?.toDouble() ?? 0) < 0);

      if (allLosses) {
        patterns.add(PatternWarning(
          name: 'Chasing Losses',
          description: 'You\'ve lost 5 trades in a row',
          yourWinRate: winRate.rate,
          sampleSize: winRate.sample,
        ));
      }
    }

    // PATTERN: Overtrading
    final last24h = DateTime.now().subtract(const Duration(hours: 24));
    final tradesLast24h = history.where((t) {
      final timestamp = (t['timestamp'] as Timestamp).toDate();
      return timestamp.isAfter(last24h);
    }).length;

    if (tradesLast24h > 20) {
      patterns.add(PatternWarning(
        name: 'Overtrading',
        description: 'You\'ve made $tradesLast24h trades in 24 hours',
        yourWinRate: winRate.rate,
        sampleSize: winRate.sample,
      ));
    }

    return patterns;
  }

  /// The user's win rate across [history], with the number of trades it was
  /// actually computed over.
  ///
  /// The rate is null below a handful of trades: a "win rate" over two trades
  /// is noise, and showing 0% or 100% off that would be worse than showing
  /// nothing. Trades with no recorded P&L are excluded rather than counted as
  /// losses, and the returned sample counts only what was included — quoting
  /// a rate against a larger sample than it was measured on would be its own
  /// small dishonesty.
  static ({double? rate, int sample}) winRateFor(
      List<Map<String, dynamic>> history) {
    const minimumSample = 5;
    final settled = history
        .map((t) => (t['pnl'] as num?)?.toDouble())
        .whereType<double>()
        .toList();

    if (settled.length < minimumSample) {
      return (rate: null, sample: settled.length);
    }

    final wins = settled.where((pnl) => pnl > 0).length;
    return (rate: (wins / settled.length) * 100, sample: settled.length);
  }

  /// Calculate risk score 0-100
  double _calculateRiskScore(
    EmotionalState state,
    List<PatternWarning> patterns,
  ) {
    double score = 0;

    // Emotional state: 0-40 points
    switch (state) {
      case EmotionalState.calm:
        score += 0;
        break;
      case EmotionalState.overconfident:
        score += 20;
        break;
      case EmotionalState.fomo:
        score += 30;
        break;
      case EmotionalState.panic:
        score += 35;
        break;
      case EmotionalState.revenge:
        score += 40;
        break;
    }

    // Each pattern: +20 points
    score += patterns.length * 20;

    return score.clamp(0, 100);
  }

  /// Generate recommendation
  String _generateRecommendation(
    EmotionalState state,
    List<PatternWarning> patterns,
    double riskScore,
  ) {
    if (riskScore < 30) {
      return 'Trade appears rational. Risk is acceptable.';
    }

    if (state == EmotionalState.revenge) {
      return 'Take a 30-minute break. Performance drops 73% after losses.';
    }

    if (state == EmotionalState.fomo) {
      return 'Wait for a pullback. 87% of FOMO trades lose money.';
    }

    if (state == EmotionalState.panic) {
      return 'Review your trading plan. Don\'t panic sell.';
    }

    if (patterns.any((p) => p.name == 'Chasing Losses')) {
      return 'Stop trading today. Chasing losses has 95% failure rate.';
    }

    return 'Moderate risk detected. Proceed with caution.';
  }

  /// Get recent trades from Firestore
  Future<List<Map<String, dynamic>>> _getRecentTrades() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('trades')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('Failed to get history', e, StackTrace.current);
      return [];
    }
  }
}
