import 'package:volex_terminal/ui/design_system/vx_format.dart';

/// Market-ticker formatting helpers.
///
/// These now delegate to [VxFormat], which is the app-wide standard. The
/// logic originated here and was correct; the problem was that it was only
/// reachable from the ticker widgets, so the rest of the app grew its own
/// ad-hoc `toStringAsFixed` calls and the two drifted apart.
///
/// Kept as thin wrappers rather than deleted because the call sites read
/// well and renaming them across the ticker would be churn for no gain.

/// Formats a price with precision appropriate to its magnitude
/// (68,895.00 / 3.142 / 0.12345) — the way trading terminals do.
String formatPrice(double price) => VxFormat.price(price);

/// "BTCUSDT" -> "BTC"
String baseAsset(String symbol) =>
    symbol.endsWith('USDT') ? symbol.substring(0, symbol.length - 4) : symbol;

/// Compact quote volume, e.g. "$1.2B", "$845M".
String formatQuoteVolume(double v) => VxFormat.compactMoney(v);
