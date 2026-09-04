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
      child: _glyph(),
    );
  }

  /// The mark inside the badge.
  ///
  /// The majors get their actual symbol drawn as vector paths — Ethereum's
  /// octahedron, Solana's three bars, BNB's diamond cluster, Bitcoin's
  /// struck-through B. They're plain geometry, so there's no image asset to
  /// bundle and nothing to fetch at runtime. Everything else falls back to the
  /// ticker text, which is what every coin showed before.
  Widget _glyph() {
    final painter = switch (_base) {
      'BTC' => const _BtcGlyph(),
      'ETH' => const _EthGlyph(),
      'SOL' => const _SolGlyph(),
      'BNB' => const _BnbGlyph(),
      _ => null,
    };

    if (painter != null) {
      return SizedBox(
        width: size * 0.52,
        height: size * 0.52,
        child: CustomPaint(painter: painter),
      );
    }

    return FittedBox(
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
    );
  }
}

/// Shared plumbing for the vector coin marks: all draw in white on the badge's
/// brand-coloured disc, and none of them depend on external state, so none
/// ever need to repaint.
abstract class _CoinGlyph extends CustomPainter {
  const _CoinGlyph();

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  Paint get _fill => Paint()
    ..color = Colors.white
    ..isAntiAlias = true;
}

/// Ethereum's octahedron: an upper solid half and a lower open half.
class _EthGlyph extends _CoinGlyph {
  const _EthGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    // Upper body, down to the waist at 58% height.
    final top = Path()
      ..moveTo(mid, 0)
      ..lineTo(w * 0.94, h * 0.55)
      ..lineTo(mid, h * 0.74)
      ..lineTo(w * 0.06, h * 0.55)
      ..close();
    canvas.drawPath(top, _fill);

    // Lower point, drawn slightly dimmer so the waist edge reads.
    final bottom = Path()
      ..moveTo(mid, h * 0.80)
      ..lineTo(w * 0.94, h * 0.62)
      ..lineTo(mid, h)
      ..lineTo(w * 0.06, h * 0.62)
      ..close();
    canvas.drawPath(bottom, _fill..color = Colors.white.withValues(alpha: 0.75));
  }
}

/// Solana's three slanted bars.
class _SolGlyph extends _CoinGlyph {
  const _SolGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bar = h * 0.2;
    final skew = w * 0.18;
    final paint = _fill;

    void slant(double top, bool leanRight) {
      final path = Path();
      if (leanRight) {
        path
          ..moveTo(skew, top)
          ..lineTo(w, top)
          ..lineTo(w - skew, top + bar)
          ..lineTo(0, top + bar);
      } else {
        path
          ..moveTo(0, top)
          ..lineTo(w - skew, top)
          ..lineTo(w, top + bar)
          ..lineTo(skew, top + bar);
      }
      canvas.drawPath(path..close(), paint);
    }

    slant(0, true);
    slant(h * 0.4, false);
    slant(h * 0.8, true);
  }
}

/// BNB's cluster: four small diamonds around a central one.
class _BnbGlyph extends _CoinGlyph {
  const _BnbGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = _fill;

    void diamond(double cx, double cy, double r) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close(),
        paint,
      );
    }

    final small = w * 0.19;
    diamond(w / 2, h * 0.14, small); // top
    diamond(w * 0.14, h / 2, small); // left
    diamond(w * 0.86, h / 2, small); // right
    diamond(w / 2, h * 0.86, small); // bottom
    diamond(w / 2, h / 2, w * 0.21); // centre
  }
}

/// Bitcoin's B with the two vertical strokes through it.
class _BtcGlyph extends _CoinGlyph {
  const _BtcGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = _fill;

    // The two strokes that run above and below the letter.
    final strokeWidth = w * 0.11;
    final strokeHeight = h * 0.16;
    for (final x in [w * 0.34, w * 0.56]) {
      canvas.drawRect(
          Rect.fromLTWH(x, 0, strokeWidth, strokeHeight + h * 0.06), paint);
      canvas.drawRect(
          Rect.fromLTWH(x, h - strokeHeight - h * 0.06, strokeWidth,
              strokeHeight + h * 0.06),
          paint);
    }

    // The letter itself, laid out to the badge's size rather than a font size
    // so it scales with the icon.
    final letter = TextPainter(
      text: TextSpan(
        text: 'B',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: h * 0.92,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final scale = (h * 0.78) / letter.height;
    canvas.save();
    canvas.translate(
      (w - letter.width * scale) / 2,
      (h - letter.height * scale) / 2,
    );
    canvas.scale(scale);
    letter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
