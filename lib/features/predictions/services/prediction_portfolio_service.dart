import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/prediction_data.dart';
import '../models/prediction_models.dart';

/// Result of attempting to place a simulated event-market order.
class PredictionTradeResult {
  final bool ok;
  final String message;
  const PredictionTradeResult(this.ok, this.message);
}

/// Manages a user's simulated prediction-market portfolio: a virtual balance
/// and Yes/No positions. Self-contained singleton backed by SharedPreferences,
/// mirroring [AcademyProgressService] so it needs no DI wiring.
///
/// All money here is virtual — this is a risk-free simulator.
class PredictionPortfolioService extends ChangeNotifier {
  PredictionPortfolioService._();
  static final PredictionPortfolioService instance =
      PredictionPortfolioService._();

  static const String _balanceKey = 'prediction_balance_v1';
  static const String _positionsKey = 'prediction_positions_v1';
  static const double _startingBalance = 10000.0;

  double _balance = _startingBalance;
  final Map<String, PredictionPosition> _positions = {}; // keyed by pos.key
  bool _loaded = false;

  bool get isLoaded => _loaded;
  double get balance => _balance;
  List<PredictionPosition> get positions => _positions.values.toList();
  bool get hasPositions => _positions.isNotEmpty;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _balance = prefs.getDouble(_balanceKey) ?? _startingBalance;
      final raw = prefs.getStringList(_positionsKey) ?? const <String>[];
      _positions.clear();
      for (final s in raw) {
        try {
          final map = jsonDecode(s);
          if (map is Map<String, dynamic>) {
            final pos = PredictionPosition.fromJson(map);
            if (pos != null) _positions[pos.key] = pos;
          }
        } catch (_) {
          // Skip a malformed entry rather than failing the whole load.
        }
      }
    } catch (_) {
      _balance = _startingBalance;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  PredictionPosition? positionFor(String marketId, ContractSide side) =>
      _positions['$marketId::${side.name}'];

  /// Total current market value of all open positions (virtual $).
  double get positionsValue {
    double total = 0;
    for (final pos in _positions.values) {
      final market = PredictionData.marketById(pos.marketId);
      if (market != null) total += pos.currentValue(market);
    }
    return total;
  }

  /// Balance + open-position value (virtual $).
  double get netWorth => _balance + positionsValue;

  /// Total unrealised P/L across open positions (virtual $).
  double get totalPnl {
    double total = 0;
    for (final pos in _positions.values) {
      final market = PredictionData.marketById(pos.marketId);
      if (market != null) total += pos.pnl(market);
    }
    return total;
  }

  /// Buy [contracts] contracts on [side] of [market] at its current price.
  Future<PredictionTradeResult> buy(
    EventMarket market,
    ContractSide side,
    int contracts,
  ) async {
    await ensureLoaded();
    if (contracts <= 0) {
      return const PredictionTradeResult(false, 'Choose at least 1 contract.');
    }
    final priceCents = market.priceFor(side);
    final cost = contracts * priceCents / 100.0;
    if (cost > _balance) {
      return PredictionTradeResult(
        false,
        'Not enough balance. Need \$${cost.toStringAsFixed(2)}.',
      );
    }

    final key = '${market.id}::${side.name}';
    final existing = _positions[key];
    if (existing == null) {
      _positions[key] = PredictionPosition(
        marketId: market.id,
        side: side,
        contracts: contracts,
        avgPriceCents: priceCents,
      );
    } else {
      final totalContracts = existing.contracts + contracts;
      final blendedAvg = ((existing.avgPriceCents * existing.contracts) +
              (priceCents * contracts)) /
          totalContracts;
      _positions[key] = existing.copyWith(
        contracts: totalContracts,
        avgPriceCents: blendedAvg.round(),
      );
    }

    _balance -= cost;
    notifyListeners();
    await _persist();
    return PredictionTradeResult(
      true,
      'Bought $contracts ${side.name.toUpperCase()} @ $priceCents¢',
    );
  }

  /// Close a position at the market's current price, realising into balance.
  Future<PredictionTradeResult> close(EventMarket market, ContractSide side) async {
    await ensureLoaded();
    final key = '${market.id}::${side.name}';
    final pos = _positions[key];
    if (pos == null) {
      return const PredictionTradeResult(false, 'No position to close.');
    }
    final proceeds = pos.currentValue(market);
    _balance += proceeds;
    _positions.remove(key);
    notifyListeners();
    await _persist();
    return PredictionTradeResult(
      true,
      'Closed for \$${proceeds.toStringAsFixed(2)}',
    );
  }

  Future<void> resetPortfolio() async {
    _balance = _startingBalance;
    _positions.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_balanceKey, _balance);
      await prefs.setStringList(
        _positionsKey,
        _positions.values.map((p) => jsonEncode(p.toJson())).toList(),
      );
    } catch (_) {
      // Non-fatal: keep in-memory state for this session.
    }
  }
}
