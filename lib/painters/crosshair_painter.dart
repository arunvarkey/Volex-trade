import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../engine/chart_controller.dart';

class CrosshairPainter {
  static void paint(Canvas canvas, Size size, ChartController controller) {
    final offset = controller.crosshairOffset;
    if (offset == null) return;

    final paint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
        // ..pathEffect = PathEffect.dashPathEffect([4, 4], 0) // Not supported on Paint directly in standard Canvas kit?
        ;

    // 1. Draw Lines
    // Vertical
    canvas.drawLine(
        Offset(offset.dx, 0), Offset(offset.dx, size.height), paint);
    // Horizontal
    canvas.drawLine(Offset(0, offset.dy), Offset(size.width, offset.dy), paint);

    // 2. Draw Labels (Axis)

    // Price Label (Right Axis)
    final price = controller.yToPrice(offset.dy, size.height);
    final priceText = price.toStringAsFixed(2);

    _drawLabel(canvas, priceText, Offset(size.width - 60, offset.dy - 10),
        alignRight: true);

    // Time Label (Bottom Axis)
    // We need index -> time
    final index = controller.xToIndex(offset.dx);
    if (index >= 0 && index < controller.allCandles.length) {
      final candle = controller.allCandles[index];
      final timeStr = DateTime.fromMillisecondsSinceEpoch(candle.time * 1000)
          .toIso8601String()
          .split('T')
          .last
          .substring(0, 5); // HH:MM

      _drawLabel(canvas, timeStr, Offset(offset.dx, size.height - 20),
          alignRight: false);
    }
  }

  static void _drawLabel(Canvas canvas, String text, Offset position,
      {bool alignRight = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          backgroundColor: Colors.black.withValues(alpha: 0.7)),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();

    final drawOffset = alignRight
        ? Offset(position.dx - tp.width, position.dy)
        : Offset(position.dx - (tp.width / 2), position.dy);

    // Background Rect
    final rect = Rect.fromLTWH(
        drawOffset.dx - 2, drawOffset.dy - 2, tp.width + 4, tp.height + 4);
    canvas.drawRect(rect, Paint()..color = Colors.grey[800]!);

    tp.paint(canvas, drawOffset);
  }
}
