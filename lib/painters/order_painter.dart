import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
import '../ui/design_system/vx_colors.dart';

class OrderPainter {
  static void paint(Canvas canvas, Size size, ChartController controller,
      ExecutionManager executionManager) {
    for (final order in executionManager.orders) {
      if (order.status == OrderStatus.cancelled) continue;

      final index = controller.allCandles.indexWhere((c) =>
          c.date.isAtSameMomentAs(order.timestamp) ||
          c.date.isAfter(order.timestamp));

      if (index == -1) continue;

      final x = controller.indexToX(index);
      final y = controller.priceToY(order.entryPrice, size.height);

      final color = order.direction == OrderDirection.long
          ? VxColors.neonGreen
          : VxColors.neonRed;

      final markerPath = Path();
      if (order.direction == OrderDirection.long) {
        markerPath.moveTo(x, y + 10);
        markerPath.lineTo(x - 5, y + 20);
        markerPath.lineTo(x + 5, y + 20);
      } else {
        markerPath.moveTo(x, y - 10);
        markerPath.lineTo(x - 5, y - 20);
        markerPath.lineTo(x + 5, y - 20);
      }
      markerPath.close();

      canvas.drawPath(markerPath, Paint()..color = color);
      canvas.drawPath(
          markerPath,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);

      Color lineColor = color;

      if (order.isOpen) {
        final currentPrice = controller.allCandles.last.close;
        final currentY = controller.priceToY(currentPrice, size.height);
        final currentX = controller.indexToX(controller.allCandles.length - 1);

        final pnl = order.unrealizedPnl ?? 0;
        lineColor = pnl >= 0 ? VxColors.neonGreen : VxColors.neonRed;

        final dashPaint = Paint()
          ..color = lineColor
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        _drawDashedLine(
            canvas, Offset(x, y), Offset(currentX, currentY), dashPaint);
      } else {
        if (order.exitPrice != null && order.closedAt != null) {
          final exitY = controller.priceToY(order.exitPrice!, size.height);
          lineColor = (order.realizedPnl ?? 0) >= 0
              ? VxColors.neonGreen.withOpacity(0.5)
              : VxColors.neonRed.withOpacity(0.5);

          canvas.drawLine(
              Offset(x, y),
              Offset(x + 20, exitY),
              Paint()
                ..color = lineColor
                ..strokeWidth = 1);
        }
      }
    }
  }

  static void _drawDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const int dashWidth = 5;
    const int dashSpace = 5;
    double distance = (p2 - p1).distance;
    double dx = (p2.dx - p1.dx) / distance;
    double dy = (p2.dy - p1.dy) / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      double startX = p1.dx + currentDistance * dx;
      double startY = p1.dy + currentDistance * dy;
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + dashWidth * dx, startY + dashWidth * dy), paint);
      currentDistance += dashWidth + dashSpace;
    }
  }
}
