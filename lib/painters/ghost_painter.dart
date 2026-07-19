import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../ui/design_system/vx_colors.dart';

class GhostPainter {
  static void paint(Canvas canvas, Size size, ChartController controller) {
    final ghost = controller.ghost;
    if (ghost == null) return;

    final paint = Paint()
      ..color = VxColors.neonCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final x1 = controller.indexToX(ghost.startIndex);
    final y1 = controller.priceToY(ghost.startPrice, size.height);

    final x2 = controller.indexToX(ghost.endIndex);
    final y2 = controller.priceToY(ghost.endPrice, size.height);

    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

    final glowPaint = Paint()
      ..color = VxColors.neonCyan.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);

    canvas.drawCircle(Offset(x2, y2), 4.0, Paint()..color = VxColors.neonCyan);
    canvas.drawCircle(Offset(x2, y2), 8.0,
        Paint()..color = VxColors.neonCyan.withValues(alpha: 0.3));
  }
}
