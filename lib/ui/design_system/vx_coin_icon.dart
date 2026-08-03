import 'package:flutter/material.dart';

/// A consistent, professional coin badge used everywhere a coin is shown.
///
/// Renders a circular badge in the coin's real brand color with its ticker,
/// so markets, tickers, positions and signals all share one recognizable coin
/// identity (no remote logo fetch required).
class VxCoinIcon extends StatelessWidget {
  final String symbol;
  final double size;

  const VxCoinIcon(this.symbol, {super.key, this.size = 36});

  /// Base asset ticker, e.g. 'BTCUSDT' -> 'BTC', 'ETH/USD' -> 'ETH'.
  String get _base {
    var s = symbol.toUpperCase().replaceAll('/', '').replaceAll('-', '');
    for (final quote in const ['USDT', 'USDC', 'BUSD', 'USD', 'EUR', 'GBP']) {
      if (s.endsWith(quote) && s.length > quote.length) {
        s = s.substring(0, s.length - quote.length);
        break;
      }
    }
    return s;
  }

  static const Map<String, Color> _brand = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF),
    'BNB': Color(0xFFF3BA2F),
    'XRP': Color(0xFF4A90D9),
    'DOGE': Color(0xFFC2A633),
    'ADA': Color(0xFF0033AD),
    'AVAX': Color(0xFFE84142),
    'LINK': Color(0xFF2A5ADA),
    'MATIC': Color(0xFF8247E5),
    'POL': Color(0xFF8247E5),
    'DOT': Color(0xFFE6007A),
    'LTC': Color(0xFF345D9D),
    'TRX': Color(0xFFFF060A),
    'SHIB': Color(0xFFFFA409),
    'USDT': Color(0xFF26A17B),
    'USDC': Color(0xFF2775CA),
    'ATOM': Color(0xFF2E3148),
    'UNI': Color(0xFFFF007A),
    'ARB': Color(0xFF28A0F0),
    'OP': Color(0xFFFF0420),
    'APT': Color(0xFF00C2A8),
    'NEAR': Color(0xFF00EC97),
    'FIL': Color(0xFF0090FF),
    'ETC': Color(0xFF3AB83A),
    'BCH': Color(0xFF8DC351),
    'XLM': Color(0xFF14B6E7),
  };

  Color get _color {
    final b = _base;
    if (_brand.containsKey(b)) return _brand[b]!;
    // Deterministic fallback color from the ticker so every coin is stable.
    const hues = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    return hues[b.hashCode.abs() % hues.length];
  }

  String get _label {
    final b = _base;
    if (b.length <= 4) return b;
    return b.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            spreadRadius: -size * 0.06,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.12),
          child: Text(
            _label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.34,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
