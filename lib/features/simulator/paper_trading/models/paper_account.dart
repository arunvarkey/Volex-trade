// lib/features/simulator/paper_trading/models/paper_account.dart
import 'package:volex_terminal/domain/position.dart';
import 'paper_trade.dart';

class PaperAccount {
  final String id;
  final double initialEquity;
  final double currentEquity;
  final Position? currentPosition;
  final List<PaperTrade> tradeHistory;
  final DateTime createdAt;

  PaperAccount({
    required this.id,
    required this.initialEquity,
    required this.currentEquity,
    this.currentPosition,
    this.tradeHistory = const [],
    required this.createdAt,
  });

  double get totalPnl => currentEquity - initialEquity;
  double get totalReturnPercent =>
      ((currentEquity - initialEquity) / initialEquity) * 100;
  bool get hasOpenPosition => currentPosition != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'initialEquity': initialEquity,
        'currentEquity': currentEquity,
        'currentPosition': currentPosition?.toJson(),
        'tradeHistory': tradeHistory.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PaperAccount.fromJson(Map<String, dynamic> json) {
    return PaperAccount(
      id: json['id'],
      initialEquity: (json['initialEquity'] as num).toDouble(),
      currentEquity: (json['currentEquity'] as num).toDouble(),
      currentPosition: json['currentPosition'] != null
          ? Position.fromJson(
              Map<String, dynamic>.from(json['currentPosition']))
          : null,
      tradeHistory: (json['tradeHistory'] as List?)
              ?.map((t) => PaperTrade.fromJson(Map<String, dynamic>.from(t)))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
