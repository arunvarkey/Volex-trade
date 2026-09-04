import 'dart:async';
import 'dart:math';

import 'package:volex_terminal/core/app_logger.dart';
import 'package:volex_terminal/data/historical_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/domain/position.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/engine/strategy/strategy_recommendation.dart';

/// Turns an activated strategy into a real paper-trading loop across several
/// markets.
///
/// While one or more strategies are active in [ExecutionManager], this
/// periodically evaluates each strategy on every watchlist symbol and manages
/// one paper position per (strategy, symbol): opens on a signal, and closes on
/// stop-loss, take-profit, or an opposite-side signal — so "Deploy"/▶ actually
/// trades (positions, P&L, risk exits) instead of only flipping a flag.
///
/// Each symbol keeps its own gently random-walking mark price (tethered to its
/// latest close) so the simulated markets move and stop/take exits can fire.
///
/// Safe by construction: one position per (strategy, symbol), a small fixed
/// fraction of the paper balance per trade, a cooldown after each exit, and
/// every step wrapped so a bad evaluation can never crash the app.
class StrategyRunner {
  final ExecutionManager _execution;
  final StrategyEngine _engine;
  final HistoricalRepository _history;

  /// The markets activated strategies paper-trade across.
  static const List<String> symbols = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'BNBUSDT',
  ];
  static const Duration _interval = Duration(seconds: 20);
  static const Duration _cooldown = Duration(seconds: 60);
  static const double _riskFraction = 0.03; // 3% of balance per position

  final Random _rng = Random();
  Timer? _timer;
  bool _evaluating = false;

  /// Simulated live mark price per symbol.
  final Map<String, double> _marks = {};

  /// Stop-loss / take-profit per '<strategyId>|<symbol>' with an open position.
  final Map<String, _Bracket> _brackets = {};

  /// Don't immediately re-enter a '<strategyId>|<symbol>' right after an exit.
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

  /// Advance a symbol's simulated mark: a small random walk gently tethered to
  /// the latest close so it wanders but never runs away.
  double _nextMark(String symbol, double base) {
    final current = _marks[symbol] ?? base;
    final drift = (base - current) * 0.03; // pull back toward the close
    final noise = (_rng.nextDouble() - 0.5) * base * 0.004; // ±0.2%
    var next = current + drift + noise;
    if (next <= 0) next = base;
    _marks[symbol] = next;
    return next;
  }

  Future<void> _evaluate() async {
    if (_evaluating) return;
    _evaluating = true;
    try {
      final activeIds = _execution.activeStrategyIds;
      if (activeIds.isEmpty) return;
      final strategies = _engine.allStrategies;

      for (final sym in symbols) {
        List<Candle> candles;
        try {
          candles = await _history.fetchHistory(
              symbol: sym, interval: '1h', limit: 200);
        } catch (e) {
          AppLogger.error('StrategyRunner: history failed for $sym: $e');
          continue;
        }
        if (candles.length < 30) continue;

        final price = _nextMark(sym, candles.last.close);
        _execution.updateUnrealizedPnlForSymbol(sym, price);

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
            final recs = await strat.analyze(sym, candles);
            for (final r in recs) {
              if (!r.shouldTrade) continue;
              if (rec == null || r.confidence > rec.confidence) rec = r;
            }
          } catch (e) {
            AppLogger.error('StrategyRunner: analyze failed for $id/$sym: $e');
            continue;
          }

          final key = '$id|$sym';
          final open = _execution.openPositions
              .where((p) => p.strategyId == id && p.symbol == sym)
              .toList();

          try {
            if (open.isEmpty) {
              _brackets.remove(key);
              await _maybeEnter(key, sym, id, rec, price);
            } else {
              await _maybeExit(key, id, open.first, rec, price);
            }
          } catch (e) {
            AppLogger.error('StrategyRunner: trade skipped for $key: $e');
          }
        }
      }
    } catch (e) {
      AppLogger.error('StrategyRunner: evaluation error: $e');
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _maybeEnter(String key, String sym, String id,
      StrategyRecommendation? rec, double price) async {
    if (rec == null) return;
    final cd = _cooldownUntil[key];
    if (cd != null && DateTime.now().isBefore(cd)) return;

    final qty = _sizeFor(price);
    if (qty <= 0) return;

    await _execution.placeMarketOrder(
      symbol: sym,
      side: rec.side,
      quantity: qty,
      currentPrice: price,
      stopLoss: rec.stopLoss,
      takeProfit: rec.takeProfit,
      strategyId: id,
    );
    _brackets[key] = _Bracket(rec.stopLoss, rec.takeProfit);
    AppLogger.info(
        'StrategyRunner: $id opened ${rec.side.name} $sym @ ${price.toStringAsFixed(2)}');
  }

  Future<void> _maybeExit(String key, String id, Position pos,
      StrategyRecommendation? rec, double price) async {
    final isLong = pos.side == OrderSide.buy;
    final br = _brackets[key];

    // 1) Stop-loss / take-profit auto-exit.
    if (br != null) {
      final hitStop = br.stopLoss != null &&
          (isLong ? price <= br.stopLoss! : price >= br.stopLoss!);
      final hitTake = br.takeProfit != null &&
          (isLong ? price >= br.takeProfit! : price <= br.takeProfit!);
      if (hitStop || hitTake) {
        await _close(key, id, pos, price);
        AppLogger.info(
            'StrategyRunner: $id ${hitStop ? 'stop-loss' : 'take-profit'} exit ${pos.symbol} @ ${price.toStringAsFixed(2)}');
        return;
      }
    }

    // 2) Exit on an opposite-side signal.
    if (rec != null && rec.side != pos.side) {
      await _close(key, id, pos, price);
      AppLogger.info(
          'StrategyRunner: $id signal-flip exit ${pos.symbol} @ ${price.toStringAsFixed(2)}');
    }
  }

  Future<void> _close(String key, String id, Position pos, double price) async {
    // Offsetting market order placed directly rather than via closeOrder,
    // because we already hold the live price for this symbol and closeOrder
    // would only back one out of the position's last-marked P&L.
    await _execution.placeMarketOrder(
      symbol: pos.symbol,
      side: pos.side == OrderSide.buy ? OrderSide.sell : OrderSide.buy,
      quantity: pos.quantity,
      currentPrice: price,
      strategyId: id,
      // Exiting is a reduction, so it is not blocked once the daily loss
      // limit trips the emergency stop. Without this a strategy's own
      // stop-loss exit would be refused exactly when it was needed.
      isReduction: true,
    );
    _brackets.remove(key);
    _cooldownUntil[key] = DateTime.now().add(_cooldown);
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
