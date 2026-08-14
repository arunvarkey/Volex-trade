import 'package:intl/intl.dart';

final NumberFormat _large = NumberFormat('#,##0.00');
final NumberFormat _mid = NumberFormat('0.000');
final NumberFormat _small = NumberFormat('0.00000');

/// Formats a price with precision appropriate to its magnitude
/// (68,895.00 / 3.142 / 0.12345) — the way trading terminals do.
String formatPrice(double price) {
  if (price >= 100) return _large.format(price);
  if (price >= 1) return _mid.format(price);
  return _small.format(price);
}

/// "BTCUSDT" -> "BTC"
String baseAsset(String symbol) =>
    symbol.endsWith('USDT') ? symbol.substring(0, symbol.length - 4) : symbol;

/// Compact quote volume, e.g. "$1.2B", "$845M".
String formatQuoteVolume(double v) {
  if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
  if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(0)}M';
  if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
  return '\$${v.toStringAsFixed(0)}';
}
