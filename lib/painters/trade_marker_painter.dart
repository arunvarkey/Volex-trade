import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../ui/design_system/vx_colors.dart';

class TradeMarkerPainter {
  static void paint(Canvas canvas, Size size, ChartController controller) {
    if (controller.tradeMarkers.isEmpty) return;
    if (controller.allCandles.isEmpty) return;

    final markers = controller.tradeMarkers;

    for (final marker in markers) {
      // 1. Find the candle index for this timestamp
      // Simplified: find first candle where time >= marker.timestamp
      // Better: Binary search or use a map if performance is an issue.
      // For now, linear search in visible range? No, markers could be anywhere.

      // Efficiently find index
      final index =
          _findIndexForTimestamp(controller.allCandles, marker.timestamp);
      if (index == -1) continue;

      // 2. Check if visible
      if (index < controller.startIndex || index > controller.endIndex) {
        continue;
      }

      // 3. Coordinate Mapping
      final x = controller.indexToX(index);
      final y = controller.priceToY(marker.price, size.height);

      // 4. Draw Arrow
      _drawArrow(canvas, Offset(x, y), marker.isBuy);
    }
  }

  static int _findIndexForTimestamp(List<dynamic> candles, DateTime timestamp) {
    final target = timestamp.millisecondsSinceEpoch;
    // Binary search is best here
    int low = 0;
    int high = candles.length - 1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      final midTime = candles[mid].time;
      if (midTime == target) return mid;
      if (midTime < target) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return -1; // Or return 'low' to find nearest? Replay uses exact matches usually.
  }

  static void _drawArrow(Canvas canvas, Offset position, bool isBuy) {
    final color = isBuy ? VxColors.neonGreen : VxColors.neonRed;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const size = 10.0;

    if (isBuy) {
      // Up Arrow below the price
      final tip = position.translate(0, 15);
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx - size / 2, tip.dy + size);
      path.lineTo(tip.dx + size / 2, tip.dy + size);
    } else {
      // Down Arrow above the price
      final tip = position.translate(0, -15);
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx - size / 2, tip.dy - size);
      path.lineTo(tip.dx + size / 2, tip.dy - size);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Optional: Draw a subtle glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);
  }
}
