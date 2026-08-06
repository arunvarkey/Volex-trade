import 'dart:async';
import 'dart:math';

import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/data/historical_repository.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/position.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/engine/strategy/strategy_recommendation.dart';

/// Turns an activated strategy into a real paper-trading loop.
///
/// While one or more strategies are active in [ExecutionManager], this
/// periodically evaluates each on realistic candles and opens/closes a single
/// paper position per strategy — so "Deploy"/▶ actually trades (positions,
/// P&L, stop-loss/take-profit exits) instead of only flipping a flag.
///
/// Because the offline data source is static synthetic candles, the loop keeps
/// its own gently-walking mark price (tethered to the latest close) so the
/// simulated market moves — that's what lets stop-loss/take-profit and P&L
/// actually breathe. On real market data this walk stays close to the truth.
///
/// Safe by construction: one position per strategy, a small fixed fraction of
/// the paper balance per trade, a cooldown after each exit, and every step
/// wrapped so a bad evaluation can never crash the app.
class StrategyRunner {
  final ExecutionManager _execution;
  final StrategyEngine _engine;
  final HistoricalRepository _history;

  /// The symbol activated strategies paper-trade on (MVP: a single market).
  static const String symbol = 'BTCUSDT';
  static const Duration _interval = Duration(seconds: 20);
  static const Duration _cooldown = Duration(seconds: 60);
  static const double _riskFraction = 0.05; // 5% of balance per position

  final Random _rng = Random();
  Timer? _timer;
  bool _evaluating = false;

  /// Simulated live mark price for the paper market.
  double? _mark;

  /// Stop-loss / take-profit per strategy with an open position.
  final Map<String, _Bracket> _brackets = {};

  /// Don't immediately re-enter right after an exit.
  final Map<String, DateTime> _cooldownUntil = {};

  StrategyRunner(this._execution, this._engine, this._history) {
    _execution.addListener(_sync);
  }

  bool get isRunning => _timer != null;

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

  /// Advance the simulated mark price: a small random walk gently tethered to
  /// the latest real/synthetic close so it wanders but never runs away.
  double _nextMark(double base) {
    _mark ??= base;
    final drift = (base - _mark!) * 0.03; // pull back toward the close
    final noise = (_rng.nextDouble() - 0.5) * base * 0.004; // ±0.2%
    var next = _mark! + drift + noise;
    if (next <= 0) next = base;
    _mark = next;
    return next;
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

      final price = _nextMark(candles.last.close);
      // Refresh unrealized P&L on open positions against the moving mark.
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

        StrategyRecommendation? rec;
        try {
          final recs = await strat.analyze(symbol, candles);
          for (final r in recs) {
            if (!r.shouldTrade) continue;
            if (rec == null || r.confidence > rec.confidence) rec = r;
          }
        } catch (e) {
          AppLogger.error('StrategyRunner: analyze failed for $id: $e');
          continue;
        }

        final open =
            _execution.openPositions.where((p) => p.strategyId == id).toList();

        try {
          if (open.isEmpty) {
            _brackets.remove(id);
            _maybeEnter(id, rec, price);
          } else {
            _maybeExit(id, open.first, rec, price);
          }
        } catch (e) {
          AppLogger.error('StrategyRunner: trade skipped for $id: $e');
        }
      }
    } catch (e) {
      AppLogger.error('StrategyRunner: evaluation error: $e');
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _maybeEnter(
      String id, StrategyRecommendation? rec, double price) async {
    if (rec == null) return;
    final cd = _cooldownUntil[id];
    if (cd != null && DateTime.now().isBefore(cd)) return;

    final qty = _sizeFor(price);
    if (qty <= 0) return;

    await _execution.placeMarketOrder(
      symbol: symbol,
      side: rec.side,
      quantity: qty,
      currentPrice: price,
      stopLoss: rec.stopLoss,
      takeProfit: rec.takeProfit,
      strategyId: id,
    );
    _brackets[id] = _Bracket(rec.stopLoss, rec.takeProfit);
    AppLogger.info(
        'StrategyRunner: $id opened ${rec.side.name} $symbol @ ${price.toStringAsFixed(2)}');
  }

  Future<void> _maybeExit(String id, Position pos, StrategyRecommendation? rec,
      double price) async {
    final isLong = pos.side == OrderSide.buy;
    final br = _brackets[id];

    // 1) Stop-loss / take-profit auto-exit.
    if (br != null) {
      final hitStop = br.stopLoss != null &&
          (isLong ? price <= br.stopLoss! : price >= br.stopLoss!);
      final hitTake = br.takeProfit != null &&
          (isLong ? price >= br.takeProfit! : price <= br.takeProfit!);
      if (hitStop || hitTake) {
        await _close(id, pos, price);
        AppLogger.info(
            'StrategyRunner: $id ${hitStop ? 'stop-loss' : 'take-profit'} exit $symbol @ ${price.toStringAsFixed(2)}');
        return;
      }
    }

    // 2) Exit on an opposite-side signal.
    if (rec != null && rec.side != pos.side) {
      await _close(id, pos, price);
      AppLogger.info(
          'StrategyRunner: $id signal-flip exit $symbol @ ${price.toStringAsFixed(2)}');
    }
  }

  Future<void> _close(String id, Position pos, double price) async {
    // Offsetting market order (ExecutionManager.closeOrder omits the required
    // currentPrice, so we close directly).
    await _execution.placeMarketOrder(
      symbol: pos.symbol,
      side: pos.side == OrderSide.buy ? OrderSide.sell : OrderSide.buy,
      quantity: pos.quantity,
      currentPrice: price,
      strategyId: id,
    );
    _brackets.remove(id);
    _cooldownUntil[id] = DateTime.now().add(_cooldown);
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

class _Bracket {
  final double? stopLoss;
  final double? takeProfit;
  const _Bracket(this.stopLoss, this.takeProfit);
}
