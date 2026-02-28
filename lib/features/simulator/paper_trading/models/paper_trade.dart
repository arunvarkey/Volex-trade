// lib/features/simulator/paper_trading/models/paper_trade.dart
class PaperTrade {
  final String id;
  final String symbol;
  final double entryPrice;
  final double exitPrice;
  final double size;
  final double pnl;
  final double pnlPercent;
  final DateTime entryTime;
  final DateTime exitTime;
  final String exitReason; // 'signal', 'stop_loss', 'take_profit'

  PaperTrade({
    required this.id,
    required this.symbol,
    required this.entryPrice,
    required this.exitPrice,
    required this.size,
    required this.pnl,
    required this.pnlPercent,
    required this.entryTime,
    required this.exitTime,
    required this.exitReason,
  });

  Duration get duration => exitTime.difference(entryTime);
  bool get isWin => pnl > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'size': size,
        'pnl': pnl,
        'pnlPercent': pnlPercent,
        'entryTime': entryTime.toIso8601String(),
        'exitTime': exitTime.toIso8601String(),
        'exitReason': exitReason,
      };

  factory PaperTrade.fromJson(Map<String, dynamic> json) {
    return PaperTrade(
      id: json['id'],
      symbol: json['symbol'],
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num).toDouble(),
      size: (json['size'] as num).toDouble(),
      pnl: (json['pnl'] as num).toDouble(),
      pnlPercent: (json['pnlPercent'] as num).toDouble(),
      entryTime: DateTime.parse(json['entryTime']),
      exitTime: DateTime.parse(json['exitTime']),
      exitReason: json['exitReason'],
    );
  }
}
