import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vx_colors.dart';
import 'vx_typography.dart';

/// The Volex mark: a V whose right arm rises into an arrow.
///
/// It reads as the letter and as a recovery on a chart at the same time, which
/// is what the product is. Drawn as vector geometry rather than shipped as a
/// raster asset so it stays sharp at any size, costs nothing in the APK, and
/// cannot drift out of sync with the launcher icon — both are the same shape,
/// in the same brand colours.
class VxLogoMark extends StatelessWidget {
  final double size;

  /// Colour of the V itself. Defaults to the brand blue.
  final Color? color;

  /// Colour of the arrow tip. Defaults to the gain green, which is the only
  /// place the mark carries a second colour.
  final Color? tipColor;

  const VxLogoMark({super.key, this.size = 96, this.color, this.tipColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // Decorative on its own: [VxLogo] supplies the accessible name for the
      // mark and wordmark together, so painting it here adds nothing to
      // announce.
      child: CustomPaint(
        painter: _VxLogoPainter(
          color: color ?? VxColors.neonCyan,
          tipColor: tipColor ?? VxColors.positive,
        ),
      ),
    );
  }
}

class _VxLogoPainter extends CustomPainter {
  final Color color;
  final Color tipColor;

  const _VxLogoPainter({required this.color, required this.tipColor});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100.0;
    final w = 9.5 * u;

    // Same coordinates as the launcher icon generator, so the two marks are
    // identical shapes at different scales.
    final a = Offset(24 * u, 26 * u);
    final v = Offset(48 * u, 72 * u);
    final tip = Offset(82 * u, 20 * u);

    final ang = math.atan2(tip.dy - v.dy, tip.dx - v.dx);
    final head = 15 * u;
    final stop = Offset(
      tip.dx - math.cos(ang) * head * 0.80,
      tip.dy - math.sin(ang) * head * 0.80,
    );

    final stroke = Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(Path()..moveTo(a.dx, a.dy)..lineTo(v.dx, v.dy)..lineTo(stop.dx, stop.dy), stroke);

    final back = Offset(
      tip.dx - math.cos(ang) * head,
      tip.dy - math.sin(ang) * head,
    );
    final perp = ang + math.pi / 2;
    final half = head * 0.55;

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(back.dx + math.cos(perp) * half, back.dy + math.sin(perp) * half)
        ..lineTo(back.dx - math.cos(perp) * half, back.dy - math.sin(perp) * half)
        ..close(),
      Paint()
        ..color = tipColor
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _VxLogoPainter old) =>
      old.color != color || old.tipColor != tipColor;
}

/// The mark with the product name beneath it — the splash and any
/// full-screen branding moment.
class VxLogo extends StatelessWidget {
  final double markSize;
  final bool showTagline;

  const VxLogo({super.key, this.markSize = 88, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Volex Terminal',
      // The name is already announced by this label, so the painted mark and
      // the wordmark below it must not be read out a second time.
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VxLogoMark(size: markSize),
          SizedBox(height: markSize * 0.22),
          Text(
            'Volex',
            style: VxTypography.hero.copyWith(
              fontSize: markSize * 0.42,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          if (showTagline) ...[
            SizedBox(height: markSize * 0.10),
            Text(
              'Practice trading · Virtual money',
              style: VxTypography.bodySmall.copyWith(
                color: VxColors.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
