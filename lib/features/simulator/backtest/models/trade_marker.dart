// lib/engine/backtest/models/trade_marker.dart
import 'package:equatable/equatable.dart';

enum TradeType { entry, exit, stopLoss, takeProfit }

class TradeMarker extends Equatable {
  final DateTime timestamp;
  final double price;
  final TradeType type;
  final double? pnl;
  final double? pnlPercent;
  final String? reason;

  const TradeMarker({
    required this.timestamp,
    required this.price,
    required this.type,
    this.pnl,
    this.pnlPercent,
    this.reason,
  });

  @override
  List<Object?> get props => [timestamp, price, type, pnl, pnlPercent, reason];
}
