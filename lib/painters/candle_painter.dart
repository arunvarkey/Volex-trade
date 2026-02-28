import 'package:flutter/material.dart';

import '../engine/chart_controller.dart';

class CandlePainter {
  static final Paint _greenPaint = Paint()
    ..color = const Color(0xFF00F2A9) // Neon Green
    ..style = PaintingStyle.fill;

  static final Paint _redPaint = Paint()
    ..color = const Color(0xFFFF2E54) // Neon Red
    ..style = PaintingStyle.fill;

  static final Paint _wickPaint = Paint()..strokeWidth = 1.0;

  /// Renders the visible candles on the canvas.
  /// This must be allocation-free in the loop.
  static void paint(Canvas canvas, Size size, ChartController controller) {
    if (controller.allCandles.isEmpty) return;

    final candles = controller.allCandles;
    final startIndex = controller.startIndex;
    final endIndex = controller.endIndex;
    final candleWidth = controller.candleWidth;
    final gap = candleWidth * 0.1; // 10% gap
    final bodyWidth = candleWidth - gap;

    // Scale Logic: Map Price to Height (Simple MinMax for visible range)
    // In a real app, calculate min/max of VISIBLE range only.
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (int i = startIndex; i <= endIndex; i++) {
      final c = candles[i];
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }

    // Safety padding
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    final pixelPerPrice = size.height / priceRange;

    // Drawing Loop
    for (int i = startIndex; i <= endIndex; i++) {
      final candle = candles[i];
      final x = (i * candleWidth) - controller.scrollOffset;

      // Optimization: Don't draw if off-screen (Controller handles index, but safe check needed for partials)
      if (x + bodyWidth < 0 || x > size.width) continue;

      final isGreen = candle.isGreen;
      final currentPaint = isGreen ? _greenPaint : _redPaint;
      _wickPaint.color = currentPaint.color;

      // Y-Coordinates (Inverted: 0 is top)
      // canvas y = height - ((price - min) * scale)
      final openY = size.height - ((candle.open - minPrice) * pixelPerPrice);
      final closeY = size.height - ((candle.close - minPrice) * pixelPerPrice);
      final highY = size.height - ((candle.high - minPrice) * pixelPerPrice);
      final lowY = size.height - ((candle.low - minPrice) * pixelPerPrice);

      // Draw Wick
      canvas.drawLine(Offset(x + bodyWidth / 2, highY),
          Offset(x + bodyWidth / 2, lowY), _wickPaint);

      // Draw Body
      // Rect.fromLTRB is faster than fromPoints
      // If open == close, draw a thin line
      double top = openY < closeY ? openY : closeY; // visual top
      double bottom = openY > closeY ? openY : closeY; // visual bottom
      if ((bottom - top) < 1.0) bottom = top + 1.0;

      canvas.drawRect(
          Rect.fromLTRB(x, top, x + bodyWidth, bottom), currentPaint);
    }
  }
}
