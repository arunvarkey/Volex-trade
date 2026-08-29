import 'package:volex_terminal/domain/order.dart';

class TradeSignal {
  final String id;
  final String symbol;
  final OrderSide side;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  final String reasoning;
  final String? aiWarning;
  final double confidence;
  final String strategyName;
  final DateTime timestamp;
  final DateTime expiresAt;

  /// True when the strategy actually fired an actionable signal; false when
  /// this is only the strongest current *setup* surfaced for the watchlist
  /// (no confirmed trigger yet). Keeps the feed honest about what's a real
  /// call vs. "one to watch".
  final bool isActionable;

  TradeSignal({
    required this.id,
    required this.symbol,
    required this.side,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.reasoning,
    this.aiWarning,
    required this.confidence,
    required this.strategyName,
    required this.timestamp,
    required this.expiresAt,
    this.isActionable = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.toString(),
        'entry_price': entryPrice,
        'stop_loss': stopLoss,
        'take_profit': takeProfit,
        'reasoning': reasoning,
        'ai_warning': aiWarning,
        'confidence': confidence,
        'strategy_name': strategyName,
        'timestamp': timestamp.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_actionable': isActionable,
      };

  factory TradeSignal.fromJson(Map<String, dynamic> json) => TradeSignal(
        id: json['id'],
        symbol: json['symbol'],
        side: json['side'] == 'OrderSide.buy' ? OrderSide.buy : OrderSide.sell,
        entryPrice: json['entry_price'],
        stopLoss: json['stop_loss'],
        takeProfit: json['take_profit'],
        reasoning: json['reasoning'],
        aiWarning: json['ai_warning'],
        confidence: json['confidence'],
        strategyName: json['strategy_name'],
        timestamp: DateTime.parse(json['timestamp']),
        expiresAt: DateTime.parse(json['expires_at']),
        isActionable: json['is_actionable'] as bool? ?? true,
      );

  String toShareableText() {
    final emoji = side == OrderSide.buy ? '🟢' : '🔴';
    final action = side == OrderSide.buy ? 'BUY' : 'SELL';

    return '''
$emoji Volex Signal: $action $symbol

📊 Entry: \$${entryPrice.toStringAsFixed(2)}
🛡️ Stop Loss: \$${stopLoss.toStringAsFixed(2)}
🎯 Take Profit: \$${takeProfit.toStringAsFixed(2)}

💡 Strategy: $strategyName
⭐ Confidence: ${confidence.toStringAsFixed(0)}%

📝 $reasoning

${aiWarning != null ? '⚠️ AI Warning: $aiWarning\n' : ''}
⏰ Valid for ${timeRemaining.inMinutes} minutes

Simulated signal from Volex Terminal, a paper-trading app. Not financial advice.
https://play.google.com/store/apps/details?id=com.antigravity.volextrade
''';
  }
}
