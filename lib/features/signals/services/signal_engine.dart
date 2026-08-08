import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/features/ai_guardian/services/ai_guardian_service.dart';

import 'package:volex_terminal/features/signals/models/trade_signal.dart';
import 'package:volex_terminal/core/app_logger.dart';

import 'package:volex_terminal/data/i_market_data_repository.dart';

class SignalEngine {
  final StrategyEngine _strategyEngine;
  final AIGuardianService _aiGuardian;
  final IMarketDataRepository _marketData;
  final _signalsController = StreamController<TradeSignal>.broadcast();

  Stream<TradeSignal> get signalStream => _signalsController.stream;

  // Retain recently generated signals so a screen opened *after* generation
  // (broadcast streams don't replay) can seed itself instead of showing an
  // endless "Scanning markets…" spinner.
  final List<TradeSignal> _recent = [];
  List<TradeSignal> get recentSignals => List.unmodifiable(_recent);

  bool _hasScanned = false;
  bool get hasScanned => _hasScanned;

  /// Runs a single scan on demand (used by the feed to force a refresh).
  Future<void> scanNow() => _generateSignals();

  SignalEngine({
    required StrategyEngine strategyEngine,
    required AIGuardianService aiGuardian,
    required IMarketDataRepository marketData,
  })  : _strategyEngine = strategyEngine,
        _aiGuardian = aiGuardian,
        _marketData = marketData;

  /// Start generating signals
  Future<void> startGenerating() async {
    AppLogger.info('🎯 SignalEngine: Started generating signals');

    // Initial generation
    _generateSignals();

    // Enforce 60s minimum scan interval
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _generateSignals();
    });
  }

  Future<void> _generateSignals() async {
    // For MVP, we watch a fixed set of high-volume pairs
    final watchlist = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'BNBUSDT'];

    for (final symbol in watchlist) {
      try {
        // 1. Fetch 500 candles of history for analysis warmth
        // Defaulting to 1H for reliable signals
        final history = await _marketData.fetchHistory(
          symbol: symbol,
          interval: '1h',
          limit: 500,
        );

        if (history.isEmpty) continue;

        // 2. Get strategy recommendation
        final recommendations =
            await _strategyEngine.analyzeSymbol(symbol, history);

        // Prefer actionable (shouldTrade) recommendations; if none fire this
        // scan, still surface the single strongest recommendation so the feed
        // always shows current opportunities instead of staying empty.
        final tradeable =
            recommendations.where((r) => r.shouldTrade).toList();
        final toEmit = tradeable.isNotEmpty
            ? tradeable
            : (recommendations.isEmpty
                ? recommendations
                : [
                    recommendations.reduce(
                        (a, b) => a.confidence >= b.confidence ? a : b)
                  ]);

        for (final rec in toEmit) {

          // Construct a mock order for analysis
          final mockOrder = Order(
            id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
            symbol: symbol,
            type: OrderType.market,
            side: rec.side,
            quantity: rec.suggestedQuantity,
            price: rec.entryPrice,
            timestamp: DateTime.now(),
            status: OrderStatus.open,
          );

          // Get AI Guardian analysis
          final aiAnalysis = await _aiGuardian.analyzeTradeIntent(mockOrder);

          // Create signal
          final signal = TradeSignal(
            id: _generateSignalId(),
            symbol: symbol,
            side: rec.side,
            entryPrice: rec.entryPrice,
            stopLoss: rec.stopLoss ?? rec.entryPrice * 0.98,
            takeProfit: rec.takeProfit ?? rec.entryPrice * 1.05,
            reasoning: rec.reasoning ?? 'Strategy detected opportunity',
            // Use 'recommendation' as the warning text if shouldWarn is true
            aiWarning: aiAnalysis.shouldWarn ? aiAnalysis.recommendation : null,
            confidence: rec.confidence,
            strategyName: rec.strategyName,
            timestamp: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            // Honest: a confirmed trigger (shouldTrade) vs. the strongest
            // current setup surfaced for the watchlist.
            isActionable: rec.shouldTrade,
          );

          // Retain + emit
          _recent.insert(0, signal);
          if (_recent.length > 50) _recent.removeRange(50, _recent.length);
          _signalsController.add(signal);

          // Save to history (fire and forget)
          _saveSignal(signal);

          AppLogger.info(
              '🎯 Signal Generated: ${signal.side} ${signal.symbol} @ ${signal.entryPrice}');
        }
      } catch (e) {
        AppLogger.error('Error generating signal for $symbol: $e');
      }
    }
    _hasScanned = true;
  }

  String _generateSignalId() {
    return 'sig_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveSignal(TradeSignal signal) async {
    // Firebase-free run (no google-services.json / web preview): skip cloud
    // persistence instead of throwing on FirebaseAuth.instance every scan.
    if (Firebase.apps.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save to Firestore for history
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('signals')
          .doc(signal.id)
          .set(signal.toJson());
    } catch (e) {
      AppLogger.error('Failed to save signal to firestore: $e');
    }
  }

  void dispose() {
    _signalsController.close();
  }
}
