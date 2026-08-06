import 'dart:async';

import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/data/historical_repository.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/engine/strategy/strategy_recommendation.dart';

/// Turns an activated strategy into a real paper-trading loop.
///
/// While one or more strategies are active in [ExecutionManager], this
/// periodically evaluates each on realistic candles and opens/closes a single
/// paper position per strategy on its own signals — so "Deploy"/▶ actually
/// trades (positions, P&L) instead of only flipping a running flag.
///
/// Safe by construction: one position per strategy at a time, a small fixed
/// fraction of the paper balance per trade, and every step wrapped so a bad
/// evaluation can never crash the app.
class StrategyRunner {
  final ExecutionManager _execution;
  final StrategyEngine _engine;
  final HistoricalRepository _history;

  /// The symbol activated strategies paper-trade on (MVP: a single market).
  static const String symbol = 'BTCUSDT';
  static const Duration _interval = Duration(seconds: 20);
  static const double _riskFraction = 0.05; // 5% of balance per position

  Timer? _timer;
  bool _evaluating = false;

  StrategyRunner(this._execution, this._engine, this._history) {
    _execution.addListener(_sync);
  }

  bool get isRunning => _timer != null;

  /// Start/stop the loop as strategies are activated/deactivated.
  void _sync() {
    final active = _execution.activeStrategyIds.isNotEmpty;
    if (active && _timer == null) {
      AppLogger.info('StrategyRunner: starting paper-trading loop');
      _timer = Timer.periodic(_interval, (_) => _evaluate());
      _evaluate(); // immediate first pass
    } else if (!active && _timer != null) {
      AppLogger.info('StrategyRunner: no active strategies — stopping loop');
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _evaluate() async {
    if (_evaluating) return;
    _evaluating = true;
    try {
      final activeIds = _execution.activeStrategyIds;
      if (activeIds.isEmpty) return;

      final candles = await _history.fetchHistory(
          symbol: symbol, interval: '1h', limit: 200);
      if (candles.length < 30) return;
      final price = candles.last.close;

      // Refresh unrealized P&L on any open positions against the latest price.
      _execution.updateUnrealizedPnl(price);

      final strategies = _engine.allStrategies;
      for (final id in activeIds) {
        Strategy? strat;
        for (final s in strategies) {
          if (s.id == id) {
            strat = s;
            break;
          }
        }
        if (strat == null) continue;

        List<StrategyRecommendation> recs;
        try {
          recs = await strat.analyze(symbol, candles);
        } catch (e) {
          AppLogger.error('StrategyRunner: analyze failed for $id: $e');
          continue;
        }

        // Strongest actionable recommendation this tick, if any.
        StrategyRecommendation? rec;
        for (final r in recs) {
          if (!r.shouldTrade) continue;
          if (rec == null || r.confidence > rec.confidence) rec = r;
        }

        final open =
            _execution.openPositions.where((p) => p.strategyId == id).toList();

        try {
          if (open.isEmpty) {
            // No position: open one on a signal.
            if (rec != null) {
              final qty = _sizeFor(price);
              if (qty > 0) {
                await _execution.placeMarketOrder(
                  symbol: symbol,
                  side: rec.side,
                  quantity: qty,
                  currentPrice: price,
                  stopLoss: rec.stopLoss,
                  takeProfit: rec.takeProfit,
                  strategyId: id,
                );
                AppLogger.info(
                    'StrategyRunner: $id opened ${rec.side.name} $symbol @ $price');
              }
            }
          } else {
            // Have a position: close it on an opposite-side signal.
            final pos = open.first;
            if (rec != null && rec.side != pos.side) {
              await _execution.placeMarketOrder(
                symbol: pos.symbol,
                side: pos.side == OrderSide.buy
                    ? OrderSide.sell
                    : OrderSide.buy,
                quantity: pos.quantity,
                currentPrice: price,
                strategyId: id,
              );
              AppLogger.info('StrategyRunner: $id closed $symbol @ $price');
            }
          }
        } catch (e) {
          // Risk rejection / execution error for this strategy — skip it.
          AppLogger.error('StrategyRunner: trade skipped for $id: $e');
        }
      }
    } catch (e) {
      AppLogger.error('StrategyRunner: evaluation error: $e');
    } finally {
      _evaluating = false;
    }
  }

  double _sizeFor(double price) {
    if (price <= 0) return 0;
    final notional = _execution.balance * _riskFraction;
    final qty = notional / price;
    return double.parse(qty.toStringAsFixed(6));
  }

  void dispose() {
    _execution.removeListener(_sync);
    _timer?.cancel();
    _timer = null;
  }
}
